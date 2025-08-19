-- BigQuery 타임존 변환 쿼리

-- 한국 시간대 기준으로 수집 시간 필터링
SELECT *
FROM mydataset.ingestion_table
WHERE _PARTITIONTIME >= TIMESTAMP("2024-01-01", "Asia/Seoul")
  AND _PARTITIONTIME < TIMESTAMP("2024-01-02", "Asia/Seoul");

-- 특정 날짜 파티션에 직접 데이터 삽입 (한국 시간 기준)
INSERT INTO mydataset.sales_table$20240101
SELECT 
    transaction_id,
    DATE("2024-01-01") as transaction_date,
    amount
FROM source_table
WHERE DATE(transaction_timestamp, "Asia/Seoul") = "2024-01-01";

-- 한국 시간 기준으로 2024년 1월 1일 데이터 조회
SELECT *
FROM mydataset.events_table
WHERE DATE(event_timestamp, "Asia/Seoul") = "2024-01-01";

-- 미국 동부 시간 기준으로 특정 시간 범위 데이터 조회
SELECT *
FROM mydataset.events_table
WHERE DATETIME(event_timestamp, "America/New_York") 
    BETWEEN "2024-01-01 09:00:00" AND "2024-01-01 17:00:00";

-- UTC 기준 파티션 시간으로 필터링
SELECT *
FROM mydataset.ingestion_table
WHERE _PARTITIONDATE BETWEEN "2024-01-01" AND "2024-01-03";

-- 한국 시간 기준으로 변환하여 조회
SELECT 
    *,
    DATETIME(_PARTITIONTIME, "Asia/Seoul") as korea_partition_time
FROM mydataset.ingestion_table
WHERE _PARTITIONDATE = "2024-01-01";

-- DST 변경 시점을 고려한 쿼리 작성
SELECT 
    event_timestamp,
    DATETIME(event_timestamp, "America/New_York") as local_time,
    -- DST 정보 확인
    EXTRACT(DAYOFYEAR FROM DATETIME(event_timestamp, "America/New_York")) as day_of_year
FROM mydataset.events_table
WHERE DATE(event_timestamp, "America/New_York") = "2024-03-10"; -- DST 시작일

-- 파티션별 데이터 분포 확인
SELECT 
    _PARTITIONTIME,
    COUNT(*) as record_count,
    MIN(event_timestamp) as min_timestamp,
    MAX(event_timestamp) as max_timestamp
FROM mydataset.ingestion_table
WHERE _PARTITIONDATE BETWEEN "2024-01-01" AND "2024-01-07"
GROUP BY _PARTITIONTIME
ORDER BY _PARTITIONTIME;