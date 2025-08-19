-- BigQuery 파티션 성능 최적화 쿼리

-- 파티션 프루닝을 위한 효율적인 필터 작성
-- 좋은 예: 파티션 컬럼을 직접 필터링
SELECT * FROM mydataset.sales_table
WHERE transaction_date >= "2024-01-01" 
  AND transaction_date <= "2024-01-31";

-- 피해야 할 예: 함수 적용으로 파티션 프루닝 방해
SELECT * FROM mydataset.sales_table
WHERE DATE_ADD(transaction_date, INTERVAL 1 DAY) >= "2024-01-02";

-- 배치 데이터 로드 시 정확한 파티션 지정
LOAD DATA INTO mydataset.sales_table
PARTITION (transaction_date = "2024-01-01")
FROM 'gs://bucket/sales-20240101.csv'
WITH PARTITION_COLUMNS (transaction_date);