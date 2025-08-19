#!/bin/bash

# 특정 프로젝트에 예약 할당
bq mk --assignment \
  --reservation_id=projects/my-project/locations/US/reservations/my-reservation \
  --job_type=QUERY \
  --assignee_id=projects/assigned-project \
  --assignee_type=PROJECT