#!/bin/bash

# 기본 예약 생성
bq mk --reservation \
  --project_id=my-project \
  --location=US \
  --slots=1000 \
  --plan=FLEX \
  my-reservation

# 자동 스케일링 설정
bq mk --reservation \
  --project_id=my-project \
  --location=US \
  --slots=500 \
  --max_slots=2000 \
  --autoscale_max_slots=2000 \
  auto-scaling-reservation