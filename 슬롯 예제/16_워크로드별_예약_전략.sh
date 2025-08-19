#!/bin/bash

# ETL 워크로드용 예약
bq mk --reservation \
  --slots=1000 \
  --plan=FLEX \
  etl-reservation

# 애드혹 분석용 예약  
bq mk --reservation \
  --slots=500 \
  --plan=FLEX \
  analytics-reservation

# 대시보드용 예약
bq mk --reservation \
  --slots=200 \
  --plan=MONTHLY \
  dashboard-reservation