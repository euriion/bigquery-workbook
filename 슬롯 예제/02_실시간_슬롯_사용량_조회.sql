-- 실시간 슬롯 사용량 조회
SELECT reservation_name,
       total_slots,
       assigned_slots,
       idle_slots,
       total_assigned_slots - assigned_slots AS available_slots
FROM `region-US`.INFORMATION_SCHEMA.RESERVATIONS_TIMELINE
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
ORDER BY creation_time DESC;