# BigQuery CTAS 완벽 가이드

BigQuery에서 CREATE TABLE AS SELECT (CTAS) 구문을 활용한 테이블 생성, 데이터 변환, 성능 최적화를 위한 종합 가이드입니다.

---

## 목차

1. [CTAS의 개념과 정의](#1-ctas의-개념과-정의)
2. [기본 문법과 구조](#2-기본-문법과-구조)
3. [테이블 옵션과 설정](#3-테이블-옵션과-설정)
4. [파티셔닝과 클러스터링](#4-파티셔닝과-클러스터링)
5. [데이터 변환과 처리](#5-데이터-변환과-처리)
6. [성능 최적화 전략](#6-성능-최적화-전략)
7. [실제 활용 사례](#7-실제-활용-사례)
8. [CTAS vs 기타 방법들](#8-ctas-vs-기타-방법들)
9. [모범 사례와 주의점](#9-모범-사례와-주의점)

---

## 1. CTAS의 개념과 정의

### 1.1 CTAS란?

**CREATE TABLE AS SELECT (CTAS)**는 SELECT 쿼리의 결과를 바탕으로 새로운 테이블을 생성하는 BigQuery의 핵심 기능입니다.

- **테이블 생성과 데이터 삽입을 동시에**: 스키마 정의와 데이터 로딩을 한 번에 처리
- **자동 스키마 추론**: SELECT 결과에서 컬럼 타입을 자동 결정
- **효율적인 데이터 변환**: ETL 파이프라인에서 핵심 역할

### 1.2 CTAS의 주요 장점

```sql
-- 기존 방식: 별도 테이블 생성 후 데이터 삽입
CREATE TABLE dataset.new_table (
  id INT64,
  name STRING,
  created_date DATE
);

INSERT INTO dataset.new_table
SELECT id, name, CURRENT_DATE()
FROM dataset.source_table;

-- CTAS 방식: 한 번에 처리
CREATE TABLE dataset.new_table AS
SELECT 
  id,
  name,
  CURRENT_DATE() as created_date
FROM dataset.source_table;
```

**장점:**
- **간단한 문법**: 복잡한 스키마 정의 불필요
- **높은 성능**: 내부 최적화된 데이터 복사
- **원자성**: 테이블 생성과 데이터 로딩이 단일 트랜잭션
- **유연성**: 복잡한 변환 로직 적용 가능

---

## 2. 기본 문법과 구조

### 2.1 기본 구문

```sql
CREATE [OR REPLACE] TABLE [IF NOT EXISTS] dataset_name.table_name
[PARTITION BY partition_expression]
[CLUSTER BY cluster_column_list]
[OPTIONS (
  description = "테이블 설명",
  expiration_timestamp = TIMESTAMP("2024-12-31 00:00:00"),
  labels = [("env", "prod"), ("team", "analytics")]
)]
AS 
SELECT_STATEMENT;
```

### 2.2 구문 요소 설명

#### OR REPLACE
```sql
-- 기존 테이블이 존재하면 대체
CREATE OR REPLACE TABLE mydataset.sales_summary AS
SELECT 
  DATE(order_date) as sale_date,
  COUNT(*) as total_orders,
  SUM(amount) as total_revenue
FROM mydataset.orders
WHERE order_date >= '2024-01-01'
GROUP BY DATE(order_date);
```

#### IF NOT EXISTS
```sql
-- 테이블이 없을 때만 생성 (멱등성 보장)
CREATE TABLE IF NOT EXISTS mydataset.customer_segments AS
SELECT 
  customer_id,
  CASE 
    WHEN total_spent >= 10000 THEN 'VIP'
    WHEN total_spent >= 5000 THEN 'PREMIUM'
    ELSE 'STANDARD'
  END as segment
FROM mydataset.customer_summary;
```

### 2.3 데이터 타입 추론

```sql
-- 자동 타입 추론 예시
CREATE TABLE mydataset.type_inference AS
SELECT 
  123 as integer_column,           -- INT64
  123.45 as float_column,          -- FLOAT64
  'Hello World' as string_column,  -- STRING
  TRUE as boolean_column,          -- BOOL
  CURRENT_DATE() as date_column,   -- DATE
  CURRENT_TIMESTAMP() as ts_column -- TIMESTAMP
;

-- 명시적 타입 캐스팅
CREATE TABLE mydataset.explicit_types AS
SELECT 
  CAST(user_id AS STRING) as user_id_str,
  SAFE_CAST(age AS INT64) as age_int,
  PARSE_DATE('%Y-%m-%d', date_str) as parsed_date
FROM mydataset.raw_data;
```

---

## 3. 테이블 옵션과 설정

### 3.1 기본 테이블 옵션

```sql
CREATE OR REPLACE TABLE mydataset.sales_analytics
OPTIONS (
  description = "일별 매출 분석 테이블",
  expiration_timestamp = TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 90 DAY),
  labels = [("department", "sales"), ("frequency", "daily")],
  friendly_name = "Sales Analytics Daily"
)
AS
SELECT 
  DATE(order_timestamp) as order_date,
  product_category,
  COUNT(*) as order_count,
  SUM(order_amount) as total_revenue,
  AVG(order_amount) as avg_order_value
FROM mydataset.orders
WHERE order_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY DATE(order_timestamp), product_category;
```

### 3.2 암호화 설정

```sql
-- 고객 관리 키(CMEK) 사용
CREATE TABLE mydataset.sensitive_data
OPTIONS (
  kms_key_name = "projects/my-project/locations/us/keyRings/my-ring/cryptoKeys/my-key"
)
AS
SELECT 
  customer_id,
  encrypted_email,
  masked_phone
FROM mydataset.customer_pii;
```

### 3.3 테이블 복제본 설정

```sql
-- 다중 지역 복제본 테이블
CREATE TABLE mydataset.global_sales
OPTIONS (
  max_staleness = INTERVAL 15 MINUTE
)
AS
SELECT 
  region,
  sale_date,
  product_id,
  quantity,
  revenue
FROM mydataset.regional_sales;
```

---

## 4. 파티셔닝과 클러스터링

### 4.1 날짜 파티셔닝

```sql
-- 날짜 컬럼으로 파티셔닝
CREATE TABLE mydataset.daily_events
PARTITION BY event_date
CLUSTER BY user_id, event_type
AS
SELECT 
  user_id,
  event_type,
  event_data,
  DATE(event_timestamp) as event_date,
  event_timestamp
FROM mydataset.raw_events
WHERE event_timestamp >= '2024-01-01';
```

### 4.2 타임스탬프 파티셔닝

```sql
-- 시간별 파티셔닝
CREATE TABLE mydataset.hourly_metrics
PARTITION BY DATETIME_TRUNC(metric_time, HOUR)
CLUSTER BY metric_name, source_system
AS
SELECT 
  metric_name,
  metric_value,
  source_system,
  DATETIME(metric_timestamp) as metric_time
FROM mydataset.raw_metrics
WHERE metric_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY);
```

### 4.3 정수 범위 파티셔닝

```sql
-- 사용자 ID로 범위 파티셔닝
CREATE TABLE mydataset.user_activities
PARTITION BY RANGE_BUCKET(user_id, GENERATE_ARRAY(0, 1000000, 10000))
CLUSTER BY activity_type, activity_date
AS
SELECT 
  user_id,
  activity_type,
  activity_data,
  DATE(activity_timestamp) as activity_date
FROM mydataset.user_events
WHERE user_id BETWEEN 0 AND 1000000;
```

### 4.4 복합 파티셔닝과 클러스터링

```sql
-- 날짜 파티셔닝 + 다중 클러스터링
CREATE TABLE mydataset.ecommerce_orders
PARTITION BY order_date
CLUSTER BY customer_segment, product_category, payment_method
AS
SELECT 
  order_id,
  customer_id,
  customer_segment,
  product_category,
  payment_method,
  order_amount,
  DATE(order_timestamp) as order_date
FROM mydataset.raw_orders o
JOIN mydataset.customers c ON o.customer_id = c.customer_id
WHERE order_timestamp >= '2024-01-01';
```

---

## 5. 데이터 변환과 처리

### 5.1 집계와 요약

```sql
-- 월별 매출 요약 테이블
CREATE OR REPLACE TABLE mydataset.monthly_sales_summary
PARTITION BY sales_month
AS
SELECT 
  DATE_TRUNC(order_date, MONTH) as sales_month,
  product_category,
  region,
  COUNT(*) as order_count,
  COUNT(DISTINCT customer_id) as unique_customers,
  SUM(order_amount) as total_revenue,
  AVG(order_amount) as avg_order_value,
  STDDEV(order_amount) as revenue_stddev,
  MIN(order_amount) as min_order,
  MAX(order_amount) as max_order
FROM mydataset.orders
WHERE order_date >= '2023-01-01'
GROUP BY 
  DATE_TRUNC(order_date, MONTH),
  product_category,
  region;
```

### 5.2 데이터 정제와 표준화

```sql
-- 고객 데이터 정제 테이블
CREATE OR REPLACE TABLE mydataset.cleaned_customers AS
SELECT 
  customer_id,
  -- 이름 정규화
  TRIM(UPPER(REGEXP_REPLACE(customer_name, r'[^a-zA-Z\s]', ''))) as clean_name,
  -- 이메일 검증 및 정제
  CASE 
    WHEN REGEXP_CONTAINS(email, r'^[^@]+@[^@]+\.[^@]+$') 
    THEN LOWER(TRIM(email))
    ELSE NULL 
  END as valid_email,
  -- 전화번호 정규화
  REGEXP_REPLACE(phone, r'[^0-9]', '') as clean_phone,
  -- 주소 표준화
  TRIM(REGEXP_REPLACE(
    REPLACE(REPLACE(address, '  ', ' '), '\n', ' '), 
    r'\s+', ' '
  )) as normalized_address,
  -- 나이 그룹 분류
  CASE 
    WHEN age BETWEEN 18 AND 24 THEN '18-24'
    WHEN age BETWEEN 25 AND 34 THEN '25-34'
    WHEN age BETWEEN 35 AND 44 THEN '35-44'
    WHEN age BETWEEN 45 AND 54 THEN '45-54'
    WHEN age BETWEEN 55 AND 64 THEN '55-64'
    WHEN age >= 65 THEN '65+'
    ELSE 'Unknown'
  END as age_group,
  created_date
FROM mydataset.raw_customers
WHERE customer_id IS NOT NULL;
```

### 5.3 복잡한 윈도우 함수 활용

```sql
-- 고객별 RFM 분석 테이블
CREATE OR REPLACE TABLE mydataset.customer_rfm_analysis AS
WITH customer_metrics AS (
  SELECT 
    customer_id,
    COUNT(*) as frequency,
    SUM(order_amount) as monetary,
    DATE_DIFF(CURRENT_DATE(), MAX(order_date), DAY) as recency,
    AVG(order_amount) as avg_order_value,
    STDDEV(order_amount) as order_value_std
  FROM mydataset.orders
  WHERE order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY)
  GROUP BY customer_id
),
rfm_scores AS (
  SELECT 
    customer_id,
    frequency,
    monetary,
    recency,
    avg_order_value,
    -- RFM 점수 계산 (1-5 스케일)
    NTILE(5) OVER (ORDER BY recency DESC) as recency_score,
    NTILE(5) OVER (ORDER BY frequency) as frequency_score,
    NTILE(5) OVER (ORDER BY monetary) as monetary_score
  FROM customer_metrics
)
SELECT 
  customer_id,
  frequency,
  monetary,
  recency,
  avg_order_value,
  recency_score,
  frequency_score,
  monetary_score,
  -- 통합 RFM 점수
  (recency_score + frequency_score + monetary_score) / 3 as rfm_score,
  -- 고객 세그먼트 분류
  CASE 
    WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
    WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
    WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
    WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
    WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Lost Customers'
    ELSE 'Potential Loyalists'
  END as customer_segment
FROM rfm_scores;
```

---

## 6. 성능 최적화 전략

### 6.1 효율적인 JOIN 처리

```sql
-- 대용량 테이블 JOIN 최적화
CREATE OR REPLACE TABLE mydataset.order_details_optimized
PARTITION BY order_date
CLUSTER BY customer_id, product_id
AS
SELECT 
  o.order_id,
  o.customer_id,
  c.customer_name,
  c.customer_segment,
  p.product_id,
  p.product_name,
  p.category,
  o.quantity,
  o.unit_price,
  o.quantity * o.unit_price as total_amount,
  DATE(o.order_timestamp) as order_date
FROM mydataset.orders o
JOIN mydataset.customers c ON o.customer_id = c.customer_id
JOIN mydataset.products p ON o.product_id = p.product_id
WHERE o.order_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
  AND c.status = 'active'
  AND p.is_available = TRUE;
```

### 6.2 데이터 스큐 최적화

```sql
-- 데이터 스큐 방지를 위한 균등 분산
CREATE OR REPLACE TABLE mydataset.balanced_user_events
PARTITION BY event_date
CLUSTER BY user_bucket, event_type
AS
SELECT 
  user_id,
  event_type,
  event_data,
  -- 사용자를 균등하게 100개 버킷으로 분산
  MOD(ABS(FARM_FINGERPRINT(CAST(user_id AS STRING))), 100) as user_bucket,
  DATE(event_timestamp) as event_date,
  event_timestamp
FROM mydataset.user_events
WHERE event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);
```

### 6.3 중복 제거 최적화

```sql
-- 효율적인 중복 제거
CREATE OR REPLACE TABLE mydataset.deduplicated_transactions
PARTITION BY transaction_date
CLUSTER BY account_id
AS
SELECT 
  transaction_id,
  account_id,
  transaction_amount,
  transaction_type,
  DATE(transaction_timestamp) as transaction_date,
  transaction_timestamp
FROM (
  SELECT 
    *,
    ROW_NUMBER() OVER (
      PARTITION BY transaction_id 
      ORDER BY _file_time DESC, transaction_timestamp DESC
    ) as rn
  FROM mydataset.raw_transactions
  WHERE DATE(transaction_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
)
WHERE rn = 1;
```

---

## 7. 실제 활용 사례

### 7.1 데이터 웨어하우스 구축

```sql
-- 팩트 테이블 생성
CREATE OR REPLACE TABLE datawarehouse.fact_sales
PARTITION BY sale_date
CLUSTER BY customer_key, product_key
AS
SELECT 
  -- 대리 키 생성
  GENERATE_UUID() as sale_key,
  dc.customer_key,
  dp.product_key,
  dd.date_key,
  -- 측정값
  s.quantity,
  s.unit_price,
  s.total_amount,
  s.discount_amount,
  s.tax_amount,
  -- 계산된 측정값
  s.total_amount - s.discount_amount - s.tax_amount as net_amount,
  s.unit_price * s.quantity as gross_amount,
  -- 날짜 차원
  DATE(s.sale_timestamp) as sale_date
FROM mydataset.sales s
JOIN datawarehouse.dim_customers dc ON s.customer_id = dc.customer_id
JOIN datawarehouse.dim_products dp ON s.product_id = dp.product_id
JOIN datawarehouse.dim_dates dd ON DATE(s.sale_timestamp) = dd.date_value
WHERE s.sale_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 YEAR);
```

### 7.2 실시간 대시보드용 집계 테이블

```sql
-- 실시간 KPI 대시보드용 테이블
CREATE OR REPLACE TABLE analytics.realtime_kpis
PARTITION BY kpi_date
AS
WITH hourly_metrics AS (
  SELECT 
    DATETIME_TRUNC(event_timestamp, HOUR) as hour_dt,
    COUNT(*) as total_events,
    COUNT(DISTINCT user_id) as active_users,
    COUNT(DISTINCT session_id) as active_sessions,
    COUNTIF(event_type = 'purchase') as purchases,
    SUM(CASE WHEN event_type = 'purchase' THEN revenue ELSE 0 END) as revenue
  FROM mydataset.events
  WHERE event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  GROUP BY DATETIME_TRUNC(event_timestamp, HOUR)
)
SELECT 
  DATE(hour_dt) as kpi_date,
  EXTRACT(HOUR FROM hour_dt) as hour_of_day,
  total_events,
  active_users,
  active_sessions,
  purchases,
  revenue,
  -- 전환율 계산
  SAFE_DIVIDE(purchases, active_users) * 100 as conversion_rate,
  -- ARPU 계산
  SAFE_DIVIDE(revenue, active_users) as arpu,
  -- 세션당 이벤트 수
  SAFE_DIVIDE(total_events, active_sessions) as events_per_session
FROM hourly_metrics;
```

### 7.3 머신러닝용 피처 테이블

```sql
-- ML 모델용 피처 엔지니어링
CREATE OR REPLACE TABLE ml_features.customer_churn_features
AS
WITH customer_activity AS (
  SELECT 
    customer_id,
    -- 기본 통계
    COUNT(*) as total_orders,
    SUM(order_amount) as total_spent,
    AVG(order_amount) as avg_order_value,
    STDDEV(order_amount) as order_value_std,
    -- 시간 기반 피처
    DATE_DIFF(CURRENT_DATE(), MAX(order_date), DAY) as days_since_last_order,
    DATE_DIFF(MAX(order_date), MIN(order_date), DAY) as customer_lifetime_days,
    -- 행동 패턴
    COUNT(DISTINCT product_category) as category_diversity,
    COUNT(DISTINCT DATE_TRUNC(order_date, MONTH)) as active_months,
    -- 최근 3개월 vs 이전 3개월 비교
    COUNTIF(order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)) as recent_orders,
    COUNTIF(order_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH) 
            AND DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)) as previous_orders
  FROM mydataset.orders
  WHERE order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
  GROUP BY customer_id
),
customer_features AS (
  SELECT 
    ca.*,
    c.registration_date,
    c.age,
    c.gender,
    c.city,
    c.customer_segment,
    -- 파생 피처
    SAFE_DIVIDE(ca.total_spent, ca.customer_lifetime_days) as daily_spend_rate,
    SAFE_DIVIDE(ca.recent_orders, ca.previous_orders) as order_trend_ratio,
    -- 이탈 위험 라벨 (90일 이상 비활성)
    CASE WHEN ca.days_since_last_order >= 90 THEN 1 ELSE 0 END as churn_label
  FROM customer_activity ca
  JOIN mydataset.customers c ON ca.customer_id = c.customer_id
)
SELECT 
  customer_id,
  -- 정규화된 수치 피처
  (total_orders - AVG(total_orders) OVER()) / STDDEV(total_orders) OVER() as total_orders_norm,
  (total_spent - AVG(total_spent) OVER()) / STDDEV(total_spent) OVER() as total_spent_norm,
  (avg_order_value - AVG(avg_order_value) OVER()) / STDDEV(avg_order_value) OVER() as avg_order_norm,
  -- 카테고리 피처
  age,
  gender,
  city,
  customer_segment,
  -- 원시 피처
  days_since_last_order,
  category_diversity,
  order_trend_ratio,
  daily_spend_rate,
  churn_label
FROM customer_features
WHERE customer_lifetime_days >= 30; -- 충분한 활동 이력이 있는 고객만
```

---

## 8. CTAS vs 기타 방법들

### 8.1 CTAS vs INSERT SELECT

```sql
-- ❌ 기존 방식: 별도 테이블 생성 후 삽입
CREATE TABLE mydataset.customer_summary (
  customer_id INT64,
  total_orders INT64,
  total_spent FLOAT64,
  last_order_date DATE
);

INSERT INTO mydataset.customer_summary
SELECT 
  customer_id,
  COUNT(*) as total_orders,
  SUM(order_amount) as total_spent,
  MAX(order_date) as last_order_date
FROM mydataset.orders
GROUP BY customer_id;

-- ✅ CTAS 방식: 한 번에 처리
CREATE OR REPLACE TABLE mydataset.customer_summary AS
SELECT 
  customer_id,
  COUNT(*) as total_orders,
  SUM(order_amount) as total_spent,
  MAX(order_date) as last_order_date
FROM mydataset.orders
GROUP BY customer_id;
```

### 8.2 CTAS vs 뷰 (View)

```sql
-- 뷰: 실시간 계산 (매번 쿼리 실행)
CREATE VIEW mydataset.sales_summary_view AS
SELECT 
  product_category,
  DATE_TRUNC(order_date, MONTH) as month,
  SUM(order_amount) as monthly_revenue
FROM mydataset.orders
GROUP BY product_category, DATE_TRUNC(order_date, MONTH);

-- CTAS: 물리적 테이블 (스냅샷)
CREATE OR REPLACE TABLE mydataset.sales_summary_table AS
SELECT 
  product_category,
  DATE_TRUNC(order_date, MONTH) as month,
  SUM(order_amount) as monthly_revenue
FROM mydataset.orders
GROUP BY product_category, DATE_TRUNC(order_date, MONTH);
```

**사용 기준:**
- **뷰 사용**: 실시간 데이터 필요, 저장 공간 절약, 간단한 변환
- **CTAS 사용**: 복잡한 집계, 높은 성능 필요, 스냅샷 데이터

### 8.3 CTAS vs 머터리얼라이즈드 뷰

```sql
-- 머터리얼라이즈드 뷰: 자동 갱신
CREATE MATERIALIZED VIEW mydataset.product_sales_mv
PARTITION BY sale_date
AS
SELECT 
  product_id,
  DATE(order_timestamp) as sale_date,
  SUM(quantity) as total_quantity,
  SUM(order_amount) as total_revenue
FROM mydataset.orders
WHERE DATE(order_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY product_id, DATE(order_timestamp);

-- CTAS: 수동 갱신
CREATE OR REPLACE TABLE mydataset.product_sales_table
PARTITION BY sale_date
AS
SELECT 
  product_id,
  DATE(order_timestamp) as sale_date,
  SUM(quantity) as total_quantity,
  SUM(order_amount) as total_revenue
FROM mydataset.orders
WHERE DATE(order_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY product_id, DATE(order_timestamp);
```

---

## 9. 모범 사례와 주의점

### 9.1 명명 규칙과 구조화

```sql
-- ✅ 좋은 예: 명확한 네이밍과 구조
CREATE OR REPLACE TABLE analytics.dim_customers_enhanced
OPTIONS (
  description = "고객 차원 테이블 - 세그먼트와 RFM 점수 포함",
  labels = [("layer", "dimension"), ("source", "crm"), ("frequency", "daily")]
)
AS
SELECT 
  -- 기본 키
  customer_id,
  -- 기본 정보
  customer_name,
  email,
  phone,
  -- 주소 정보
  address,
  city,
  state,
  country,
  postal_code,
  -- 계산된 속성
  customer_segment,
  rfm_score,
  lifetime_value,
  -- 메타데이터
  created_date,
  last_updated_date,
  CURRENT_TIMESTAMP() as dbt_updated_at
FROM source_data.customers;

-- ❌ 나쁜 예: 모호한 네이밍
CREATE TABLE dataset1.table1 AS
SELECT * FROM dataset2.table2;
```

### 9.2 스키마 설계 모범 사례

```sql
-- ✅ 명시적 타입 캐스팅과 NULL 처리
CREATE OR REPLACE TABLE mydataset.clean_orders AS
SELECT 
  -- 필수 필드 검증
  CAST(order_id AS STRING) as order_id,
  CAST(customer_id AS STRING) as customer_id,
  
  -- NULL 값 처리
  COALESCE(product_name, 'Unknown Product') as product_name,
  COALESCE(quantity, 0) as quantity,
  COALESCE(unit_price, 0.0) as unit_price,
  
  -- 데이터 검증
  CASE 
    WHEN order_amount < 0 THEN 0
    WHEN order_amount IS NULL THEN 0
    ELSE order_amount 
  END as order_amount,
  
  -- 날짜 표준화
  PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', order_timestamp_str) as order_timestamp,
  
  -- 데이터 품질 플래그
  CASE 
    WHEN customer_id IS NULL OR order_amount IS NULL THEN FALSE
    ELSE TRUE 
  END as is_valid_record
FROM mydataset.raw_orders
WHERE order_id IS NOT NULL;
```

### 9.3 성능 최적화 체크리스트

```sql
-- ✅ 최적화된 CTAS 예시
CREATE OR REPLACE TABLE analytics.fact_sales_optimized
-- 쿼리 필터에 맞춰 파티셔닝
PARTITION BY sale_date  
-- 조인과 필터에 사용되는 컬럼으로 클러스터링
CLUSTER BY customer_id, product_category, store_id  
OPTIONS (
  description = "최적화된 매출 팩트 테이블",
  -- 90일 후 자동 삭제
  expiration_timestamp = TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
)
AS
SELECT 
  s.sale_id,
  s.customer_id,
  s.product_id,
  p.product_category,  -- 자주 사용되는 조인 결과 저장
  s.store_id,
  s.quantity,
  s.unit_price,
  s.total_amount,
  DATE(s.sale_timestamp) as sale_date,
  s.sale_timestamp
FROM mydataset.sales s
JOIN mydataset.products p ON s.product_id = p.product_id
WHERE DATE(s.sale_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY)
  AND s.total_amount > 0  -- 유효한 거래만
  AND s.customer_id IS NOT NULL;  -- 필수 필드 확인
```

### 9.4 주의사항과 제한사항

#### 9.4.1 스키마 진화 제한

```sql
-- ❌ 주의: CTAS는 기존 테이블 스키마를 완전히 대체
-- 컬럼 추가/제거 시 데이터 손실 가능성

-- ✅ 안전한 방법: 단계적 스키마 변경
-- 1단계: 새 컬럼 추가
ALTER TABLE mydataset.customers 
ADD COLUMN new_segment STRING;

-- 2단계: 데이터 업데이트  
UPDATE mydataset.customers 
SET new_segment = 'Premium'
WHERE total_spent > 10000;

-- 3단계: 필요시 CTAS로 정리
CREATE OR REPLACE TABLE mydataset.customers_v2 AS
SELECT * FROM mydataset.customers;
```

#### 9.4.2 비용 관리

```sql
-- ✅ 비용 효율적인 CTAS
CREATE OR REPLACE TABLE mydataset.monthly_summary
PARTITION BY summary_month
AS
SELECT 
  DATE_TRUNC(order_date, MONTH) as summary_month,
  COUNT(*) as order_count,
  SUM(order_amount) as total_revenue
FROM mydataset.orders
WHERE 
  -- 필요한 데이터만 스캔
  order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 24 MONTH)
  AND order_amount > 0
GROUP BY DATE_TRUNC(order_date, MONTH);

-- ❌ 비용 비효율: 전체 테이블 스캔
CREATE OR REPLACE TABLE mydataset.all_orders_copy AS
SELECT * FROM mydataset.orders;  -- 수 TB 데이터 전체 복사
```

#### 9.4.3 동시성 고려사항

```sql
-- ✅ 원자성이 중요한 경우
CREATE OR REPLACE TABLE mydataset.daily_report_20241201 AS
SELECT 
  DATE('2024-12-01') as report_date,
  product_category,
  SUM(order_amount) as daily_revenue
FROM mydataset.orders
WHERE DATE(order_timestamp) = '2024-12-01'
GROUP BY product_category;

-- ✅ 점진적 업데이트가 필요한 경우
-- 새 데이터만 추가하는 방식 고려
INSERT INTO mydataset.incremental_table
SELECT * FROM mydataset.new_data
WHERE load_date = CURRENT_DATE();
```

---

## 결론

BigQuery CTAS는 데이터 변환, 분석, 웨어하우징에서 핵심적인 역할을 하는 강력한 도구입니다. 

**핵심 포인트:**

- **효율성**: 테이블 생성과 데이터 로딩을 단일 작업으로 처리
- **유연성**: 복잡한 변환 로직과 집계를 동시에 수행
- **성능**: 파티셔닝과 클러스터링을 통한 최적화 가능
- **확장성**: 대용량 데이터 처리에 최적화된 구조

적절한 파티셔닝 전략, 클러스터링 설정, 그리고 비용 효율적인 쿼리 작성을 통해 CTAS의 진정한 가치를 실현할 수 있습니다.
