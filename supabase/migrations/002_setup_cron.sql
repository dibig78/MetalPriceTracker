-- ============================================
-- Cron 스케줄 설정
-- Supabase 대시보드 > SQL Editor에서 실행
-- 매일 UTC 00:00 (한국시간 오전 9시)에 Edge Function 호출
-- ============================================

-- pg_cron 확장 활성화 (Supabase 대시보드 > Database > Extensions에서 활성화)
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- pg_net 확장 활성화 (HTTP 요청용)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 매일 UTC 00:00에 Edge Function 호출하는 cron job 생성
-- 주의: SUPABASE_URL과 ANON_KEY를 실제 값으로 교체해야 합니다
SELECT cron.schedule(
  'fetch-daily-metal-prices',       -- job 이름
  '0 0 * * 1-5',                    -- 매주 월~금 UTC 00:00 (주말 제외)
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/fetch-metal-prices',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_SUPABASE_ANON_KEY'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- cron job 확인
-- SELECT * FROM cron.job;

-- cron job 삭제 (필요 시)
-- SELECT cron.unschedule('fetch-daily-metal-prices');
