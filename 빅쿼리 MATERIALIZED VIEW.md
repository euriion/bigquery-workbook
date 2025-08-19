# BigQuery 머터리얼라이즈드 뷰 완벽 가이드

BigQuery에서 머터리얼라이즈드 뷰(Materialized View)를 활용한 성능 최적화와 효율적인 데이터 처리 방법을 다루는 종합 가이드입니다.

---

## 목차

1. [머터리얼라이즈드 뷰 개념과 정의](#1-머터리얼라이즈드-뷰-개념과-정의)
2. [일반 뷰와의 차이점](#2-일반-뷰와의-차이점)
3. [머터리얼라이즈드 뷰 생성과 관리](#3-머터리얼라이즈드-뷰-생성과-관리)
4. [새로고침 메커니즘](#4-새로고침-메커니즘)
5. [성능 최적화 전략](#5-성능-최적화-전략)
6. [비용 고려사항](#6-비용-고려사항)
7. [제약사항과 한계](#7-제약사항과-한계)
8. [실제 사용 사례](#8-실제-사용-사례)
9. [모범 사례와 주의점](#9-모범-사례와-주의점)

---

## 1. 머터리얼라이즈드 뷰 개념과 정의

### 1.1 머터리얼라이즈드 뷰란?

**머터리얼라이즈드 뷰(Materialized View)**는 쿼리 결과를 **물리적으로 저장**하는 뷰입니다.

- **기본 개념**: 쿼리 결과를 미리 계산하여 저장하는 가상 테이블
- **자동 새로고침**: 기본 테이블 변경 사항을 자동으로 반영
- **성능 향상**: 복잡한 집계 쿼리의 실행 시간 대폭 단축

### 1.2 머터리얼라이즈드 뷰의 장점

```sql
-- 복잡한 집계 쿼리 (매번 실행 시 시간 소요)
SELECT 
  DATE(order_date) as order_day,
  customer_region,
  COUNT(*) as order_count,
  SUM(total_amount) as total_sales,
  AVG(total_amount) as avg_order_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY)
GROUP BY 1, 2;

-- 머터리얼라이즈드 뷰 (결과가 미리 저장되어 빠른 조회)
CREATE MATERIALIZED VIEW sales_summary AS
SELECT 
  DATE(order_date) as order_day,
  customer_region,
  COUNT(*) as order_count,
  SUM(total_amount) as total_sales,
  AVG(total_amount) as avg_order_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY)
GROUP BY 1, 2;
```

### 1.3 주요 특징

| 특징 | 설명 |
|------|------|
| **물리적 저장** | 쿼리 결과를 실제 저장소에 보관 |
| **자동 새로고침** | 기본 테이블 변경 시 자동으로 업데이트 |
| **스마트 튜닝** | BigQuery가 자동으로 최적화 수행 |
| **클러스터링 지원** | 성능 향상을 위한 클러스터링 적용 가능 |

---

## 2. 일반 뷰와의 차이점

### 2.1 핵심 차이점 비교

| 구분 | 일반 뷰 (View) | 머터리얼라이즈드 뷰 (Materialized View) |
|------|-------------|--------------------------------|
| **저장 방식** | 쿼리만 저장 | 쿼리 결과 저장 |
| **실행 시점** | 조회할 때마다 실행 | 미리 계산된 결과 조회 |
| **성능** | 매번 기본 테이블 스캔 | 저장된 결과 직접 조회 |
| **저장 공간** | 사용 안 함 | 추가 저장 공간 필요 |
| **데이터 일관성** | 항상 최신 | 새로고침 주기에 따라 지연 |
| **비용** | 쿼리 실행 비용만 | 저장 비용 + 새로고침 비용 |

### 2.2 성능 비교 상세 분석

#### 2.2.1 실행 속도 비교

```sql
-- 일반 뷰: 매번 기본 테이블을 스캔하여 집계 수행
CREATE VIEW sales_analysis_view AS
SELECT 
  DATE(order_timestamp) as order_date,
  product_category,
  customer_segment,
  COUNT(*) as order_count,
  SUM(amount) as total_sales,
  AVG(amount) as avg_order_value,
  COUNT(DISTINCT customer_id) as unique_customers
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
WHERE order_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
GROUP BY 1, 2, 3;

-- 동일한 로직의 머터리얼라이즈드 뷰: 미리 계산된 결과 반환
CREATE MATERIALIZED VIEW sales_analysis_mv
PARTITION BY order_date
CLUSTER BY product_category, customer_segment
AS
SELECT 
  DATE(order_timestamp) as order_date,
  product_category,
  customer_segment,
  COUNT(*) as order_count,
  SUM(amount) as total_sales,
  AVG(amount) as avg_order_value,
  COUNT(DISTINCT customer_id) as unique_customers
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
WHERE order_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
GROUP BY 1, 2, 3;

-- 성능 비교 테스트
-- 일반 뷰 조회 (약 10-30초 소요)
SELECT product_category, SUM(total_sales) as category_sales
FROM sales_analysis_view
WHERE order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1;

-- 머터리얼라이즈드 뷰 조회 (약 1-3초 소요)
SELECT product_category, SUM(total_sales) as category_sales
FROM sales_analysis_mv
WHERE order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1;
```

#### 2.2.2 리소스 사용량 비교

| 메트릭 | 일반 뷰 | 머터리얼라이즈드 뷰 |
|--------|---------|-------------------|
| **쿼리 실행 시간** | 매번 10-30초 | 1-3초 |
| **스캔 데이터량** | 전체 기본 테이블 | 집계된 결과만 |
| **슬롯 사용량** | 높음 (매번 처리) | 낮음 (결과 조회만) |
| **메모리 사용량** | 높음 | 낮음 |

### 2.3 데이터 일관성과 실시간성

#### 2.3.1 데이터 신선도 비교

```sql
-- 일반 뷰: 항상 최신 데이터 반영
CREATE VIEW real_time_inventory AS
SELECT 
  product_id,
  SUM(quantity_in_stock) as current_stock,
  MIN(last_updated) as oldest_update,
  MAX(last_updated) as latest_update
FROM inventory_locations
GROUP BY 1;

-- 머터리얼라이즈드 뷰: 새로고침 주기에 따른 지연
CREATE MATERIALIZED VIEW inventory_summary AS
SELECT 
  product_id,
  SUM(quantity_in_stock) as current_stock,
  MIN(last_updated) as oldest_update,
  MAX(last_updated) as latest_update
FROM inventory_locations
GROUP BY 1;

-- 데이터 신선도 확인
SELECT 
  'View' as type,
  MAX(latest_update) as most_recent_data
FROM real_time_inventory
UNION ALL
SELECT 
  'Materialized View' as type,
  MAX(latest_update) as most_recent_data
FROM inventory_summary;
```

#### 2.3.2 새로고침 지연 모니터링

```sql
-- 머터리얼라이즈드 뷰 새로고침 상태 확인
SELECT 
  materialized_view_name,
  last_refresh_time,
  refresh_watermark,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), last_refresh_time, MINUTE) as minutes_behind
FROM `project.dataset.INFORMATION_SCHEMA.MATERIALIZED_VIEWS`
WHERE materialized_view_name = 'inventory_summary';
```

### 2.4 사용 시나리오별 선택 가이드

#### 2.4.1 일반 뷰를 선택해야 하는 경우

```sql
-- ✅ 일반 뷰 적합: 실시간 데이터 필요
CREATE VIEW live_order_status AS
SELECT 
  order_id,
  customer_id,
  order_status,
  last_updated,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), last_updated, MINUTE) as minutes_since_update
FROM orders
WHERE order_status IN ('PROCESSING', 'SHIPPING');

-- ✅ 일반 뷰 적합: 단순 필터링/변환
CREATE VIEW active_customers AS
SELECT 
  customer_id,
  customer_name,
  email,
  phone,
  CASE 
    WHEN last_order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) THEN 'Active'
    WHEN last_order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) THEN 'Dormant'
    ELSE 'Inactive'
  END as customer_status
FROM customers
WHERE is_deleted = FALSE;

-- ✅ 일반 뷰 적합: 자주 변경되는 로직
CREATE VIEW dynamic_pricing AS
SELECT 
  product_id,
  base_price,
  CASE 
    WHEN EXTRACT(HOUR FROM CURRENT_TIMESTAMP()) BETWEEN 9 AND 17 THEN base_price * 1.1
    WHEN EXTRACT(DAYOFWEEK FROM CURRENT_DATE()) IN (1, 7) THEN base_price * 0.9
    ELSE base_price
  END as current_price
FROM products;
```

#### 2.4.2 머터리얼라이즈드 뷰를 선택해야 하는 경우

```sql
-- ✅ 머터리얼라이즈드 뷰 적합: 복잡한 집계 분석
CREATE MATERIALIZED VIEW customer_lifetime_value
PARTITION BY DATE(first_order_date)
CLUSTER BY customer_segment
AS
SELECT 
  customer_id,
  customer_segment,
  DATE(MIN(order_timestamp)) as first_order_date,
  DATE(MAX(order_timestamp)) as last_order_date,
  COUNT(*) as total_orders,
  SUM(amount) as lifetime_value,
  AVG(amount) as avg_order_value,
  COUNT(DISTINCT DATE(order_timestamp)) as active_days,
  TIMESTAMP_DIFF(MAX(order_timestamp), MIN(order_timestamp), DAY) as customer_lifespan_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY 1, 2;

-- ✅ 머터리얼라이즈드 뷰 적합: 대시보드용 KPI
CREATE MATERIALIZED VIEW daily_business_kpis
PARTITION BY metric_date
AS
WITH daily_metrics AS (
  SELECT 
    DATE(order_timestamp) as metric_date,
    COUNT(*) as total_orders,
    SUM(amount) as total_revenue,
    COUNT(DISTINCT customer_id) as unique_customers,
    AVG(amount) as avg_order_value
  FROM orders
  GROUP BY 1
)
SELECT 
  metric_date,
  total_orders,
  total_revenue,
  unique_customers,
  avg_order_value,
  -- 이동평균 계산 (7일)
  AVG(total_revenue) OVER (
    ORDER BY metric_date 
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) as revenue_7day_avg,
  -- 성장률 계산
  SAFE_DIVIDE(
    total_revenue - LAG(total_revenue, 7) OVER (ORDER BY metric_date),
    LAG(total_revenue, 7) OVER (ORDER BY metric_date)
  ) as revenue_growth_7day
FROM daily_metrics;

-- ✅ 머터리얼라이즈드 뷰 적합: 머신러닝 피처
CREATE MATERIALIZED VIEW ml_customer_features
PARTITION BY DATE(feature_date)
CLUSTER BY customer_segment
AS
SELECT 
  CURRENT_DATE() as feature_date,
  customer_id,
  customer_segment,
  -- 거래 패턴 피처
  COUNT(*) as orders_last_90d,
  SUM(amount) as spend_last_90d,
  AVG(amount) as avg_order_value_90d,
  STDDEV(amount) as order_value_stddev,
  -- 시간 패턴 피처
  COUNT(DISTINCT EXTRACT(DAYOFWEEK FROM order_timestamp)) as active_days_of_week,
  AVG(EXTRACT(HOUR FROM order_timestamp)) as avg_order_hour,
  -- 카테고리 다양성 피처
  COUNT(DISTINCT product_category) as category_diversity,
  MAX(amount) as max_single_order,
  -- 최근성 피처
  DATE_DIFF(CURRENT_DATE(), MAX(DATE(order_timestamp)), DAY) as days_since_last_order
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE order_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
GROUP BY 2, 3;
```

### 2.5 비용 효율성 분석

#### 2.5.1 비용 구조 비교

```sql
-- 일반 뷰의 비용 분석
WITH view_costs AS (
  SELECT 
    'Regular View' as view_type,
    -- 매번 조회 시 전체 테이블 스캔 비용
    total_bytes_processed / POW(10, 12) * 5.0 as query_cost_usd,
    0 as storage_cost_usd,
    query_cost_usd as total_cost_per_query
  FROM `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
  WHERE query LIKE '%sales_analysis_view%'
    AND creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
),
mv_costs AS (
  SELECT 
    'Materialized View' as view_type,
    -- 조회 시 집계된 결과만 스캔
    total_bytes_processed / POW(10, 12) * 5.0 as query_cost_usd,
    -- 저장 비용 (월 기준)
    size_bytes / POW(10, 9) * 0.02 / 30 as daily_storage_cost_usd,
    query_cost_usd + daily_storage_cost_usd as total_cost_per_query
  FROM `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT j
  JOIN `project.dataset.INFORMATION_SCHEMA.TABLES` t 
    ON t.table_name = 'sales_analysis_mv'
  WHERE query LIKE '%sales_analysis_mv%'
    AND creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
)
SELECT * FROM view_costs
UNION ALL
SELECT * FROM mv_costs;
```

#### 2.5.2 ROI 분석

```sql
-- 머터리얼라이즈드 뷰 ROI 계산
WITH usage_stats AS (
  SELECT 
    materialized_view_name,
    -- 일일 쿼리 실행 횟수 (추정)
    50 as daily_queries,
    -- 일반 뷰 대비 시간 절약 (초)
    25 as time_saved_per_query_seconds,
    -- 개발자 시간당 비용 (USD)
    100 as developer_hourly_cost_usd
  FROM `project.dataset.INFORMATION_SCHEMA.MATERIALIZED_VIEWS`
  WHERE materialized_view_name = 'sales_analysis_mv'
)
SELECT 
  materialized_view_name,
  daily_queries,
  time_saved_per_query_seconds,
  -- 일일 시간 절약 효과
  daily_queries * time_saved_per_query_seconds / 3600 as daily_hours_saved,
  -- 일일 비용 절약 효과
  (daily_queries * time_saved_per_query_seconds / 3600) * developer_hourly_cost_usd as daily_cost_savings_usd,
  -- 월간 비용 절약 효과
  (daily_queries * time_saved_per_query_seconds / 3600) * developer_hourly_cost_usd * 30 as monthly_savings_usd
FROM usage_stats;
```

---

## 3. 머터리얼라이즈드 뷰 생성과 관리

### 3.1 기본 생성 문법

```sql
CREATE MATERIALIZED VIEW [IF NOT EXISTS] dataset_name.view_name
[PARTITION BY partition_expression]
[CLUSTER BY clustering_column_list]
[OPTIONS(materialized_view_option_list)]
AS query_statement;
```

### 3.2 실제 생성 예제

```sql
-- 기본 머터리얼라이즈드 뷰 생성
CREATE MATERIALIZED VIEW ecommerce.daily_sales AS
SELECT 
  DATE(order_timestamp) as order_date,
  product_category,
  COUNT(*) as order_count,
  SUM(amount) as total_sales,
  AVG(amount) as avg_order_value
FROM ecommerce.orders
GROUP BY 1, 2;

-- 파티션과 클러스터링이 적용된 머터리얼라이즈드 뷰
CREATE MATERIALIZED VIEW ecommerce.customer_analytics
PARTITION BY DATE(first_order_date)
CLUSTER BY customer_segment, region
AS
SELECT 
  customer_id,
  customer_segment,
  region,
  MIN(DATE(order_timestamp)) as first_order_date,
  MAX(DATE(order_timestamp)) as last_order_date,
  COUNT(*) as total_orders,
  SUM(amount) as lifetime_value,
  AVG(amount) as avg_order_value
FROM ecommerce.orders o
JOIN ecommerce.customers c ON o.customer_id = c.customer_id
GROUP BY 1, 2, 3;
```

### 3.3 머터리얼라이즈드 뷰 관리

```sql
-- 머터리얼라이즈드 뷰 정보 확인
SELECT 
  table_name,
  table_type,
  creation_time,
  last_modified_time
FROM ecommerce.INFORMATION_SCHEMA.TABLES
WHERE table_type = 'MATERIALIZED VIEW';

-- 머터리얼라이즈드 뷰 새로고침 상태 확인
SELECT 
  materialized_view_name,
  last_refresh_time,
  refresh_watermark
FROM ecommerce.INFORMATION_SCHEMA.MATERIALIZED_VIEWS;

-- 머터리얼라이즈드 뷰 수동 새로고침
CALL BQ.REFRESH_MATERIALIZED_VIEW('ecommerce.daily_sales');

-- 머터리얼라이즈드 뷰 삭제
DROP MATERIALIZED VIEW ecommerce.daily_sales;
```

---

## 4. 새로고침 메커니즘

### 4.1 자동 새로고침 원리

BigQuery는 **스마트 새로고침** 메커니즘을 사용합니다:

- **변경 감지**: 기본 테이블의 변경 사항 자동 감지
- **증분 업데이트**: 변경된 부분만 선택적으로 업데이트
- **최적화된 스케줄링**: 시스템 부하를 고려한 새로고침 시점 결정

### 4.2 새로고침 주기와 지연

```sql
-- 새로고침 상태 모니터링
SELECT 
  materialized_view_name,
  last_refresh_time,
  refresh_watermark,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), last_refresh_time, MINUTE) as minutes_since_refresh
FROM `project.dataset.INFORMATION_SCHEMA.MATERIALIZED_VIEWS`
WHERE materialized_view_name = 'daily_sales';
```

### 4.3 새로고침 최적화

```sql
-- 파티션 기반 증분 새로고침 최적화
CREATE MATERIALIZED VIEW analytics.incremental_sales
PARTITION BY DATE(order_date)
AS
SELECT 
  DATE(order_timestamp) as order_date,
  product_id,
  SUM(quantity) as total_quantity,
  SUM(amount) as total_sales
FROM raw_data.orders
WHERE DATE(order_timestamp) >= DATE('2024-01-01')
GROUP BY 1, 2;
```

---

## 5. 성능 최적화 전략

### 5.1 쿼리 최적화

```sql
-- 최적화 전: 비효율적인 머터리얼라이즈드 뷰
CREATE MATERIALIZED VIEW slow_view AS
SELECT 
  *,  -- 모든 컬럼 선택 (비추천)
  CURRENT_TIMESTAMP() as created_at  -- 비결정적 함수 (오류 발생)
FROM large_table
WHERE complex_calculation(column1) > 0;  -- 복잡한 UDF 사용

-- 최적화 후: 효율적인 머터리얼라이즈드 뷰
CREATE MATERIALIZED VIEW optimized_view
PARTITION BY DATE(order_date)
CLUSTER BY customer_segment
AS
SELECT 
  order_id,
  customer_id,
  customer_segment,
  DATE(order_date) as order_date,
  SUM(amount) as total_amount,
  COUNT(*) as order_count
FROM orders
WHERE order_date >= '2024-01-01'
GROUP BY 1, 2, 3, 4;
```

### 5.2 파티션과 클러스터링 활용

```sql
-- 시계열 데이터 최적화
CREATE MATERIALIZED VIEW time_series_analytics
PARTITION BY DATE(event_date)
CLUSTER BY user_segment, event_type
AS
SELECT 
  DATE(event_timestamp) as event_date,
  user_segment,
  event_type,
  COUNT(*) as event_count,
  COUNT(DISTINCT user_id) as unique_users
FROM events
WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1, 2, 3;
```

### 5.3 성능 모니터링

```sql
-- 머터리얼라이즈드 뷰 성능 분석
SELECT 
  job_id,
  query,
  total_slot_ms,
  total_bytes_processed,
  creation_time
FROM `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE query LIKE '%materialized_view_name%'
ORDER BY creation_time DESC
LIMIT 10;
```

---

## 6. 비용 고려사항

### 6.1 비용 구성 요소

| 비용 항목 | 설명 | 최적화 방법 |
|----------|------|------------|
| **저장 비용** | 머터리얼라이즈드 뷰 데이터 저장 | 필요한 컬럼만 선택, 파티션 프루닝 |
| **새로고침 비용** | 자동 새로고침 쿼리 실행 | 증분 업데이트, 효율적인 쿼리 작성 |
| **쿼리 비용** | 머터리얼라이즈드 뷰 조회 | 클러스터링, 적절한 필터링 |

### 6.2 비용 최적화 전략

```sql
-- 비용 효율적인 머터리얼라이즈드 뷰 설계
CREATE MATERIALIZED VIEW cost_optimized_summary
PARTITION BY DATE(transaction_date)  -- 파티션 프루닝으로 스캔 데이터 감소
CLUSTER BY customer_segment        -- 클러스터링으로 쿼리 성능 향상
AS
SELECT 
  DATE(transaction_timestamp) as transaction_date,
  customer_segment,
  -- 필요한 컬럼만 선택 (저장 비용 절약)
  COUNT(*) as transaction_count,
  SUM(amount) as total_amount,
  AVG(amount) as avg_amount
FROM transactions
WHERE 
  -- 최근 데이터만 포함 (저장 비용 절약)
  DATE(transaction_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  -- 유효한 데이터만 포함 (처리 비용 절약)
  AND amount > 0
GROUP BY 1, 2;
```

### 6.3 비용 모니터링

```sql
-- 머터리얼라이즈드 뷰 비용 분석
WITH mv_costs AS (
  SELECT 
    table_name,
    -- 저장 비용 (GB 기준)
    ROUND(size_bytes / POW(10, 9), 2) as storage_gb,
    ROUND(size_bytes / POW(10, 9) * 0.02, 2) as monthly_storage_cost_usd,
    last_modified_time
  FROM `project.dataset.INFORMATION_SCHEMA.TABLES`
  WHERE table_type = 'MATERIALIZED VIEW'
)
SELECT *
FROM mv_costs
ORDER BY storage_gb DESC;
```

---

## 7. 제약사항과 한계

### 7.1 주요 제약사항

#### 7.1.1 지원되지 않는 기능

```sql
-- ❌ 지원되지 않는 기능들
CREATE MATERIALIZED VIEW invalid_mv AS
SELECT 
  *,
  CURRENT_TIMESTAMP() as created_at,    -- 비결정적 함수
  RAND() as random_value,              -- 비결정적 함수
  user_defined_function(column1)       -- 대부분의 UDF
FROM source_table
WINDOW w AS (PARTITION BY column1)     -- 윈도우 함수 일부 제한
ORDER BY column2;                      -- ORDER BY 절

-- ✅ 지원되는 올바른 형태
CREATE MATERIALIZED VIEW valid_mv AS
SELECT 
  order_id,
  customer_id,
  DATE(order_timestamp) as order_date,
  SUM(amount) as total_amount
FROM orders
GROUP BY 1, 2, 3;
```

#### 7.1.2 데이터 타입 제한

```sql
-- ❌ 지원되지 않는 데이터 타입
CREATE MATERIALIZED VIEW unsupported_types AS
SELECT 
  json_column,     -- JSON 타입 제한적 지원
  array_column,    -- ARRAY 타입 제한적 지원
  struct_column    -- STRUCT 타입 제한적 지원
FROM source_table;

-- ✅ 안정적으로 지원되는 데이터 타입
CREATE MATERIALIZED VIEW supported_types AS
SELECT 
  id,              -- INT64
  name,            -- STRING
  amount,          -- FLOAT64
  order_date,      -- DATE
  created_at       -- TIMESTAMP
FROM source_table;
```

### 7.2 성능 제한사항

```sql
-- 복잡한 조인의 성능 한계
CREATE MATERIALIZED VIEW complex_joins AS
SELECT 
  o.order_id,
  c.customer_name,
  p.product_name,
  s.store_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
JOIN stores s ON o.store_id = s.store_id  -- 다중 조인 시 성능 저하 가능
WHERE o.order_date >= '2024-01-01';
```

---

## 8. 실제 사용 사례

### 8.1 전자상거래 대시보드

```sql
-- 실시간 대시보드용 머터리얼라이즈드 뷰
CREATE MATERIALIZED VIEW ecommerce.dashboard_metrics
PARTITION BY DATE(date)
CLUSTER BY product_category
AS
SELECT 
  DATE(order_timestamp) as date,
  product_category,
  COUNT(*) as orders,
  SUM(amount) as revenue,
  COUNT(DISTINCT customer_id) as unique_customers,
  AVG(amount) as avg_order_value,
  SUM(quantity) as items_sold
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE DATE(order_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY)
GROUP BY 1, 2;

-- 대시보드 쿼리 (빠른 응답)
SELECT 
  product_category,
  SUM(revenue) as total_revenue,
  SUM(orders) as total_orders,
  AVG(avg_order_value) as avg_order_value
FROM ecommerce.dashboard_metrics
WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY 1
ORDER BY total_revenue DESC;
```

### 8.2 사용자 분석

```sql
-- 사용자 세그멘테이션 및 분석
CREATE MATERIALIZED VIEW analytics.user_segments
PARTITION BY DATE(analysis_date)
CLUSTER BY user_segment
AS
WITH user_behavior AS (
  SELECT 
    user_id,
    COUNT(*) as session_count,
    SUM(session_duration) as total_duration,
    COUNT(DISTINCT DATE(session_start)) as active_days,
    AVG(page_views) as avg_page_views
  FROM sessions
  WHERE DATE(session_start) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  GROUP BY 1
),
user_segments AS (
  SELECT 
    user_id,
    CASE 
      WHEN session_count >= 20 AND total_duration >= 3600 THEN 'High Value'
      WHEN session_count >= 10 AND total_duration >= 1800 THEN 'Medium Value'
      WHEN session_count >= 5 THEN 'Low Value'
      ELSE 'New User'
    END as user_segment,
    session_count,
    total_duration,
    active_days,
    avg_page_views
  FROM user_behavior
)
SELECT 
  CURRENT_DATE() as analysis_date,
  user_segment,
  COUNT(*) as user_count,
  AVG(session_count) as avg_sessions,
  AVG(total_duration) as avg_duration,
  AVG(active_days) as avg_active_days
FROM user_segments
GROUP BY 1, 2;
```

### 8.3 IoT 센서 데이터 집계

```sql
-- IoT 센서 데이터 실시간 모니터링
CREATE MATERIALIZED VIEW iot.sensor_hourly_summary
PARTITION BY DATE(hour)
CLUSTER BY sensor_type, location
AS
SELECT 
  DATETIME_TRUNC(reading_timestamp, HOUR) as hour,
  sensor_id,
  sensor_type,
  location,
  COUNT(*) as reading_count,
  AVG(value) as avg_value,
  MIN(value) as min_value,
  MAX(value) as max_value,
  STDDEV(value) as stddev_value
FROM iot.sensor_readings
WHERE reading_timestamp >= DATETIME_SUB(CURRENT_DATETIME(), INTERVAL 30 DAY)
GROUP BY 1, 2, 3, 4;

-- 이상 감지 쿼리
SELECT 
  sensor_id,
  location,
  hour,
  avg_value,
  CASE 
    WHEN avg_value > (SELECT AVG(avg_value) + 3 * STDDEV(avg_value) 
                      FROM iot.sensor_hourly_summary 
                      WHERE sensor_type = s.sensor_type) THEN 'HIGH_ALERT'
    WHEN avg_value < (SELECT AVG(avg_value) - 3 * STDDEV(avg_value) 
                      FROM iot.sensor_hourly_summary 
                      WHERE sensor_type = s.sensor_type) THEN 'LOW_ALERT'
    ELSE 'NORMAL'
  END as alert_status
FROM iot.sensor_hourly_summary s
WHERE DATE(hour) = CURRENT_DATE()
  AND alert_status != 'NORMAL'
ORDER BY hour DESC;
```

---

## 9. 모범 사례와 주의점

### 9.1 설계 모범 사례

#### 9.1.1 효율적인 집계 설계

```sql
-- ✅ 좋은 예: 계층적 집계
CREATE MATERIALIZED VIEW sales.monthly_summary AS
SELECT 
  EXTRACT(YEAR FROM order_date) as year,
  EXTRACT(MONTH FROM order_date) as month,
  product_category,
  customer_segment,
  COUNT(*) as order_count,
  SUM(amount) as total_sales,
  COUNT(DISTINCT customer_id) as unique_customers
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id
GROUP BY 1, 2, 3, 4;

-- 세부 분석은 월별 요약에서 추가 집계
SELECT 
  year,
  product_category,
  SUM(total_sales) as yearly_sales,
  AVG(order_count) as avg_monthly_orders
FROM sales.monthly_summary
GROUP BY 1, 2;
```

#### 9.1.2 파티션 전략

```sql
-- ✅ 올바른 파티션 설계
CREATE MATERIALIZED VIEW analytics.user_activity
PARTITION BY DATE(activity_date)  -- 쿼리 패턴에 맞는 파티션
CLUSTER BY user_segment, region   -- 자주 필터링되는 컬럼으로 클러스터링
AS
SELECT 
  DATE(activity_timestamp) as activity_date,
  user_id,
  user_segment,
  region,
  COUNT(*) as activity_count,
  SUM(session_duration) as total_duration
FROM user_activities
WHERE DATE(activity_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY)
GROUP BY 1, 2, 3, 4;
```

### 9.2 성능 최적화

```sql
-- 머터리얼라이즈드 뷰 체인 구성
-- 1단계: 기본 집계
CREATE MATERIALIZED VIEW base.daily_metrics AS
SELECT 
  DATE(timestamp) as date,
  user_id,
  product_id,
  SUM(amount) as daily_amount,
  COUNT(*) as daily_count
FROM transactions
GROUP BY 1, 2, 3;

-- 2단계: 상위 집계 (1단계 뷰 활용)
CREATE MATERIALIZED VIEW analytics.weekly_summary AS
SELECT 
  DATE_TRUNC(date, WEEK) as week,
  product_id,
  SUM(daily_amount) as weekly_amount,
  SUM(daily_count) as weekly_count,
  COUNT(DISTINCT user_id) as unique_users
FROM base.daily_metrics
GROUP BY 1, 2;
```

### 9.3 주의사항과 문제 해결

#### 9.3.1 일반적인 오류와 해결책

```sql
-- ❌ 문제: 새로고침 실패
-- 원인: 기본 테이블의 스키마 변경
-- 해결: 머터리얼라이즈드 뷰 재생성

-- 스키마 변경 감지 및 대응
SELECT 
  materialized_view_name,
  last_refresh_time,
  refresh_error_message
FROM dataset.INFORMATION_SCHEMA.MATERIALIZED_VIEWS
WHERE refresh_error_message IS NOT NULL;

-- 머터리얼라이즈드 뷰 재생성
DROP MATERIALIZED VIEW IF EXISTS problem_view;
CREATE MATERIALIZED VIEW problem_view AS
-- 새로운 스키마에 맞는 쿼리
SELECT ...;
```

#### 9.3.2 모니터링 및 알림

```sql
-- 머터리얼라이즈드 뷰 상태 모니터링
CREATE MATERIALIZED VIEW monitoring.mv_health_check AS
SELECT 
  CURRENT_TIMESTAMP() as check_time,
  materialized_view_name,
  last_refresh_time,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), last_refresh_time, HOUR) as hours_since_refresh,
  CASE 
    WHEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), last_refresh_time, HOUR) > 24 THEN 'STALE'
    WHEN refresh_error_message IS NOT NULL THEN 'ERROR'
    ELSE 'HEALTHY'
  END as status
FROM `project.dataset.INFORMATION_SCHEMA.MATERIALIZED_VIEWS`;
```

### 9.4 마이그레이션 가이드

```sql
-- 기존 뷰를 머터리얼라이즈드 뷰로 전환
-- 1단계: 기존 뷰 백업
CREATE VIEW sales_summary_backup AS
SELECT * FROM sales_summary;

-- 2단계: 기존 뷰 제거
DROP VIEW sales_summary;

-- 3단계: 머터리얼라이즈드 뷰 생성
CREATE MATERIALIZED VIEW sales_summary
PARTITION BY DATE(order_date)
CLUSTER BY product_category
AS
-- 기존 뷰와 동일한 쿼리 로직
SELECT 
  DATE(order_timestamp) as order_date,
  product_category,
  COUNT(*) as order_count,
  SUM(amount) as total_sales
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY 1, 2;

-- 4단계: 결과 검증
SELECT 
  COUNT(*) as mv_count 
FROM sales_summary;

SELECT 
  COUNT(*) as backup_count 
FROM sales_summary_backup;
```

---

## 결론

머터리얼라이즈드 뷰는 BigQuery에서 **복잡한 집계 쿼리의 성능을 대폭 향상**시킬 수 있는 강력한 도구입니다. 

### 핵심 포인트
- ✅ **복잡한 집계와 조인**이 필요한 경우 적극 활용
- ✅ **파티션과 클러스터링**을 통한 추가 최적화
- ✅ **비용과 성능의 균형** 고려한 설계
- ✅ **정기적인 모니터링**과 유지보수

머터리얼라이즈드 뷰를 올바르게 활용하면 **쿼리 성능 향상과 비용 최적화**를 동시에 달성할 수 있습니다.