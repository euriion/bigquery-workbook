#!/bin/bash
# BigQuery CLI를 통한 파티션 메타데이터 조회

# 테이블의 파티션 정보 조회
bq ls --format=prettyjson mydataset.sales_table

# 특정 파티션의 정보 상세 조회
bq show mydataset.sales_table\$20240101

# 모든 파티션 목록과 크기 정보 조회
bq query \
    --use_legacy_sql=false \
    "
    SELECT 
        partition_id,
        total_rows,
        total_logical_bytes,
        last_modified_time
    FROM mydataset.INFORMATION_SCHEMA.PARTITIONS
    WHERE table_name = 'sales_table'
    ORDER BY partition_id
    "