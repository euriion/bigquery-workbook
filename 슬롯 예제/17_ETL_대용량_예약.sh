#!/bin/bash

# ETL 전용 대용량 예약
bq mk --reservation \
  --project_id=etl-project \
  --location=US \
  --slots=2000 \
  --plan=FLEX \
  --ignore_idle_slots=false \
  etl-night-batch

# 스케줄 기반 슬롯 조정 (Cloud Scheduler + Cloud Functions 사용)