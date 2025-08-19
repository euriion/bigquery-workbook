#!/bin/bash

# 워크로드별 별도 예약 생성
bq mk --reservation --slots=500 high-priority-reservation
bq mk --reservation --slots=300 medium-priority-reservation
bq mk --reservation --slots=200 low-priority-reservation

# 각각 다른 프로젝트에 할당
bq mk --assignment \
  --reservation_id=projects/my-project/locations/US/reservations/high-priority-reservation \
  --assignee_id=projects/critical-project \
  --assignee_type=PROJECT