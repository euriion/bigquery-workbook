-- BigQuery 파티션 테이블 생성 쿼리

-- DATE 컬럼 기반 일별 파티셔닝 (기본)
CREATE TABLE mydataset.sales_table (
    transaction_id INT64,
    transaction_date DATE,
    amount FLOAT64
)
PARTITION BY transaction_date;

-- TIMESTAMP 컬럼 기반 일별 파티셔닝
CREATE TABLE mydataset.events_table (
    event_id INT64,
    event_timestamp TIMESTAMP,
    user_id STRING
)
PARTITION BY DATE(event_timestamp);

-- TIMESTAMP 컬럼 기반 시간별 파티셔닝
CREATE TABLE mydataset.hourly_events (
    event_id INT64,
    event_timestamp TIMESTAMP,
    data STRING
)
PARTITION BY TIMESTAMP_TRUNC(event_timestamp, HOUR);

-- KST 기준으로 파티셔닝하려면 TIMESTAMP를 KST로 변환 후 DATE 추출
CREATE TABLE mydataset.korea_sales (
    transaction_id INT64,
    transaction_timestamp TIMESTAMP,
    amount FLOAT64
)
PARTITION BY DATE(DATETIME(TIMESTAMP(transaction_timestamp), "Asia/Seoul"));

-- 미국 동부 시간대(EST) 기준 파티셔닝
CREATE TABLE mydataset.us_east_sales (
    transaction_id INT64,
    transaction_timestamp TIMESTAMP,
    amount FLOAT64
)
PARTITION BY DATE(DATETIME(TIMESTAMP(transaction_timestamp), "America/New_York"));

-- UTC 기준 일별 수집 시간 파티셔닝
CREATE TABLE mydataset.ingestion_table (
    id INT64,
    data STRING
)
PARTITION BY _PARTITIONDATE;