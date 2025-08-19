#!/bin/bash

# 슬롯 사용률 80% 초과 시 알림
gcloud alpha monitoring policies create \
  --notification-channels=NOTIFICATION_CHANNEL_ID \
  --display-name="BigQuery 슬롯 사용률 알림" \
  --condition-filter='resource.type="bigquery_reservation"' \
  --condition-comparison=COMPARISON_GREATER_THAN \
  --condition-threshold-value=0.8