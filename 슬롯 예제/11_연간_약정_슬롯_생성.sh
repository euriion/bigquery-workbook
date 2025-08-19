#!/bin/bash

# 연간 약정 슬롯 생성
bq mk --reservation --project_id=PROJECT_ID \
  --location=US --slots=500 --plan=ANNUAL \
  production-reservation