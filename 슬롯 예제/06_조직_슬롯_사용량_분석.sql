-- 조직 내 슬롯 사용량 분석
WITH slot_usage AS (
    SELECT project_id,
           reservation_name,
           SUM(total_slot_ms) / 1000 / 60 / 60 AS slot_hours,
           COUNT(*)                            AS query_count
    FROM `region-US`.INFORMATION_SCHEMA.JOBS_BY_ORGANIZATION
    WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
      AND reservation_name IS NOT NULL
    GROUP BY project_id, reservation_name
)
SELECT project_id,
       reservation_name,
       slot_hours,
       query_count,
       slot_hours / query_count AS avg_slot_hours_per_query
FROM slot_usage
ORDER BY slot_hours DESC;