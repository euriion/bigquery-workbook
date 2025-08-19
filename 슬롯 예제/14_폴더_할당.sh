#!/bin/bash

# 폴더 단위 할당
bq mk --assignment \
  --reservation_id=projects/my-project/locations/US/reservations/my-reservation \
  --job_type=QUERY \
  --assignee_id=folders/123456789 \
  --assignee_type=FOLDER