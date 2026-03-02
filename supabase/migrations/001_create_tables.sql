-- ============================================
-- MetalPriceTracker - Supabase DB Schema
-- LME 비철금속 시세 데이터베이스
-- ============================================

-- 1. 금속 종류 마스터 테이블
CREATE TABLE metals (
  id SERIAL PRIMARY KEY,
  symbol VARCHAR(10) NOT NULL UNIQUE,
  name_en VARCHAR(50) NOT NULL,
  name_ko VARCHAR(50) NOT NULL,
  unit VARCHAR(20) DEFAULT 'USD/MT',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 일별 시세 데이터 테이블
CREATE TABLE daily_prices (
  id BIGSERIAL PRIMARY KEY,
  metal_id INTEGER NOT NULL REFERENCES metals(id) ON DELETE CASCADE,
  price_date DATE NOT NULL,
  open_price DECIMAL(12,2),
  high_price DECIMAL(12,2),
  low_price DECIMAL(12,2),
  close_price DECIMAL(12,2),
  change_amount DECIMAL(12,2),
  change_percent DECIMAL(8,4),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(metal_id, price_date)
);

-- 3. 가격 알림 설정 테이블
CREATE TABLE price_alerts (
  id SERIAL PRIMARY KEY,
  device_token TEXT NOT NULL,
  metal_id INTEGER NOT NULL REFERENCES metals(id) ON DELETE CASCADE,
  target_price DECIMAL(12,2) NOT NULL,
  direction VARCHAR(10) NOT NULL CHECK (direction IN ('above', 'below')),
  is_active BOOLEAN DEFAULT TRUE,
  triggered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 인덱스 생성
CREATE INDEX idx_daily_prices_date ON daily_prices(price_date DESC);
CREATE INDEX idx_daily_prices_metal_date ON daily_prices(metal_id, price_date DESC);
CREATE INDEX idx_price_alerts_active ON price_alerts(is_active) WHERE is_active = TRUE;

-- 5. 초기 금속 데이터 삽입 (LME 주요 비철금속 6종)
INSERT INTO metals (symbol, name_en, name_ko, unit) VALUES
  ('CU', 'Copper', '구리', 'USD/MT'),
  ('AL', 'Aluminium', '알루미늄', 'USD/MT'),
  ('ZN', 'Zinc', '아연', 'USD/MT'),
  ('NI', 'Nickel', '니켈', 'USD/MT'),
  ('PB', 'Lead', '납', 'USD/MT'),
  ('SN', 'Tin', '주석', 'USD/MT');

-- 6. RLS (Row Level Security) 정책
-- daily_prices: 누구나 읽기 가능
ALTER TABLE daily_prices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "daily_prices_read" ON daily_prices
  FOR SELECT USING (true);

-- metals: 누구나 읽기 가능
ALTER TABLE metals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "metals_read" ON metals
  FOR SELECT USING (true);

-- price_alerts: device_token 기반 접근
ALTER TABLE price_alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "alerts_read" ON price_alerts
  FOR SELECT USING (true);
CREATE POLICY "alerts_insert" ON price_alerts
  FOR INSERT WITH CHECK (true);
CREATE POLICY "alerts_update" ON price_alerts
  FOR UPDATE USING (true);
CREATE POLICY "alerts_delete" ON price_alerts
  FOR DELETE USING (true);

-- 7. pg_cron 확장 활성화 (Supabase 대시보드에서 직접 활성화 필요)
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 8. 유용한 뷰: 최신 시세 + 전일 대비 변동
CREATE OR REPLACE VIEW latest_prices AS
SELECT
  m.id AS metal_id,
  m.symbol,
  m.name_en,
  m.name_ko,
  m.unit,
  dp.price_date,
  dp.close_price,
  dp.open_price,
  dp.high_price,
  dp.low_price,
  dp.change_amount,
  dp.change_percent
FROM metals m
LEFT JOIN daily_prices dp ON dp.metal_id = m.id
  AND dp.price_date = (
    SELECT MAX(price_date) FROM daily_prices WHERE metal_id = m.id
  )
WHERE m.is_active = TRUE
ORDER BY m.id;
