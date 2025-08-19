-- 슬롯 사용 효율성 분석
SELECT job_id,
       query,
       total_slot_ms,
       total_bytes_processed,
       (total_slot_ms / 1000) / (total_bytes_processed / POW(2, 30)) AS slot_seconds_per_gb
FROM `region-US`.INFORMATION_SCHEMA.JOBS_BY_USER
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
  AND total_slot_ms > 0
ORDER BY slot_seconds_per_gb DESC
LIMIT 20;