#!/bin/bash

# 1. 현재 슬롯 사용량 확인
bq ls --reservations --location=US

# 2. 슬롯 증가 (Flex 예약인 경우)
bq update --reservation \
  --location=US \
  --slots=1500 \
  my-reservation

# 3. 추가 예약 구매 고려