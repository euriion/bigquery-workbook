-- BigQuery 파티션 메타데이터 조회 쿼리

-- 모든 파티션 목록과 크기 정보 조회
SELECT 
    partition_id,
    total_rows,
    total_logical_bytes,
    last_modified_time
FROM mydataset.INFORMATION_SCHEMA.PARTITIONS
WHERE table_name = 'sales_table'
ORDER BY partition_id;