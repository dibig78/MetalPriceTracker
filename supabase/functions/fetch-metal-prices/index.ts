// ============================================
// MetalPriceTracker - 일별 시세 수집 Edge Function
// Supabase Edge Function (Deno/TypeScript)
// 매일 자동으로 MetalpriceAPI에서 LME 비철금속 시세를 가져와 DB에 저장
// ============================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// 환경 변수
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const METALS_API_KEY = Deno.env.get("METALS_API_KEY") || "5db412ead539e53d6abd8cdf25ec3ccf";

// MetalpriceAPI 기본 URL
const METALS_API_BASE = "https://api.metalpriceapi.com/v1";

// 금속 심볼 매핑 (MetalpriceAPI 형식)
const METAL_SYMBOLS: Record<string, string> = {
  CU: "LME-XCU",  // 구리
  AL: "LME-ALU",  // 알루미늄
  ZN: "LME-ZNC",  // 아연
  NI: "LME-NI",   // 니켈
  PB: "LME-PB",   // 납
  SN: "LME-SN",   // 주석
  AG: "XAG",       // 은 (Silver)
};

interface MetalpriceApiResponse {
  success: boolean;
  timestamp: number;
  date: string;
  base: string;
  rates: Record<string, number>;
}

interface MetalPriceRow {
  metal_id: number;
  price_date: string;
  close_price: number;
  open_price: number | null;
  high_price: number | null;
  low_price: number | null;
  change_amount: number | null;
  change_percent: number | null;
}

// MetalpriceAPI에서 시세 조회
async function fetchMetalPrices(date?: string): Promise<MetalpriceApiResponse> {
  const currencies = Object.values(METAL_SYMBOLS).join(",");

  let url: string;
  if (date) {
    // 특정 날짜 조회
    url = `${METALS_API_BASE}/${date}?api_key=${METALS_API_KEY}&base=USD&currencies=${currencies}`;
  } else {
    // 최신 시세 조회
    url = `${METALS_API_BASE}/latest?api_key=${METALS_API_KEY}&base=USD&currencies=${currencies}`;
  }

  console.log(`Fetching prices from: ${url.replace(METALS_API_KEY, "***")}`);

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`MetalpriceAPI error: ${response.status} ${response.statusText}`);
  }

  const data: MetalpriceApiResponse = await response.json();
  if (!data.success) {
    throw new Error(`MetalpriceAPI returned error: ${JSON.stringify(data)}`);
  }

  return data;
}

// DB에서 금속 목록 조회
async function getMetals(supabase: ReturnType<typeof createClient>) {
  const { data, error } = await supabase
    .from("metals")
    .select("id, symbol")
    .eq("is_active", true);

  if (error) throw new Error(`Failed to fetch metals: ${error.message}`);
  return data;
}

// 전일 시세 조회 (변동률 계산용)
async function getPreviousPrice(
  supabase: ReturnType<typeof createClient>,
  metalId: number,
  beforeDate: string
) {
  const { data, error } = await supabase
    .from("daily_prices")
    .select("close_price")
    .eq("metal_id", metalId)
    .lt("price_date", beforeDate)
    .order("price_date", { ascending: false })
    .limit(1)
    .single();

  if (error || !data) return null;
  return data.close_price;
}

// 시세 데이터 저장
async function savePrices(
  supabase: ReturnType<typeof createClient>,
  prices: MetalPriceRow[]
) {
  const { data, error } = await supabase
    .from("daily_prices")
    .upsert(prices, { onConflict: "metal_id,price_date" })
    .select();

  if (error) throw new Error(`Failed to save prices: ${error.message}`);
  return data;
}

// 가격 알림 체크
async function checkAlerts(
  supabase: ReturnType<typeof createClient>,
  prices: MetalPriceRow[]
) {
  const { data: alerts, error } = await supabase
    .from("price_alerts")
    .select("*")
    .eq("is_active", true);

  if (error || !alerts) return;

  const triggeredAlerts: number[] = [];

  for (const alert of alerts) {
    const priceData = prices.find((p) => p.metal_id === alert.metal_id);
    if (!priceData) continue;

    const currentPrice = priceData.close_price;
    const shouldTrigger =
      (alert.direction === "above" && currentPrice >= alert.target_price) ||
      (alert.direction === "below" && currentPrice <= alert.target_price);

    if (shouldTrigger) {
      triggeredAlerts.push(alert.id);
      console.log(
        `Alert triggered: metal_id=${alert.metal_id}, ` +
        `target=${alert.target_price}, current=${currentPrice}`
      );
    }
  }

  // 트리거된 알림 비활성화
  if (triggeredAlerts.length > 0) {
    await supabase
      .from("price_alerts")
      .update({ is_active: false, triggered_at: new Date().toISOString() })
      .in("id", triggeredAlerts);
  }
}

