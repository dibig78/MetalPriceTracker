// ============================================
// MetalPriceTracker - 일별 시세 수집 Edge Function
// Supabase Edge Function (Deno/TypeScript)
// 매일 자동으로 Metals.Dev API에서 금속 시세를 가져와 DB에 저장
// API: https://metals.dev (무료 100회/월)
// ============================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// 환경 변수
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const METALS_DEV_API_KEY = Deno.env.get("METALS_DEV_API_KEY") || "";

// Metals.Dev API 기본 URL
const METALS_DEV_BASE = "https://api.metals.dev/v1";

// 1 메트릭톤 = 32,150.7 트로이온스
const TOZ_PER_MT = 32150.7;

// 금속 심볼 매핑 (DB symbol → Metals.Dev API key)
// type: "industrial" = LME 산업금속 (가격: USD/MT), "precious" = 귀금속 (가격: USD/toz)
const METAL_MAP: Record<string, { key: string; type: "industrial" | "precious" }> = {
  CU: { key: "lme_copper",    type: "industrial" },  // 구리
  AL: { key: "lme_aluminum",  type: "industrial" },  // 알루미늄
  ZN: { key: "lme_zinc",      type: "industrial" },  // 아연
  NI: { key: "lme_nickel",    type: "industrial" },  // 니켈
  PB: { key: "lme_lead",      type: "industrial" },  // 납
  SN: { key: "lme_tin",       type: "industrial" },  // 주석 (미지원 시 자동 skip)
  AG: { key: "silver",        type: "precious" },     // 은
};

// Metals.Dev API 응답 타입
interface MetalsDevResponse {
  status: string;
  currency: string;
  unit: string;
  metals: Record<string, number>;
  timestamps: {
    metal: string;
    currency: string;
  };
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

// Metals.Dev API에서 최신 시세 조회
async function fetchMetalPrices(): Promise<MetalsDevResponse> {
  const url = `${METALS_DEV_BASE}/latest?api_key=${METALS_DEV_API_KEY}&currency=USD&unit=toz`;

  console.log(`Fetching prices from: ${url.replace(METALS_DEV_API_KEY, "***")}`);

  const response = await fetch(url);
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Metals.Dev API error: ${response.status} ${response.statusText} - ${errorText}`);
  }

  const data: MetalsDevResponse = await response.json();
  if (data.status !== "success") {
    throw new Error(`Metals.Dev API returned error: ${JSON.stringify(data)}`);
  }

  return data;
}

// DB에서 금속 목록 조회
async function getMetals(supabase: ReturnType<typeof createClient>) {
  const { data, error } = await supabase
    .from("metals")
    .select("id, symbol, unit")
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

    console.log("Starting daily metal price fetch (Metals.Dev)...");

    // API 키 확인
    if (!METALS_DEV_API_KEY) {
      throw new Error("METALS_DEV_API_KEY environment variable is not set");
    }

    // Supabase 클라이언트 (service role로 RLS 우회)
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. 금속 목록 조회
    const metals = await getMetals(supabase);
    console.log(`Found ${metals.length} active metals`);

    // 2. Metals.Dev API에서 최신 시세 조회
    const apiData = await fetchMetalPrices();
    console.log(`API response metals:`, JSON.stringify(apiData.metals));
    console.log(`API unit: ${apiData.unit}, currency: ${apiData.currency}`);

    // 3. 데이터 변환 및 저장
    const priceRows: MetalPriceRow[] = [];
    const today = new Date().toISOString().split("T")[0];

    for (const metal of metals) {
      const mapping = METAL_MAP[metal.symbol];
      if (!mapping) {
        console.warn(`No mapping for ${metal.symbol}`);
        continue;
      }

      // API 응답에서 가격 가져오기 (단위: USD/toz)
      const pricePerToz = apiData.metals[mapping.key];

      if (pricePerToz === undefined || pricePerToz === null) {
        console.warn(`No price data for ${metal.symbol} (key: ${mapping.key})`);
        console.warn(`Available keys: ${Object.keys(apiData.metals).join(", ")}`);
        continue;
      }

      // 가격 변환
      let closePrice: number;
      if (mapping.type === "industrial") {
        // 산업금속: toz → MT 변환 (1MT = 32,150.7 toz)
        closePrice = Math.round(pricePerToz * TOZ_PER_MT * 100) / 100;
      } else {
        // 귀금속: 이미 USD/toz 단위 그대로 사용
        closePrice = Math.round(pricePerToz * 100) / 100;
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

      const unitLabel = mapping.type === "industrial" ? "USD/MT" : "USD/toz";
      console.log(`${metal.symbol}: ${pricePerToz} USD/toz → $${closePrice} ${unitLabel}`);
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
