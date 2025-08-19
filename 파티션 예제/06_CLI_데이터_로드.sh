#!/bin/bash
# BigQuery CLI를 통한 타임존 고려 데이터 로드

# 한국 시간(KST) CSV 데이터를 UTC로 변환하여 로드
bq load \
    --source_format=CSV \
    --time_partitioning_field=event_timestamp \
    --skip_leading_rows=1 \
    mydataset.events_table \
    gs://my-bucket/korea-events.csv \
    event_id:INTEGER,event_timestamp:TIMESTAMP,user_id:STRING

# 특정 파티션에 직접 로드 (날짜 지정)
bq load \
    --source_format=CSV \
    --replace \
    mydataset.sales_table\$20240101 \
    gs://my-bucket/sales-20240101.csv \
    transaction_id:INTEGER,transaction_date:DATE,amount:FLOAT

# JSON 파일에서 ISO 8601 형식의 타임스탬프 로드
bq load \
    --source_format=NEWLINE_DELIMITED_JSON \
    --time_partitioning_field=created_at \
    --autodetect \
    mydataset.user_events \
    gs://my-bucket/events-with-timezone.json

# bq 명령어로 특정 파티션에 데이터 로드
bq load \
    --source_format=CSV \
    --time_partitioning_field=transaction_date \
    mydataset.sales_table$20240101 \
    gs://my-bucket/data-20240101.csv \
    "transaction_id:INTEGER,transaction_date:DATE,amount:FLOAT"