// 메인 핸들러
serve(async (req) => {
  try {
    // CORS 헤더
    if (req.method === "OPTIONS") {
      return new Response("ok", {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    console.log("Starting daily metal price fetch...");

    // Supabase 클라이언트 (service role로 RLS 우회)
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. 금속 목록 조회
    const metals = await getMetals(supabase);
    console.log(`Found ${metals.length} active metals`);

    // 2. MetalpriceAPI에서 최신 시세 조회
    const apiData = await fetchMetalPrices();
    console.log(`Fetched prices for date: ${apiData.date}`);
    console.log(`Rates received:`, JSON.stringify(apiData.rates));

    // 3. 데이터 변환 및 저장
    const priceRows: MetalPriceRow[] = [];
    const today = apiData.date || new Date().toISOString().split("T")[0];

    for (const metal of metals) {
      const apiSymbol = METAL_SYMBOLS[metal.symbol];
      if (!apiSymbol) {
        console.warn(`No symbol mapping for ${metal.symbol}`);
        continue;
      }

      // MetalpriceAPI 응답에서 해당 금속 가격 찾기
      // 응답 형식: rates 객체에 "USDLME-XCU" 또는 "LME-XCU" 키로 들어올 수 있음
      let rate = apiData.rates[apiSymbol] || apiData.rates[`USD${apiSymbol}`];

      if (!rate) {
        console.warn(`No price data for ${metal.symbol} (tried ${apiSymbol} and USD${apiSymbol})`);
        console.warn(`Available keys: ${Object.keys(apiData.rates).join(", ")}`);
        continue;
      }

      // MetalpriceAPI: base=USD일 때 rates는 "1 USD = X 단위 금속"
      // 실제 가격(USD/MT)을 얻으려면 1/rate 계산
      // 단, rate가 이미 USD 가격으로 올 수도 있으므로 값 크기로 판단
      let closePrice: number;
      if (rate < 1) {
        // 1/rate = USD 가격 (예: rate=0.0001 → 가격=$10,000)
        closePrice = Math.round((1 / rate) * 100) / 100;
      } else {
        // 이미 USD 가격으로 제공됨
        closePrice = Math.round(rate * 100) / 100;
      }

      // 전일 대비 변동 계산
      const prevPrice = await getPreviousPrice(supabase, metal.id, today);
      const changeAmount = prevPrice ? closePrice - prevPrice : null;
      const changePercent = prevPrice && prevPrice > 0
        ? ((closePrice - prevPrice) / prevPrice) * 100
        : null;

      priceRows.push({
        metal_id: metal.id,
        price_date: today,
        close_price: closePrice,
        open_price: closePrice,
        high_price: null,
        low_price: null,
        change_amount: changeAmount ? Math.round(changeAmount * 100) / 100 : null,
        change_percent: changePercent ? Math.round(changePercent * 10000) / 10000 : null,
      });

      console.log(`${metal.symbol}: rate=${rate}, price=$${closePrice}`);
    }

    if (priceRows.length === 0) {
      throw new Error("No price data could be parsed from API response");
    }

    // 4. DB에 저장 (UPSERT)
    const saved = await savePrices(supabase, priceRows);
    console.log(`Saved ${saved?.length || 0} price records`);

    // 5. 가격 알림 체크
    await checkAlerts(supabase, priceRows);

    return new Response(
      JSON.stringify({
        success: true,
        date: today,
        count: priceRows.length,
        prices: priceRows.map((p) => ({
          metal_id: p.metal_id,
          close_price: p.close_price,
          change_percent: p.change_percent,
        })),
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    console.error("Error fetching metal prices:", error);
    return new Response(
      JSON.stringify({ success: false, error: (error as Error).message }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});
