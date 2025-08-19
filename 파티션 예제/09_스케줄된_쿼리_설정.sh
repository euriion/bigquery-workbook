#!/bin/bash
# BigQuery 스케줄된 쿼리로 타임존 처리

# 매일 한국 시간 기준으로 전일 데이터를 처리하는 스케줄된 쿼리 생성
bq mk \
    --transfer_config \
    --project_id=my-project \
    --target_dataset=mydataset \
    --display_name="Daily Korea Timezone Processing" \
    --data_source=scheduled_query \
    --schedule="0 1 * * *" \
    --params='{
        "query":"INSERT INTO mydataset.daily_korea_summary SELECT DATE(event_timestamp, \"Asia/Seoul\") as event_date, COUNT(*) as total_events FROM mydataset.events_table WHERE DATE(event_timestamp, \"Asia/Seoul\") = DATE_SUB(CURRENT_DATE(\"Asia/Seoul\"), INTERVAL 1 DAY) GROUP BY event_date",
        "destination_table_name_template":"daily_summary_{run_date}",
        "write_disposition":"WRITE_TRUNCATE"
    }'