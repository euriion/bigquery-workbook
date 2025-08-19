# BigQuery JSON 처리 완벽 가이드

BigQuery에서 JSON 데이터를 효율적으로 처리, 분석하는 방법을 다루는 종합 가이드입니다.

---

## 목차

1. [JSON 데이터 개념](#1-json-데이터-개념)
2. [JSON 함수 기본 사용법](#2-json-함수-기본-사용법)
3. [JSON 추출 및 변환](#3-json-추출-및-변환)
4. [JSON 배열 처리](#4-json-배열-처리)
5. [JSON 스키마 처리](#5-json-스키마-처리)
6. [JSON과 구조체 변환](#6-json과-구조체-변환)
7. [실제 활용 사례](#7-실제-활용-사례)
8. [성능 최적화](#8-성능-최적화)
9. [모범 사례와 주의점](#9-모범-사례와-주의점)

---

## 1. JSON 데이터 개념

### 1.1 BigQuery에서 JSON

BigQuery는 **JSON 데이터 타입**과 **JSON 함수**를 제공하여 반구조화 데이터를 효율적으로 처리할 수 있습니다.

```sql
-- JSON 리터럴 생성
SELECT 
  JSON '{"name": "John", "age": 30, "city": "New York"}' as person_info,
  JSON '[1, 2, 3, 4, 5]' as numbers,
  JSON '{"products": [{"name": "laptop", "price": 999}, {"name": "mouse", "price": 25}]}' as catalog;
```

### 1.2 JSON vs STRING

```sql
-- STRING으로 저장된 JSON (비추천)
WITH string_json AS (
  SELECT '{"user_id": 123, "name": "Alice"}' as user_data_string
)
SELECT 
  user_data_string,
  -- 문자열에서 JSON 함수 사용 시 매번 파싱 필요
  JSON_EXTRACT_SCALAR(user_data_string, '$.name') as name
FROM string_json;

-- JSON 타입으로 저장 (추천)
WITH typed_json AS (
  SELECT JSON '{"user_id": 123, "name": "Alice"}' as user_data_json
)
SELECT 
  user_data_json,
  -- 이미 파싱된 JSON에서 효율적 추출
  JSON_VALUE(user_data_json, '$.name') as name
FROM typed_json;
```

---

## 2. JSON 함수 기본 사용법

### 2.1 JSON 값 추출 함수

```sql
-- 기본 JSON 데이터
WITH sample_json AS (
  SELECT JSON '''{
    "user_id": 12345,
    "profile": {
      "name": "John Doe",
      "email": "john@example.com",
      "age": 30,
      "is_active": true,
      "tags": ["developer", "engineer", "tech-lead"]
    },
    "orders": [
      {"order_id": "A001", "amount": 299.99},
      {"order_id": "A002", "amount": 199.99}
    ]
  }''' as user_data
)
SELECT 
  user_data,
  
-- JSON_VALUE: 스칼라 값 추출 (문자열 반환)
  JSON_VALUE(user_data, '$.user_id') as user_id_string,
  JSON_VALUE(user_data, '$.profile.name') as user_name,
  JSON_VALUE(user_data, '$.profile.email') as user_email,
  
-- JSON_VALUE_ARRAY: 배열을 STRING 배열로 추출
  JSON_VALUE_ARRAY(user_data, '$.profile.tags') as tags_array,
  
-- JSON_EXTRACT: JSON 값 추출 (JSON 타입 유지)
  JSON_EXTRACT(user_data, '$.profile') as profile_json,
  JSON_EXTRACT(user_data, '$.orders') as orders_json,
  
-- JSON_EXTRACT_SCALAR: 스칼라 값 추출 (문자열 반환) - 레거시
  JSON_EXTRACT_SCALAR(user_data, '$.profile.age') as age_string
  
FROM sample_json;
```

### 2.2 타입 변환 함수

```sql
WITH json_data AS (
  SELECT JSON '''{
    "metrics": {
      "revenue": "1234.56",
      "user_count": "5000",
      "conversion_rate": "0.034",
      "is_profitable": "true",
      "launch_date": "2024-01-15"
    }
  }''' as data
)
SELECT 
-- 문자열 -> 숫자 변환
  CAST(JSON_VALUE(data, '$.metrics.revenue') AS FLOAT64) as revenue_numeric,
  CAST(JSON_VALUE(data, '$.metrics.user_count') AS INT64) as user_count_numeric,
  
-- 문자열 -> 불린 변환
  CAST(JSON_VALUE(data, '$.metrics.is_profitable') AS BOOL) as is_profitable_bool,
  
-- 문자열 -> 날짜 변환
  CAST(JSON_VALUE(data, '$.metrics.launch_date') AS DATE) as launch_date,
  
-- SAFE_CAST로 안전한 변환
  SAFE_CAST(JSON_VALUE(data, '$.metrics.revenue') AS FLOAT64) as revenue_safe,
  
-- NULL 처리
  COALESCE(
    SAFE_CAST(JSON_VALUE(data, '$.metrics.invalid_field') AS INT64), 
    0
  ) as default_zero
  
FROM json_data;
```

### 2.3 JSON 검증 및 타입 확인

```sql
-- JSON 유효성 검사
WITH test_data AS (
  SELECT 
    '{"valid": "json"}' as valid_json_string,
    '{"invalid": json}' as invalid_json_string,
    JSON '{"already": "parsed"}' as parsed_json
)
SELECT 
-- 유효한 JSON인지 확인
  valid_json_string,
  JSON_EXTRACT(SAFE.PARSE_JSON(valid_json_string), '$') is not null as is_valid_json,
  
-- 안전한 JSON 파싱
  SAFE.PARSE_JSON(valid_json_string) as parsed_from_string,
  SAFE.PARSE_JSON(invalid_json_string) as parsed_invalid, -- NULL 반환
  
-- JSON 타입 확인
  JSON_TYPE(JSON_EXTRACT(parsed_json, '$.already')) as field_type
  
FROM test_data;
```

---

## 3. JSON 추출 및 변환

### 3.1 복잡한 JSON Path 사용

```sql
WITH complex_json AS (
  SELECT JSON '''{
    "event": {
      "type": "purchase",
      "timestamp": "2024-01-15T10:30:00Z",
      "user": {
        "id": 12345,
        "profile": {
          "preferences": {
            "categories": ["electronics", "books"],
            "notifications": {
              "email": true,
              "sms": false
            }
          }
        }
      },
      "items": [
        {"sku": "LAPTOP001", "quantity": 1, "price": 999.99},
        {"sku": "MOUSE001", "quantity": 2, "price": 25.00}
      ]
    }
  }''' as event_data
)
SELECT 
  event_data,
  
-- 중첩된 객체 접근
  JSON_VALUE(event_data, '$.event.user.id') as user_id,
  JSON_VALUE(event_data, '$.event.user.profile.preferences.notifications.email') as email_notifications,
  
-- 배열의 첫 번째 요소 접근
  JSON_VALUE(event_data, '$.event.items[0].sku') as first_item_sku,
  JSON_VALUE(event_data, '$.event.items[0].price') as first_item_price,
  
-- 배열 길이 계산
  JSON_VALUE(event_data, '$.event.items.size()') as items_count,
  
-- 조건부 필터링 (JSONPath 고급 기능)
  JSON_EXTRACT(event_data, '$.event.items[?@.price > 100]') as expensive_items
  
FROM complex_json;
```

### 3.2 동적 JSON Path

```sql
-- 변수를 사용한 동적 경로 (제한적)
WITH dynamic_access AS (
  SELECT 
    JSON '{"user_123": {"name": "Alice"}, "user_456": {"name": "Bob"}}' as users_data,
    'user_123' as target_user_id
)
SELECT 
  users_data,
  target_user_id,
  
-- CONCAT을 사용한 동적 경로 (JSON_EXTRACT_SCALAR 사용)
  JSON_EXTRACT_SCALAR(users_data, CONCAT('$.', target_user_id, '.name')) as user_name,
  
-- 더 복잡한 동적 접근을 위해서는 JavaScript UDF 사용 고려
FROM dynamic_access;
```

---

## 4. JSON 배열 처리

### 4.1 JSON 배열을 테이블 행으로 변환

```sql
-- JSON 배열을 행으로 펼치기
WITH json_with_arrays AS (
  SELECT 
    'order_001' as order_id,
    JSON '''{
      "customer_id": "CUST123",
      "items": [
        {"product_id": "P001", "name": "Laptop", "quantity": 1, "price": 999.99},
        {"product_id": "P002", "name": "Mouse", "quantity": 2, "price": 25.00},
        {"product_id": "P003", "name": "Keyboard", "quantity": 1, "price": 75.00}
      ],
      "shipping_addresses": [
        {"type": "home", "address": "123 Main St, NY"},
        {"type": "office", "address": "456 Work Ave, NY"}
      ]
    }''' as order_data
)
SELECT 
  order_id,
  JSON_VALUE(order_data, '$.customer_id') as customer_id,
  
-- JSON 배열의 각 요소에서 데이터 추출
  JSON_VALUE(item, '$.product_id') as product_id,
  JSON_VALUE(item, '$.name') as product_name,
  CAST(JSON_VALUE(item, '$.quantity') AS INT64) as quantity,
  CAST(JSON_VALUE(item, '$.price') AS FLOAT64) as price,
  
-- 계산 필드
  CAST(JSON_VALUE(item, '$.quantity') AS INT64) * 
  CAST(JSON_VALUE(item, '$.price') AS FLOAT64) as line_total
  
FROM json_with_arrays,
UNNEST(JSON_VALUE_ARRAY(order_data, '$.items')) as item;
```

### 4.2 JSON 배열 집계

```sql
WITH product_reviews AS (
  SELECT 
    'PROD001' as product_id,
    JSON '''{
      "reviews": [
        {"user_id": "U001", "rating": 5, "comment": "Excellent!"},
        {"user_id": "U002", "rating": 4, "comment": "Good quality"},
        {"user_id": "U003", "rating": 3, "comment": "Average"},
        {"user_id": "U004", "rating": 5, "comment": "Love it!"},
        {"user_id": "U005", "rating": 2, "comment": "Not satisfied"}
      ]
    }''' as review_data
)
SELECT 
  product_id,
  
-- 리뷰 총 개수
  ARRAY_LENGTH(JSON_VALUE_ARRAY(review_data, '$.reviews')) as total_reviews,
  
-- 평균 평점 계산
  ROUND(
    (SELECT AVG(CAST(JSON_VALUE(review, '$.rating') AS INT64))
     FROM UNNEST(JSON_VALUE_ARRAY(review_data, '$.reviews')) as review), 2
  ) as average_rating,
  
-- 5점 리뷰 개수
  (SELECT COUNT(*)
   FROM UNNEST(JSON_VALUE_ARRAY(review_data, '$.reviews')) as review
   WHERE CAST(JSON_VALUE(review, '$.rating') AS INT64) = 5
  ) as five_star_count,
  
-- 모든 평점 분포
  ARRAY(
    SELECT STRUCT(
      rating,
      COUNT(*) as count
    )
    FROM (
      SELECT CAST(JSON_VALUE(review, '$.rating') AS INT64) as rating
      FROM UNNEST(JSON_VALUE_ARRAY(review_data, '$.reviews')) as review
    )
    GROUP BY rating
    ORDER BY rating DESC
  ) as rating_distribution
  
FROM product_reviews;
```

### 4.3 중첩된 JSON 배열 처리

```sql
WITH nested_json AS (
  SELECT JSON '''{
    "departments": [
      {
        "name": "Engineering",
        "employees": [
          {"name": "John", "skills": ["Python", "SQL", "Java"]},
          {"name": "Alice", "skills": ["JavaScript", "React", "Node.js"]}
        ]
      },
      {
        "name": "Marketing", 
        "employees": [
          {"name": "Bob", "skills": ["SEO", "Analytics", "Content"]},
          {"name": "Carol", "skills": ["Design", "Adobe", "Figma"]}
        ]
      }
    ]
  }''' as company_data
)
SELECT 
  JSON_VALUE(dept, '$.name') as department_name,
  JSON_VALUE(emp, '$.name') as employee_name,
  skill
FROM nested_json,
UNNEST(JSON_VALUE_ARRAY(company_data, '$.departments')) as dept,
UNNEST(JSON_VALUE_ARRAY(dept, '$.employees')) as emp,
UNNEST(JSON_VALUE_ARRAY(emp, '$.skills')) as skill
ORDER BY department_name, employee_name, skill;
```

---

## 5. JSON 스키마 처리

### 5.1 동적 스키마 발견

```sql
-- JSON 스키마 분석
WITH sample_events AS (
  SELECT event_data FROM (
    SELECT JSON '{"event_type": "click", "user_id": 123, "page": "/home"}' as event_data
    UNION ALL
    SELECT JSON '{"event_type": "purchase", "user_id": 456, "amount": 99.99, "currency": "USD"}'
    UNION ALL
    SELECT JSON '{"event_type": "signup", "user_id": 789, "email": "user@example.com", "source": "google"}'
  )
),
key_analysis AS (
  SELECT 
    event_data,
    JSON_KEYS(event_data) as all_keys
  FROM sample_events
)
SELECT 
-- 모든 고유 키 목록
  ARRAY(
    SELECT DISTINCT key
    FROM key_analysis,
    UNNEST(all_keys) as key
    ORDER BY key
  ) as unique_keys,
  
-- 키별 출현 빈도
  ARRAY(
    SELECT STRUCT(key, COUNT(*) as frequency)
    FROM key_analysis,
    UNNEST(all_keys) as key
    GROUP BY key
    ORDER BY frequency DESC
  ) as key_frequencies;
```

### 5.2 스키마 진화 처리

```sql
-- 버전별로 다른 JSON 스키마 처리
WITH versioned_data AS (
  SELECT 
    1 as version,
    JSON '{"user_id": 123, "name": "John"}' as user_data
  UNION ALL
  SELECT 
    2 as version,
    JSON '{"user_id": 456, "profile": {"first_name": "Jane", "last_name": "Doe"}}'
  UNION ALL
  SELECT 
    3 as version,
    JSON '{"user_id": 789, "profile": {"full_name": "Bob Smith", "email": "bob@example.com"}}'
)
SELECT 
  version,
  user_data,
  
-- 버전에 따른 다른 추출 방식
  CASE version
    WHEN 1 THEN JSON_VALUE(user_data, '$.name')
    WHEN 2 THEN CONCAT(
      JSON_VALUE(user_data, '$.profile.first_name'), ' ',
      JSON_VALUE(user_data, '$.profile.last_name')
    )
    WHEN 3 THEN JSON_VALUE(user_data, '$.profile.full_name')
  END as user_name,
  
-- 안전한 다중 경로 시도
  COALESCE(
    JSON_VALUE(user_data, '$.name'),                    -- v1 형식
    JSON_VALUE(user_data, '$.profile.full_name'),      -- v3 형식
    CONCAT(                                             -- v2 형식
      JSON_VALUE(user_data, '$.profile.first_name'), ' ',
      JSON_VALUE(user_data, '$.profile.last_name')
    )
  ) as normalized_name
  
FROM versioned_data;
```

---

## 6. JSON과 구조체 변환

### 6.1 JSON을 구조체로 변환

```sql
-- JSON 데이터를 구조화된 STRUCT로 변환
WITH json_orders AS (
  SELECT JSON '''{
    "order_id": "ORD123",
    "customer": {
      "id": "CUST456", 
      "name": "John Doe",
      "email": "john@example.com"
    },
    "items": [
      {"sku": "ITEM001", "quantity": 2, "price": 29.99},
      {"sku": "ITEM002", "quantity": 1, "price": 49.99}
    ],
    "shipping": {
      "method": "standard",
      "address": "123 Main St, City, State"
    }
  }''' as order_json
)
SELECT 
  order_json,
  
-- JSON을 구조체로 변환
  STRUCT(
    JSON_VALUE(order_json, '$.order_id') as order_id,
    STRUCT(
      JSON_VALUE(order_json, '$.customer.id') as customer_id,
      JSON_VALUE(order_json, '$.customer.name') as name,
      JSON_VALUE(order_json, '$.customer.email') as email
    ) as customer,
    ARRAY(
      SELECT STRUCT(
        JSON_VALUE(item, '$.sku') as sku,
        CAST(JSON_VALUE(item, '$.quantity') AS INT64) as quantity,
        CAST(JSON_VALUE(item, '$.price') AS FLOAT64) as price
      )
      FROM UNNEST(JSON_VALUE_ARRAY(order_json, '$.items')) as item
    ) as items,
    STRUCT(
      JSON_VALUE(order_json, '$.shipping.method') as method,
      JSON_VALUE(order_json, '$.shipping.address') as address
    ) as shipping
  ) as structured_order
  
FROM json_orders;
```

### 6.2 구조체를 JSON으로 변환

```sql
-- 구조화된 데이터를 JSON으로 변환
WITH structured_data AS (
  SELECT 
    'ORDER123' as order_id,
    STRUCT(
      'CUST456' as id,
      'John Doe' as name,
      'john@example.com' as email
    ) as customer,
    [
      STRUCT('ITEM001' as sku, 2 as quantity, 29.99 as price),
      STRUCT('ITEM002' as sku, 1 as quantity, 49.99 as price)
    ] as items
)
SELECT 
  order_id,
  customer,
  items,
  
-- 구조체를 JSON으로 변환
  TO_JSON_STRING(
    STRUCT(
      order_id,
      customer,
      items,
      CURRENT_TIMESTAMP() as created_at
    )
  ) as order_json,
  
-- 개별 필드를 JSON으로
  TO_JSON_STRING(customer) as customer_json,
  TO_JSON_STRING(items) as items_json
  
FROM structured_data;
```

---

## 7. 실제 활용 사례

### 7.1 웹 로그 분석

```sql
-- 웹 서버 로그 JSON 분석
WITH web_logs AS (
  SELECT 
    log_timestamp,
    JSON_PARSE(log_data) as parsed_log
  FROM raw_web_logs
  WHERE DATE(log_timestamp) = CURRENT_DATE()
),
processed_logs AS (
  SELECT 
    log_timestamp,
    JSON_VALUE(parsed_log, '$.request.method') as http_method,
    JSON_VALUE(parsed_log, '$.request.url') as request_url,
    CAST(JSON_VALUE(parsed_log, '$.response.status') AS INT64) as status_code,
    CAST(JSON_VALUE(parsed_log, '$.response.size') AS INT64) as response_size,
    JSON_VALUE(parsed_log, '$.user_agent') as user_agent,
    JSON_VALUE(parsed_log, '$.client_ip') as client_ip,
    CAST(JSON_VALUE(parsed_log, '$.response_time_ms') AS FLOAT64) as response_time
  FROM web_logs
  WHERE JSON_VALUE(parsed_log, '$.request.method') IS NOT NULL
)
SELECT 
-- 요청 통계
  http_method,
  COUNT(*) as request_count,
  
-- 상태 코드 분포
  COUNTIF(status_code >= 200 AND status_code < 300) as success_count,
  COUNTIF(status_code >= 400 AND status_code < 500) as client_error_count,  
  COUNTIF(status_code >= 500) as server_error_count,
  
-- 성능 메트릭
  ROUND(AVG(response_time), 2) as avg_response_time,
  ROUND(PERCENTILE_CONT(response_time, 0.95) OVER(), 2) as p95_response_time,
  
-- 대용량 응답
  COUNTIF(response_size > 1024 * 1024) as large_response_count,
  
-- 상위 URL
  ARRAY_AGG(
    STRUCT(request_url, COUNT(*) as hits)
    ORDER BY COUNT(*) DESC LIMIT 5
  ) as top_urls
  
FROM processed_logs
GROUP BY http_method
ORDER BY request_count DESC;
```

### 7.2 IoT 센서 데이터 분석

```sql
-- IoT 디바이스에서 전송된 JSON 센서 데이터 분석
WITH iot_readings AS (
  SELECT 
    device_id,
    reading_timestamp,
    JSON_PARSE(sensor_data) as readings
  FROM iot_sensor_logs
  WHERE DATE(reading_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
),
sensor_metrics AS (
  SELECT 
    device_id,
    reading_timestamp,
    readings,
    
-- 온도 센서
    CAST(JSON_VALUE(readings, '$.temperature.value') AS FLOAT64) as temperature,
    JSON_VALUE(readings, '$.temperature.unit') as temp_unit,
    JSON_VALUE(readings, '$.temperature.status') as temp_status,
    
-- 습도 센서  
    CAST(JSON_VALUE(readings, '$.humidity.value') AS FLOAT64) as humidity,
    JSON_VALUE(readings, '$.humidity.unit') as humidity_unit,
    
-- 압력 센서
    CAST(JSON_VALUE(readings, '$.pressure.value') AS FLOAT64) as pressure,
    
-- 배터리 정보
    CAST(JSON_VALUE(readings, '$.battery.level') AS FLOAT64) as battery_level,
    JSON_VALUE(readings, '$.battery.status') as battery_status,
    
-- 모든 센서 상태 확인
    JSON_KEYS(readings) as available_sensors
  FROM iot_readings
),
device_health AS (
  SELECT 
    device_id,
    COUNT(*) as total_readings,
    
-- 온도 통계
    ROUND(AVG(temperature), 2) as avg_temperature,
    ROUND(MIN(temperature), 2) as min_temperature,
    ROUND(MAX(temperature), 2) as max_temperature,
    
-- 습도 통계
    ROUND(AVG(humidity), 2) as avg_humidity,
    
-- 배터리 상태
    MIN(battery_level) as min_battery_level,
    
-- 경고 조건 체크
    COUNTIF(temperature > 40 OR temperature < 0) as temp_warning_count,
    COUNTIF(humidity > 80) as humidity_warning_count,
    COUNTIF(battery_level < 20) as low_battery_count,
    
-- 센서 오류 체크
    COUNTIF(temp_status != 'OK') as temp_error_count,
    
-- 최근 읽기
    MAX(reading_timestamp) as last_reading_time
    
  FROM sensor_metrics
  WHERE temperature IS NOT NULL  -- 유효한 온도 데이터만
  GROUP BY device_id
)
SELECT 
  device_id,
  total_readings,
  avg_temperature,
  avg_humidity,
  min_battery_level,
  
-- 디바이스 상태 분류
  CASE 
    WHEN temp_warning_count > 0 OR humidity_warning_count > 0 THEN 'WARNING'
    WHEN low_battery_count > 0 THEN 'LOW_BATTERY'
    WHEN temp_error_count > 0 THEN 'ERROR'
    ELSE 'HEALTHY'
  END as device_status,
  
-- 마지막 통신 시간
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), last_reading_time, MINUTE) as minutes_since_last_reading
  
FROM device_health
ORDER BY 
  CASE device_status
    WHEN 'ERROR' THEN 1
    WHEN 'WARNING' THEN 2  
    WHEN 'LOW_BATTERY' THEN 3
    ELSE 4
  END,
  minutes_since_last_reading DESC;
```

### 7.3 A/B 테스트 결과 분석

```sql
-- A/B 테스트 이벤트 로그 분석
WITH ab_test_events AS (
  SELECT 
    user_id,
    event_timestamp,
    JSON_PARSE(event_data) as event_json
  FROM user_events
  WHERE event_name = 'ab_test_event'
    AND DATE(event_timestamp) BETWEEN '2024-01-01' AND '2024-01-31'
),
test_assignments AS (
  SELECT 
    user_id,
    JSON_VALUE(event_json, '$.test_name') as test_name,
    JSON_VALUE(event_json, '$.variant') as variant,
    JSON_VALUE(event_json, '$.assignment_timestamp') as assignment_time,
    
-- 사용자 특성
    JSON_VALUE(event_json, '$.user_properties.country') as country,
    JSON_VALUE(event_json, '$.user_properties.platform') as platform,
    CAST(JSON_VALUE(event_json, '$.user_properties.is_premium') AS BOOL) as is_premium,
    
-- 테스트 설정
    JSON_VALUE(event_json, '$.test_config.goal_metric') as goal_metric,
    CAST(JSON_VALUE(event_json, '$.test_config.traffic_split') AS FLOAT64) as traffic_split
    
  FROM ab_test_events
  WHERE JSON_VALUE(event_json, '$.event_type') = 'assignment'
),
test_conversions AS (
  SELECT 
    user_id,
    JSON_VALUE(event_json, '$.test_name') as test_name,
    JSON_VALUE(event_json, '$.conversion_type') as conversion_type,
    CAST(JSON_VALUE(event_json, '$.conversion_value') AS FLOAT64) as conversion_value,
    event_timestamp as conversion_time
    
  FROM ab_test_events  
  WHERE JSON_VALUE(event_json, '$.event_type') = 'conversion'
)
SELECT 
  a.test_name,
  a.variant,
  
-- 기본 통계
  COUNT(DISTINCT a.user_id) as assigned_users,
  COUNT(DISTINCT c.user_id) as converted_users,
  
-- 전환율
  ROUND(
    COUNT(DISTINCT c.user_id) * 100.0 / COUNT(DISTINCT a.user_id), 2
  ) as conversion_rate_pct,
  
-- 전환 가치
  ROUND(AVG(c.conversion_value), 2) as avg_conversion_value,
  ROUND(SUM(c.conversion_value), 2) as total_conversion_value,
  
-- 세그먼트별 분석
  ROUND(
    COUNT(DISTINCT CASE WHEN a.is_premium THEN c.user_id END) * 100.0 / 
    COUNT(DISTINCT CASE WHEN a.is_premium THEN a.user_id END), 2
  ) as premium_conversion_rate_pct,
  
  ROUND(
    COUNT(DISTINCT CASE WHEN NOT a.is_premium THEN c.user_id END) * 100.0 / 
    COUNT(DISTINCT CASE WHEN NOT a.is_premium THEN a.user_id END), 2  
  ) as free_conversion_rate_pct,
  
-- 플랫폼별 분포
  STRING_AGG(
    CONCAT(a.platform, ': ', COUNT(DISTINCT a.user_id)), 
    ', ' ORDER BY COUNT(DISTINCT a.user_id) DESC
  ) as platform_distribution
  
FROM test_assignments a
LEFT JOIN test_conversions c ON a.user_id = c.user_id AND a.test_name = c.test_name
GROUP BY a.test_name, a.variant
ORDER BY a.test_name, a.variant;
```

---

## 8. 성능 최적화

### 8.1 JSON 추출 최적화

```sql
-- ❌ 비효율적: 반복적인 JSON 파싱
SELECT 
  JSON_VALUE(json_data, '$.user.id') as user_id,
  JSON_VALUE(json_data, '$.user.name') as user_name,
  JSON_VALUE(json_data, '$.user.email') as user_email,
  JSON_VALUE(json_data, '$.user.created_at') as created_at
FROM large_json_table;

-- ✅ 효율적: 한 번에 추출 후 재사용
WITH extracted_data AS (
  SELECT 
    json_data,
    JSON_EXTRACT(json_data, '$.user') as user_json
  FROM large_json_table
)
SELECT 
  JSON_VALUE(user_json, '$.id') as user_id,
  JSON_VALUE(user_json, '$.name') as user_name,
  JSON_VALUE(user_json, '$.email') as user_email,
  JSON_VALUE(user_json, '$.created_at') as created_at
FROM extracted_data;
```

### 8.2 JSON 컬럼 인덱싱 (Generated Column)

```sql
-- JSON 필드에 대한 생성된 컬럼 사용
CREATE TABLE user_events (
  event_id STRING,
  event_data JSON,
  
-- 자주 쿼리되는 JSON 필드를 생성된 컬럼으로 추출
  user_id STRING GENERATED ALWAYS AS (JSON_VALUE(event_data, '$.user_id')) STORED,
  event_type STRING GENERATED ALWAYS AS (JSON_VALUE(event_data, '$.event_type')) STORED,
  event_timestamp TIMESTAMP GENERATED ALWAYS AS (
    TIMESTAMP(JSON_VALUE(event_data, '$.timestamp'))
  ) STORED
)
PARTITION BY DATE(event_timestamp)
CLUSTER BY user_id, event_type;
```

### 8.3 JSON 스트림 처리 최적화

```sql
-- 대용량 JSON 배열 처리 시 메모리 최적화
WITH large_json_data AS (
  SELECT json_array_data
  FROM source_table
  WHERE DATE(partition_date) = CURRENT_DATE()
)
SELECT 
  -- 큰 JSON 배열을 청크 단위로 처리
  ARRAY(
    SELECT JSON_VALUE(item, '$.id')
    FROM UNNEST(JSON_VALUE_ARRAY(json_array_data, '$.items')) as item
    WITH OFFSET pos
    WHERE pos < 1000  -- 처음 1000개만 처리
  ) as processed_items
FROM large_json_data;
```

---

## 9. 모범 사례와 주의점

### 9.1 모범 사례

#### 1. JSON 스키마 일관성 유지
```sql
-- ✅ 좋은 예: 일관된 JSON 구조
CREATE TABLE events (
  event_id STRING,
  event_data JSON,
  -- 스키마 검증
  CONSTRAINT valid_event_type CHECK (
    JSON_VALUE(event_data, '$.event_type') IN ('click', 'view', 'purchase')
  )
);
```

#### 2. 적절한 타입 변환
```sql
-- ✅ 좋은 예: 안전한 타입 변환
SELECT 
  JSON_VALUE(data, '$.user_id') as user_id,
  SAFE_CAST(JSON_VALUE(data, '$.age') AS INT64) as age,
  COALESCE(
    SAFE_CAST(JSON_VALUE(data, '$.created_at') AS TIMESTAMP),
    CURRENT_TIMESTAMP()
  ) as created_at
FROM json_table;
```

#### 3. 효율적인 JSON Path 사용
```sql
-- ✅ 좋은 예: 구체적인 경로 지정
SELECT 
  JSON_VALUE(data, '$.user.profile.email') as email,
  JSON_VALUE(data, '$.order.items[0].price') as first_item_price
FROM orders;
```

### 9.2 주의점

#### 1. NULL 처리
```sql
-- JSON에서 NULL vs 존재하지 않는 필드
WITH test_data AS (
  SELECT JSON '{"field1": null, "field2": "value"}' as data
)
SELECT 
  JSON_VALUE(data, '$.field1') as explicit_null,    -- null
  JSON_VALUE(data, '$.field3') as missing_field,    -- null
  JSON_VALUE(data, '$.field1') IS NULL as is_null1, -- true
  JSON_VALUE(data, '$.field3') IS NULL as is_null3  -- true
FROM test_data;

-- 구분하여 처리
SELECT 
  CASE 
    WHEN JSON_TYPE(JSON_EXTRACT(data, '$.field1')) = 'null' THEN 'explicit_null'
    WHEN JSON_EXTRACT(data, '$.field1') IS NULL THEN 'missing'
    ELSE 'has_value'
  END as field_status
FROM test_data;
```

#### 2. 대소문자 구분
```sql
-- JSON 키는 대소문자를 구분함
WITH case_sensitive AS (
  SELECT JSON '{"userName": "john", "username": "jane"}' as data
)
SELECT 
  JSON_VALUE(data, '$.userName') as camel_case,  -- "john"
  JSON_VALUE(data, '$.username') as lower_case   -- "jane"
FROM case_sensitive;
```

#### 3. 배열 인덱스 경계 확인
```sql
-- 안전한 배열 접근
WITH array_data AS (
  SELECT JSON '{"items": ["a", "b", "c"]}' as data
)
SELECT 
  JSON_VALUE(data, '$.items[0]') as first_item,   -- "a"
  JSON_VALUE(data, '$.items[10]') as out_of_bounds -- null (오류 없음)
FROM array_data;
```

### 9.3 디버깅 팁

```sql
-- JSON 구조 탐색을 위한 디버깅 쿼리
WITH debug_sample AS (
  SELECT json_data 
  FROM large_json_table 
  LIMIT 1
)
SELECT 
  -- JSON 구조 확인
  TO_JSON_STRING(json_data) as formatted_json,
  
  -- 최상위 키 확인
  JSON_KEYS(json_data) as top_level_keys,
  
  -- 특정 경로 타입 확인
  JSON_TYPE(JSON_EXTRACT(json_data, '$.user')) as user_type,
  JSON_TYPE(JSON_EXTRACT(json_data, '$.items')) as items_type,
  
  -- 배열 크기 확인
  ARRAY_LENGTH(JSON_VALUE_ARRAY(json_data, '$.items')) as items_count,
  
  -- 샘플 값 확인
  JSON_EXTRACT(json_data, '$.items[0]') as first_item_sample
FROM debug_sample;
```

---

BigQuery의 JSON 처리 기능을 활용하면 반구조화 데이터를 효율적으로 분석할 수 있습니다. 적절한 함수 선택과 성능 최적화를 통해 복잡한 JSON 데이터에서도 인사이트를 도출할 수 있습니다.
