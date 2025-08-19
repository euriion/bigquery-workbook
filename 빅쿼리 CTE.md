# BigQuery CTE (Common Table Expression) 완벽 가이드

BigQuery에서 CTE(Common Table Expression)를 활용한 효율적인 쿼리 작성 방법을 다루는 종합 가이드입니다.

---

## 목차
1. [CTE 개념과 정의](#1-cte-개념과-정의)
2. [CTE 문법과 구조](#2-cte-문법과-구조)
3. [CTE 종류와 특징](#3-cte-종류와-특징)
4. [실제 사용 예제](#4-실제-사용-예제)
5. [CTE 최적화 전략](#5-cte-최적화-전략)
6. [고급 CTE 활용법](#6-고급-cte-활용법)
7. [실제 사용 사례](#7-실제-사용-사례)
8. [모범 사례와 주의점](#8-모범-사례와-주의점)

---

## 1. CTE 개념과 정의

### 1.1 CTE란?

**CTE(Common Table Expression)**는 쿼리 내에서 **임시로 정의되는 가상 테이블**입니다.

- **기본 개념**: WITH 절을 사용하여 정의하는 임시 결과 집합
- **범위**: 단일 쿼리 실행 범위 내에서만 유효
- **가독성**: 복잡한 쿼리를 단순하고 읽기 쉽게 분해

### 1.2 CTE의 장점

```sql
-- CTE 사용 전 (복잡한 서브쿼리)
SELECT 
  customer_id,
  total_amount,
  avg_amount
FROM (
  SELECT 
    customer_id,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
  FROM orders
  WHERE order_date >= '2024-01-01'
  GROUP BY customer_id
) subquery
WHERE total_amount > 1000;

-- CTE 사용 후 (명확하고 읽기 쉬운 구조)
WITH customer_summary AS (
  SELECT 
    customer_id,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
  FROM orders
  WHERE order_date >= '2024-01-01'
  GROUP BY customer_id
)
SELECT 
  customer_id,
  total_amount,
  avg_amount
FROM customer_summary
WHERE total_amount > 1000;
```

### 1.3 CTE vs 서브쿼리 vs 뷰

| 구분 | CTE | 서브쿼리 | 뷰 |
|------|-----|----------|-----|
| **범위** | 단일 쿼리 | 단일 쿼리 | 전역 |
| **재사용** | 같은 쿼리 내 | 불가능 | 모든 쿼리 |
| **가독성** | 높음 | 낮음 | 높음 |
| **성능** | 최적화됨 | 최적화됨 | 뷰 정의에 따라 |

---

## 2. CTE 문법과 구조

### 2.1 기본 문법

```sql
WITH cte_name AS (
  -- CTE 정의 쿼리
  SELECT column1, column2, ...
  FROM table_name
  WHERE conditions
)
-- 메인 쿼리
SELECT *
FROM cte_name
WHERE additional_conditions;
```

### 2.2 다중 CTE 문법

```sql
WITH 
  first_cte AS (
    SELECT customer_id, order_count
    FROM order_summary
    WHERE order_count > 5
  ),
  second_cte AS (
    SELECT customer_id, total_amount
    FROM payment_summary
    WHERE total_amount > 1000
  )
SELECT 
  f.customer_id,
  f.order_count,
  s.total_amount
FROM first_cte f
JOIN second_cte s
  ON f.customer_id = s.customer_id;
```

### 2.3 중첩 CTE

```sql
WITH 
  level1 AS (
    SELECT product_id, category_id, sales_amount
    FROM sales
    WHERE sale_date >= '2024-01-01'
  ),
  level2 AS (
    SELECT 
      category_id,
      COUNT(*) as product_count,
      SUM(sales_amount) as total_sales
    FROM level1
    GROUP BY category_id
  )
SELECT 
  category_id,
  product_count,
  total_sales,
  total_sales / product_count as avg_sales_per_product
FROM level2
ORDER BY total_sales DESC;
```

---

## 3. CTE 종류와 특징

### 3.1 단순 CTE (Simple CTE)

**용도**: 복잡한 쿼리를 논리적 단위로 분해

```sql
-- 월별 매출 요약 CTE
WITH monthly_sales AS (
  SELECT 
    EXTRACT(YEAR FROM order_date) as year,
    EXTRACT(MONTH FROM order_date) as month,
    SUM(amount) as total_amount,
    COUNT(*) as order_count
  FROM orders
  WHERE order_date >= '2024-01-01'
  GROUP BY year, month
)
SELECT 
  year,
  month,
  total_amount,
  order_count,
  total_amount / order_count as avg_order_value
FROM monthly_sales
ORDER BY year, month;
```

### 3.2 재귀 CTE (Recursive CTE)

**용도**: 계층 구조 데이터나 반복적인 연산 처리

```sql
-- 조직 계층 구조 조회
WITH RECURSIVE org_hierarchy AS (
  -- 앵커: 최상위 매니저
  SELECT 
    employee_id,
    employee_name,
    manager_id,
    1 as level,
    CAST(employee_name AS STRING) as path
  FROM employees
  WHERE manager_id IS NULL
  
  UNION ALL
  
  -- 재귀: 하위 직원들
  SELECT 
    e.employee_id,
    e.employee_name,
    e.manager_id,
    oh.level + 1,
    CONCAT(oh.path, ' -> ', e.employee_name)
  FROM employees e
  JOIN org_hierarchy oh
    ON e.manager_id = oh.employee_id
  WHERE oh.level < 10  -- 무한 루프 방지
)
SELECT 
  employee_id,
  employee_name,
  level,
  path
FROM org_hierarchy
ORDER BY level, employee_name;
```

### 3.3 창 함수와 결합된 CTE

```sql
-- 고객별 구매 패턴 분석
WITH customer_purchases AS (
  SELECT 
    customer_id,
    order_date,
    amount,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id 
      ORDER BY order_date
    ) as purchase_sequence,
    LAG(order_date) OVER (
      PARTITION BY customer_id 
      ORDER BY order_date
    ) as prev_order_date
  FROM orders
),
purchase_intervals AS (
  SELECT 
    customer_id,
    purchase_sequence,
    amount,
    DATE_DIFF(order_date, prev_order_date, DAY) as days_between_orders
  FROM customer_purchases
  WHERE prev_order_date IS NOT NULL
)
SELECT 
  customer_id,
  COUNT(*) as total_orders,
  AVG(amount) as avg_order_amount,
  AVG(days_between_orders) as avg_days_between_orders
FROM purchase_intervals
GROUP BY customer_id
HAVING COUNT(*) >= 3
ORDER BY avg_order_amount DESC;
```

---

## 4. 실제 사용 예제

### 4.1 데이터 정제 및 변환

```sql
-- 고객 데이터 정제 및 세그먼테이션
WITH cleaned_customers AS (
  -- 1단계: 데이터 정제
  SELECT 
    customer_id,
    TRIM(UPPER(customer_name)) as customer_name,
    REGEXP_REPLACE(phone, r'[^0-9]', '') as clean_phone,
    LOWER(email) as clean_email,
    registration_date
  FROM raw_customers
  WHERE customer_name IS NOT NULL
    AND email IS NOT NULL
    AND REGEXP_CONTAINS(email, r'^[^@]+@[^@]+\.[^@]+$')
),
customer_metrics AS (
  -- 2단계: 고객 지표 계산
  SELECT 
    c.customer_id,
    c.customer_name,
    c.clean_email,
    COUNT(o.order_id) as total_orders,
    COALESCE(SUM(o.amount), 0) as total_spent,
    MAX(o.order_date) as last_order_date,
    MIN(o.order_date) as first_order_date
  FROM cleaned_customers c
  LEFT JOIN orders o ON c.customer_id = o.customer_id
  GROUP BY c.customer_id, c.customer_name, c.clean_email
),
customer_segments AS (
  -- 3단계: 고객 세그먼테이션
  SELECT 
    *,
    CASE 
      WHEN total_spent >= 5000 AND total_orders >= 10 THEN 'VIP'
      WHEN total_spent >= 2000 AND total_orders >= 5 THEN 'Premium'
      WHEN total_spent >= 500 AND total_orders >= 2 THEN 'Regular'
      ELSE 'New'
    END as customer_segment,
    DATE_DIFF(CURRENT_DATE(), last_order_date, DAY) as days_since_last_order
  FROM customer_metrics
)
SELECT 
  customer_segment,
  COUNT(*) as customer_count,
  AVG(total_spent) as avg_spent,
  AVG(total_orders) as avg_orders,
  AVG(days_since_last_order) as avg_days_inactive
FROM customer_segments
GROUP BY customer_segment
ORDER BY avg_spent DESC;
```

### 4.2 시계열 데이터 분석

```sql
-- 월별 매출 성장률 분석
WITH monthly_sales AS (
  SELECT 
    DATE_TRUNC(order_date, MONTH) as month,
    SUM(amount) as monthly_revenue,
    COUNT(DISTINCT customer_id) as unique_customers,
    COUNT(*) as total_orders
  FROM orders
  WHERE order_date >= '2023-01-01'
  GROUP BY month
),
sales_with_previous AS (
  SELECT 
    month,
    monthly_revenue,
    unique_customers,
    total_orders,
    LAG(monthly_revenue) OVER (ORDER BY month) as prev_month_revenue,
    LAG(unique_customers) OVER (ORDER BY month) as prev_month_customers
  FROM monthly_sales
),
growth_analysis AS (
  SELECT 
    month,
    monthly_revenue,
    unique_customers,
    total_orders,
    CASE 
      WHEN prev_month_revenue > 0 THEN
        ROUND((monthly_revenue - prev_month_revenue) / prev_month_revenue * 100, 2)
      ELSE NULL
    END as revenue_growth_rate,
    CASE 
      WHEN prev_month_customers > 0 THEN
        ROUND((unique_customers - prev_month_customers) / prev_month_customers * 100, 2)
      ELSE NULL
    END as customer_growth_rate
  FROM sales_with_previous
)
SELECT 
  FORMAT_DATE('%Y-%m', month) as month,
  FORMAT('%,.0f', monthly_revenue) as revenue,
  FORMAT('%,d', unique_customers) as customers,
  FORMAT('%,d', total_orders) as orders,
  CONCAT(revenue_growth_rate, '%') as revenue_growth,
  CONCAT(customer_growth_rate, '%') as customer_growth
FROM growth_analysis
ORDER BY month;
```

### 4.3 복잡한 집계 및 순위 분석

```sql
-- 제품 카테고리별 성과 분석
WITH product_sales AS (
  SELECT 
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity) as total_quantity_sold,
    SUM(oi.quantity * oi.unit_price) as total_revenue,
    COUNT(DISTINCT oi.order_id) as order_count,
    AVG(oi.unit_price) as avg_price
  FROM products p
  JOIN order_items oi ON p.product_id = oi.product_id
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
  GROUP BY p.product_id, p.product_name, p.category
),
category_totals AS (
  SELECT 
    category,
    SUM(total_revenue) as category_revenue,
    SUM(total_quantity_sold) as category_quantity,
    COUNT(*) as products_in_category
  FROM product_sales
  GROUP BY category
),
product_rankings AS (
  SELECT 
    ps.*,
    ct.category_revenue,
    ROUND(ps.total_revenue / ct.category_revenue * 100, 2) as revenue_share_in_category,
    ROW_NUMBER() OVER (
      PARTITION BY ps.category 
      ORDER BY ps.total_revenue DESC
    ) as rank_in_category,
    ROW_NUMBER() OVER (ORDER BY ps.total_revenue DESC) as overall_rank
  FROM product_sales ps
  JOIN category_totals ct ON ps.category = ct.category
)
SELECT 
  category,
  product_name,
  FORMAT('%,.0f', total_revenue) as revenue,
  FORMAT('%,d', total_quantity_sold) as quantity_sold,
  CONCAT(revenue_share_in_category, '%') as category_share,
  rank_in_category,
  overall_rank
FROM product_rankings
WHERE rank_in_category <= 5  -- 각 카테고리별 상위 5개 제품
ORDER BY category, rank_in_category;
```

---

## 5. CTE 최적화 전략

### 5.1 CTE 구체화 (Materialization)

BigQuery는 CTE를 자동으로 최적화하지만, 명시적으로 구체화를 제어할 수 있습니다.

```sql
-- 큰 CTE를 여러 번 참조할 때 구체화 힌트 사용
WITH 
  large_dataset AS (
    SELECT /*+ MATERIALIZE */ 
      customer_id,
      product_id,
      quantity,
      price,
      order_date
    FROM large_orders_table
    WHERE order_date >= '2024-01-01'
      AND status = 'COMPLETED'
  ),
  customer_totals AS (
    SELECT 
      customer_id,
      SUM(quantity * price) as total_spent
    FROM large_dataset
    GROUP BY customer_id
  ),
  product_totals AS (
    SELECT 
      product_id,
      SUM(quantity) as total_sold
    FROM large_dataset
    GROUP BY product_id
  )
SELECT 
  ct.customer_id,
  ct.total_spent,
  COUNT(DISTINCT ld.product_id) as products_purchased
FROM customer_totals ct
JOIN large_dataset ld ON ct.customer_id = ld.customer_id
GROUP BY ct.customer_id, ct.total_spent
ORDER BY ct.total_spent DESC;
```

### 5.2 필터링 최적화

```sql
-- 비효율적: 후반부에서 필터링
WITH all_orders AS (
  SELECT 
    customer_id,
    order_date,
    amount,
    status
  FROM orders  -- 전체 데이터를 가져옴
),
filtered_orders AS (
  SELECT *
  FROM all_orders
  WHERE order_date >= '2024-01-01'  -- 나중에 필터링
    AND status = 'COMPLETED'
)
SELECT customer_id, SUM(amount)
FROM filtered_orders
GROUP BY customer_id;

-- 효율적: 초기에 필터링
WITH filtered_orders AS (
  SELECT 
    customer_id,
    order_date,
    amount
  FROM orders
  WHERE order_date >= '2024-01-01'  -- 먼저 필터링
    AND status = 'COMPLETED'
)
SELECT 
  customer_id, 
  SUM(amount) as total_amount
FROM filtered_orders
GROUP BY customer_id;
```

### 5.3 컬럼 선택 최적화

```sql
-- 비효율적: 불필요한 컬럼 포함
WITH customer_data AS (
  SELECT *  -- 모든 컬럼 선택
  FROM customers
  WHERE registration_date >= '2024-01-01'
)
SELECT 
  customer_id,
  customer_name
FROM customer_data;

-- 효율적: 필요한 컬럼만 선택
WITH customer_data AS (
  SELECT 
    customer_id,
    customer_name
  FROM customers
  WHERE registration_date >= '2024-01-01'
)
SELECT 
  customer_id,
  customer_name
FROM customer_data;
```

---

## 6. 고급 CTE 활용법

### 6.1 동적 날짜 범위 분석

```sql
-- 동적 기간별 매출 비교
WITH date_ranges AS (
  SELECT 
    'current_month' as period_type,
    DATE_TRUNC(CURRENT_DATE(), MONTH) as start_date,
    CURRENT_DATE() as end_date
  UNION ALL
  SELECT 
    'previous_month',
    DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH),
    DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 1 DAY)
  UNION ALL
  SELECT 
    'same_month_last_year',
    DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR), MONTH),
    DATE_SUB(DATE_TRUNC(DATE_ADD(DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY)
),
period_sales AS (
  SELECT 
    dr.period_type,
    COUNT(o.order_id) as order_count,
    SUM(o.amount) as total_revenue,
    COUNT(DISTINCT o.customer_id) as unique_customers
  FROM date_ranges dr
  LEFT JOIN orders o 
    ON o.order_date >= dr.start_date 
    AND o.order_date <= dr.end_date
  GROUP BY dr.period_type
),
sales_comparison AS (
  SELECT 
    period_type,
    order_count,
    total_revenue,
    unique_customers,
    LAG(total_revenue) OVER (ORDER BY 
      CASE period_type 
        WHEN 'same_month_last_year' THEN 1
        WHEN 'previous_month' THEN 2
        WHEN 'current_month' THEN 3
      END
    ) as prev_period_revenue
  FROM period_sales
)
SELECT 
  period_type,
  FORMAT('%,d', order_count) as orders,
  FORMAT('$%,.2f', total_revenue) as revenue,
  FORMAT('%,d', unique_customers) as customers,
  CASE 
    WHEN prev_period_revenue > 0 THEN
      FORMAT('%.1f%%', (total_revenue - prev_period_revenue) / prev_period_revenue * 100)
    ELSE 'N/A'
  END as growth_rate
FROM sales_comparison
ORDER BY 
  CASE period_type 
    WHEN 'same_month_last_year' THEN 1
    WHEN 'previous_month' THEN 2
    WHEN 'current_month' THEN 3
  END;
```

### 6.2 복잡한 데이터 피벗

```sql
-- 월별 카테고리 매출을 행으로 피벗
WITH monthly_category_sales AS (
  SELECT 
    FORMAT_DATE('%Y-%m', o.order_date) as month,
    p.category,
    SUM(oi.quantity * oi.unit_price) as revenue
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  JOIN products p ON oi.product_id = p.product_id
  WHERE o.order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
  GROUP BY month, p.category
),
pivoted_sales AS (
  SELECT 
    month,
    SUM(CASE WHEN category = 'Electronics' THEN revenue ELSE 0 END) as electronics,
    SUM(CASE WHEN category = 'Clothing' THEN revenue ELSE 0 END) as clothing,
    SUM(CASE WHEN category = 'Books' THEN revenue ELSE 0 END) as books,
    SUM(CASE WHEN category = 'Home' THEN revenue ELSE 0 END) as home,
    SUM(revenue) as total_revenue
  FROM monthly_category_sales
  GROUP BY month
)
SELECT 
  month,
  FORMAT('$%,.0f', electronics) as electronics,
  FORMAT('$%,.0f', clothing) as clothing,
  FORMAT('$%,.0f', books) as books,
  FORMAT('$%,.0f', home) as home,
  FORMAT('$%,.0f', total_revenue) as total,
  -- 각 카테고리의 비율 계산
  FORMAT('%.1f%%', electronics / total_revenue * 100) as electronics_pct,
  FORMAT('%.1f%%', clothing / total_revenue * 100) as clothing_pct
FROM pivoted_sales
ORDER BY month;
```

### 6.3 이동 평균 및 누적 계산

```sql
-- 매출 이동 평균 및 누적 분석
WITH daily_sales AS (
  SELECT 
    DATE(order_date) as sale_date,
    SUM(amount) as daily_revenue,
    COUNT(*) as daily_orders
  FROM orders
  WHERE order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  GROUP BY sale_date
),
sales_with_moving_avg AS (
  SELECT 
    sale_date,
    daily_revenue,
    daily_orders,
    -- 7일 이동 평균
    AVG(daily_revenue) OVER (
      ORDER BY sale_date 
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as revenue_7day_avg,
    -- 30일 이동 평균
    AVG(daily_revenue) OVER (
      ORDER BY sale_date 
      ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) as revenue_30day_avg,
    -- 누적 매출
    SUM(daily_revenue) OVER (
      ORDER BY sale_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as cumulative_revenue
  FROM daily_sales
),
trend_analysis AS (
  SELECT 
    *,
    -- 전일 대비 변화율
    CASE 
      WHEN LAG(daily_revenue) OVER (ORDER BY sale_date) > 0 THEN
        (daily_revenue - LAG(daily_revenue) OVER (ORDER BY sale_date)) / 
        LAG(daily_revenue) OVER (ORDER BY sale_date) * 100
      ELSE NULL
    END as daily_change_pct,
    -- 7일 평균 대비 현재 성과
    CASE 
      WHEN revenue_7day_avg > 0 THEN
        (daily_revenue - revenue_7day_avg) / revenue_7day_avg * 100
      ELSE NULL
    END as vs_7day_avg_pct
  FROM sales_with_moving_avg
)
SELECT 
  FORMAT_DATE('%Y-%m-%d', sale_date) as date,
  FORMAT('$%,.0f', daily_revenue) as revenue,
  FORMAT('%,d', daily_orders) as orders,
  FORMAT('$%,.0f', revenue_7day_avg) as avg_7d,
  FORMAT('$%,.0f', revenue_30day_avg) as avg_30d,
  FORMAT('%.1f%%', daily_change_pct) as daily_change,
  FORMAT('%.1f%%', vs_7day_avg_pct) as vs_7d_avg
FROM trend_analysis
WHERE sale_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
ORDER BY sale_date DESC;
```

---

## 7. 실제 사용 사례

### 7.1 고객 생애 가치 (CLV) 계산

```sql
-- 고객 생애 가치 분석
WITH customer_order_history AS (
  SELECT 
    customer_id,
    order_date,
    amount,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) as order_sequence
  FROM orders
  WHERE order_date >= '2023-01-01'
),
customer_metrics AS (
  SELECT 
    customer_id,
    MIN(order_date) as first_order_date,
    MAX(order_date) as last_order_date,
    COUNT(*) as total_orders,
    SUM(amount) as total_spent,
    AVG(amount) as avg_order_value,
    DATE_DIFF(MAX(order_date), MIN(order_date), DAY) as customer_lifespan_days
  FROM customer_order_history
  GROUP BY customer_id
  HAVING COUNT(*) >= 2  -- 최소 2번 이상 구매한 고객
),
purchase_frequency AS (
  SELECT 
    customer_id,
    total_orders,
    total_spent,
    avg_order_value,
    customer_lifespan_days,
    CASE 
      WHEN customer_lifespan_days > 0 THEN
        total_orders / (customer_lifespan_days / 365.0)
      ELSE total_orders
    END as annual_purchase_frequency
  FROM customer_metrics
),
clv_calculation AS (
  SELECT 
    customer_id,
    total_spent,
    avg_order_value,
    annual_purchase_frequency,
    -- 단순 CLV = 평균 주문액 × 연간 구매 빈도 × 예상 고객 수명(3년으로 가정)
    avg_order_value * annual_purchase_frequency * 3 as predicted_clv,
    CASE 
      WHEN avg_order_value * annual_purchase_frequency * 3 >= 5000 THEN 'High Value'
      WHEN avg_order_value * annual_purchase_frequency * 3 >= 2000 THEN 'Medium Value'
      ELSE 'Low Value'
    END as clv_segment
  FROM purchase_frequency
)
SELECT 
  clv_segment,
  COUNT(*) as customer_count,
  FORMAT('$%,.2f', AVG(total_spent)) as avg_historical_spend,
  FORMAT('$%,.2f', AVG(predicted_clv)) as avg_predicted_clv,
  FORMAT('$%,.2f', SUM(predicted_clv)) as total_predicted_value
FROM clv_calculation
GROUP BY clv_segment
ORDER BY AVG(predicted_clv) DESC;
```

### 7.2 재고 회전율 분석

```sql
-- 제품별 재고 회전율 및 재주문 추천
WITH inventory_movement AS (
  SELECT 
    product_id,
    DATE_TRUNC(movement_date, MONTH) as month,
    movement_type,  -- 'IN' for stock in, 'OUT' for sales
    quantity,
    unit_cost
  FROM inventory_transactions
  WHERE movement_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
),
monthly_inventory AS (
  SELECT 
    product_id,
    month,
    SUM(CASE WHEN movement_type = 'IN' THEN quantity ELSE 0 END) as stock_in,
    SUM(CASE WHEN movement_type = 'OUT' THEN quantity ELSE 0 END) as stock_out,
    AVG(CASE WHEN movement_type = 'IN' THEN unit_cost END) as avg_unit_cost
  FROM inventory_movement
  GROUP BY product_id, month
),
inventory_with_running_stock AS (
  SELECT 
    product_id,
    month,
    stock_in,
    stock_out,
    avg_unit_cost,
    SUM(stock_in - stock_out) OVER (
      PARTITION BY product_id 
      ORDER BY month 
      ROWS UNBOUNDED PRECEDING
    ) as running_stock_level
  FROM monthly_inventory
),
turnover_analysis AS (
  SELECT 
    i.product_id,
    p.product_name,
    p.category,
    AVG(i.running_stock_level) as avg_inventory_level,
    SUM(i.stock_out) as total_sold_12months,
    AVG(i.avg_unit_cost) as avg_cost,
    CASE 
      WHEN AVG(i.running_stock_level) > 0 THEN
        SUM(i.stock_out) / AVG(i.running_stock_level)
      ELSE 0
    END as inventory_turnover_ratio,
    CASE 
      WHEN SUM(i.stock_out) > 0 THEN
        AVG(i.running_stock_level) / (SUM(i.stock_out) / 12.0) * 30
      ELSE 999
    END as days_inventory_on_hand
  FROM inventory_with_running_stock i
  JOIN products p ON i.product_id = p.product_id
  GROUP BY i.product_id, p.product_name, p.category
),
reorder_recommendations AS (
  SELECT 
    *,
    total_sold_12months / 12.0 as avg_monthly_sales,
    CASE 
      WHEN inventory_turnover_ratio >= 12 THEN 'Fast Moving'
      WHEN inventory_turnover_ratio >= 6 THEN 'Medium Moving'
      WHEN inventory_turnover_ratio >= 2 THEN 'Slow Moving'
      ELSE 'Dead Stock'
    END as movement_category,
    CASE 
      WHEN days_inventory_on_hand <= 30 THEN 'Urgent Reorder'
      WHEN days_inventory_on_hand <= 60 THEN 'Reorder Soon'
      WHEN days_inventory_on_hand <= 90 THEN 'Monitor'
      ELSE 'Overstocked'
    END as reorder_status
  FROM turnover_analysis
)
SELECT 
  category,
  movement_category,
  reorder_status,
  COUNT(*) as product_count,
  FORMAT('%.1f', AVG(inventory_turnover_ratio)) as avg_turnover,
  FORMAT('%.0f', AVG(days_inventory_on_hand)) as avg_days_on_hand,
  FORMAT('$%,.0f', SUM(avg_inventory_level * avg_cost)) as inventory_value
FROM reorder_recommendations
GROUP BY category, movement_category, reorder_status
ORDER BY category, 
         CASE movement_category
           WHEN 'Fast Moving' THEN 1
           WHEN 'Medium Moving' THEN 2
           WHEN 'Slow Moving' THEN 3
           ELSE 4
         END;
```

---

## 8. 모범 사례와 주의점

### 8.1 CTE 명명 규칙

```sql
-- 좋은 예: 의미 있는 이름 사용
WITH 
  active_customers AS (
    SELECT customer_id FROM customers WHERE status = 'ACTIVE'
  ),
  recent_orders AS (
    SELECT * FROM orders WHERE order_date >= '2024-01-01'
  ),
  customer_order_summary AS (
    SELECT 
      ac.customer_id,
      COUNT(ro.order_id) as order_count
    FROM active_customers ac
    LEFT JOIN recent_orders ro ON ac.customer_id = ro.customer_id
    GROUP BY ac.customer_id
  )
SELECT * FROM customer_order_summary;

-- 나쁜 예: 의미 없는 이름
WITH 
  temp1 AS (SELECT customer_id FROM customers WHERE status = 'ACTIVE'),
  temp2 AS (SELECT * FROM orders WHERE order_date >= '2024-01-01'),
  temp3 AS (
    SELECT t1.customer_id, COUNT(t2.order_id) as cnt
    FROM temp1 t1
    LEFT JOIN temp2 t2 ON t1.customer_id = t2.customer_id
    GROUP BY t1.customer_id
  )
SELECT * FROM temp3;
```

### 8.2 성능 고려사항

```sql
-- 주의: 대용량 CTE의 중복 참조
WITH large_cte AS (
  SELECT 
    customer_id,
    product_id,
    quantity,
    price
  FROM huge_transaction_table  -- 매우 큰 테이블
  WHERE transaction_date >= '2024-01-01'
)
-- 이 CTE가 여러 번 참조되면 비효율적
SELECT 'Customer Analysis' as analysis_type, COUNT(*)
FROM large_cte
UNION ALL
SELECT 'Product Analysis', COUNT(DISTINCT product_id)
FROM large_cte
UNION ALL
SELECT 'Transaction Analysis', SUM(quantity * price)
FROM large_cte;

-- 개선: 한 번의 집계로 모든 정보 수집
WITH large_cte AS (
  SELECT 
    customer_id,
    product_id,
    quantity,
    price
  FROM huge_transaction_table
  WHERE transaction_date >= '2024-01-01'
),
aggregated_metrics AS (
  SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT customer_id) as unique_customers,
    COUNT(DISTINCT product_id) as unique_products,
    SUM(quantity * price) as total_revenue
  FROM large_cte
)
SELECT 
  'Total Records' as metric,
  CAST(total_records AS STRING) as value
FROM aggregated_metrics
UNION ALL
SELECT 'Unique Customers', CAST(unique_customers AS STRING)
FROM aggregated_metrics
UNION ALL
SELECT 'Unique Products', CAST(unique_products AS STRING)
FROM aggregated_metrics
UNION ALL
SELECT 'Total Revenue', FORMAT('$%,.2f', total_revenue)
FROM aggregated_metrics;
```

### 8.3 오류 방지 패턴

```sql
-- 안전한 나눗셈과 NULL 처리
WITH sales_analysis AS (
  SELECT 
    product_id,
    SUM(quantity) as total_quantity,
    SUM(revenue) as total_revenue,
    COUNT(*) as order_count
  FROM product_sales
  GROUP BY product_id
),
safe_calculations AS (
  SELECT 
    product_id,
    total_quantity,
    total_revenue,
    order_count,
    -- 안전한 나눗셈
    CASE 
      WHEN total_quantity > 0 THEN total_revenue / total_quantity
      ELSE 0
    END as revenue_per_unit,
    -- NULL 안전 처리
    COALESCE(total_revenue, 0) as safe_revenue,
    -- 조건부 집계
    CASE 
      WHEN order_count >= 10 THEN 'High Volume'
      WHEN order_count >= 5 THEN 'Medium Volume'
      ELSE 'Low Volume'
    END as volume_category
  FROM sales_analysis
)
SELECT 
  product_id,
  FORMAT('$%,.2f', safe_revenue) as revenue,
  FORMAT('%.2f', revenue_per_unit) as price_per_unit,
  volume_category
FROM safe_calculations
WHERE safe_revenue > 0  -- 유효한 데이터만 표시
ORDER BY safe_revenue DESC;
```

### 8.4 디버깅과 테스트

```sql
-- CTE 단계별 디버깅
WITH 
  step1_raw_data AS (
    SELECT 
      customer_id,
      order_date,
      amount,
      status
    FROM orders
    WHERE order_date >= '2024-01-01'
  ),
  step2_filtered AS (
    SELECT *
    FROM step1_raw_data
    WHERE status = 'COMPLETED'
      AND amount > 0
  ),
  step3_aggregated AS (
    SELECT 
      customer_id,
      COUNT(*) as order_count,
      SUM(amount) as total_amount,
      AVG(amount) as avg_amount
    FROM step2_filtered
    GROUP BY customer_id
  )
-- 디버깅: 각 단계별로 확인 가능
-- SELECT 'Step 1' as step, COUNT(*) as record_count FROM step1_raw_data
-- UNION ALL
-- SELECT 'Step 2', COUNT(*) FROM step2_filtered  
-- UNION ALL
-- SELECT 'Step 3', COUNT(*) FROM step3_aggregated;

-- 최종 결과
SELECT 
  customer_id,
  order_count,
  FORMAT('$%,.2f', total_amount) as total_spent,
  FORMAT('$%,.2f', avg_amount) as avg_order_value
FROM step3_aggregated
WHERE order_count >= 3
ORDER BY total_amount DESC;
```

---

## 결론

CTE는 BigQuery에서 **복잡한 쿼리를 구조화하고 가독성을 높이는** 강력한 도구입니다.

### 주요 장점
- **가독성 향상**: 복잡한 로직을 논리적 단위로 분해
- **재사용성**: 같은 쿼리 내에서 여러 번 참조 가능
- **유지보수**: 각 단계별로 독립적인 테스트와 수정 가능
- **성능**: BigQuery 옵티마이저가 자동으로 최적화

### 활용 권장사항
1. **복잡한 집계**나 **다단계 변환**이 필요한 경우 적극 활용
2. **의미 있는 이름**으로 각 CTE의 목적을 명확히 표현
3. **필터링과 집계를 초기 단계**에서 수행하여 성능 최적화
4. **단계별 디버깅**을 통해 로직 검증

CTE를 효과적으로 활용하면 **더 명확하고 유지보수가 쉬운** BigQuery 쿼리를 작성할 수 있습니다.