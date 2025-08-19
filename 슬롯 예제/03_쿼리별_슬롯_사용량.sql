-- 지난 24시간 동안 쿼리별 슬롯 사용량
SELECT job_id,
       user_email,
       query,
       total_slot_ms,
       total_slot_ms / 1000 / 60 AS slot_minutes,
       start_time,
       end_time
FROM `region-US`.INFORMATION_SCHEMA.JOBS_BY_USER
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
  AND total_slot_ms > 0
ORDER BY total_slot_ms DESC
LIMIT 100;