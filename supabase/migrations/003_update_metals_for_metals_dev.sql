-- ============================================
-- 003: Metals.Dev API 전환 + 금속 순서 재정렬
-- 순서: SN(1), AG(2), CU(3), NI(4), PB(5), ZN(6), AL(7)
-- AU(금) 삭제
-- ============================================

-- 1. 기존 데이터 삭제 (테스트 데이터만 있으므로 안전)
DELETE FROM daily_prices;
DELETE FROM price_alerts;
DELETE FROM metals;

-- 2. 시퀀스 리셋
ALTER SEQUENCE metals_id_seq RESTART WITH 1;

-- 3. 새 순서로 금속 삽입
INSERT INTO metals (symbol, name_en, name_ko, unit, is_active) VALUES
('SN', 'Tin', '주석', 'USD/MT', true),           -- 1
('AG', 'Silver', '은', 'USD/ozt', true),          -- 2
('CU', 'Copper', '구리', 'USD/MT', true),         -- 3
('NI', 'Nickel', '니켈', 'USD/MT', true),         -- 4
('PB', 'Lead', '납', 'USD/MT', true),             -- 5
('ZN', 'Zinc', '아연', 'USD/MT', true),           -- 6
('AL', 'Aluminium', '알루미늄', 'USD/MT', true);  -- 7

-- 4. 확인
SELECT id, symbol, name_ko, unit, is_active FROM metals ORDER BY id;
