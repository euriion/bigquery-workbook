#!/bin/bash
# BigQuery CLI를 통한 파티션 테이블 생성

# DATE 컬럼 기반 일별 파티션 테이블 생성
bq mk \
    --table \
    --time_partitioning_field=transaction_date \
    --time_partitioning_type=DAY \
    mydataset.sales_table \
    transaction_id:INTEGER,transaction_date:DATE,amount:FLOAT

# TIMESTAMP 컬럼 기반 시간별 파티션 테이블 생성
bq mk \
    --table \
    --time_partitioning_field=event_timestamp \
    --time_partitioning_type=HOUR \
    mydataset.hourly_events \
    event_id:INTEGER,event_timestamp:TIMESTAMP,data:STRING

# 수집 시간 기반 일별 파티션 테이블 생성 (UTC 기준)
bq mk \
    --table \
    --time_partitioning_type=DAY \
    mydataset.ingestion_table \
    id:INTEGER,data:STRING

# 파티션 만료 기간 설정 (7일)
bq mk \
    --table \
    --time_partitioning_type=DAY \
    --time_partitioning_expiration=604800 \
    mydataset.temp_ingestion_table \
    id:INTEGER,data:STRING