#!/bin/bash

# Flex 슬롯 생성 예시
bq mk --reservation --project_id=PROJECT_ID \
  --location=US --slots=100 --ignore_idle_slots=false \
  my-flex-reservation