#!/bin/bash

# 실시간 대시보드용 월간 약정
bq mk --reservation \
  --project_id=dashboard-project \
  --location=US \
  --slots=300 \
  --plan=MONTHLY \
  dashboard-realtime

# 높은 우선순위 설정
bq query --use_legacy_sql=false \
  --priority=INTERACTIVE \
  --reservation=dashboard-realtime \
  "SELECT * FROM dashboard_view LIMIT 1000"