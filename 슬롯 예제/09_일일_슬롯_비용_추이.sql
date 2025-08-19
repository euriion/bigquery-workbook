-- 일일 슬롯 비용 추이
SELECT DATE(usage_start_time)        as usage_date,
       reservation_name,
       SUM(slot_ms) / 1000 / 60 / 60 AS total_slot_hours,
       total_slot_hours * 0.04       AS estimated_cost_usd -- Flex 슬롯 시간당 약 $0.04
FROM `region-US`.INFORMATION_SCHEMA.RESERVATION_USAGE
WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY usage_date, reservation_name
ORDER BY usage_date DESC, estimated_cost_usd DESC;