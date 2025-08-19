#!/bin/bash
# BigQuery CLI를 통한 타임존 변환 쿼리 실행

# 한국 시간대로 변환하여 특정 날짜 데이터 조회
bq query \
    --use_legacy_sql=false \
    --parameter=target_date:DATE:2024-01-01 \
    --parameter=timezone:STRING:Asia/Seoul \
    "
    SELECT 
        event_id,
        event_timestamp,
        DATETIME(event_timestamp, @timezone) as local_time,
        user_id
    FROM mydataset.events_table
    WHERE DATE(event_timestamp, @timezone) = @target_date
    "

# 배치 작업으로 타임존 변환 테이블 생성
bq query \
    --use_legacy_sql=false \
    --destination_table=mydataset.korea_events \
    --time_partitioning_field=korea_date \
    --time_partitioning_type=DAY \
    --write_disposition=WRITE_TRUNCATE \
    "
    SELECT 
        *,
        DATE(event_timestamp, 'Asia/Seoul') as korea_date
    FROM mydataset.events_table
    WHERE event_timestamp >= '2024-01-01 00:00:00 UTC'
    "

# 여러 시간대에서 동일 기간의 데이터 분포 비교
bq query \
    --use_legacy_sql=false \
    --job_id=timezone_analysis_$(date +%Y%m%d_%H%M%S) \
    "
    SELECT 
        'UTC' as timezone,
        DATE(event_timestamp) as date,
        COUNT(*) as event_count
    FROM mydataset.events_table
    WHERE event_timestamp >= '2024-01-01 00:00:00'
      AND event_timestamp < '2024-01-02 00:00:00'
    GROUP BY DATE(event_timestamp)
    
    UNION ALL
    
    SELECT 
        'Asia/Seoul' as timezone,
        DATE(event_timestamp, 'Asia/Seoul') as date,
        COUNT(*) as event_count
    FROM mydataset.events_table
    WHERE DATE(event_timestamp, 'Asia/Seoul') = '2024-01-01'
    GROUP BY DATE(event_timestamp, 'Asia/Seoul')
    "