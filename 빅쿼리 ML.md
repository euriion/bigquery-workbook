# BigQuery ML 완벽 가이드

BigQuery ML을 활용한 머신러닝 모델 개발, 학습, 예측을 위한 종합 가이드입니다.

---

## 목차

1. [BigQuery ML 개요](#1-bigquery-ml-개요)
2. [지원하는 모델 유형](#2-지원하는-모델-유형)
3. [선형 회귀 모델](#3-선형-회귀-모델)
4. [로지스틱 회귀 모델](#4-로지스틱-회귀-모델)
5. [클러스터링 모델](#5-클러스터링-모델)
6. [시계열 예측 모델](#6-시계열-예측-모델)
7. [딥러닝 모델](#7-딥러닝-모델)
8. [모델 평가 및 해석](#8-모델-평가-및-해석)
9. [모델 배포 및 운영](#9-모델-배포-및-운영)
10. [실제 활용 사례](#10-실제-활용-사례)

---

## 1. BigQuery ML 개요

### 1.1 BigQuery ML이란?

**BigQuery ML**은 BigQuery 내에서 SQL을 사용하여 머신러닝 모델을 생성, 학습, 평가, 예측할 수 있는 서비스입니다.

### 1.2 주요 장점

- **SQL 기반**: 별도 ML 프레임워크 학습 불필요
- **확장성**: 대용량 데이터 처리 가능
- **통합성**: 데이터 파이프라인과 원활한 통합
- **비용 효율성**: 별도 인프라 구축 불필요

### 1.3 기본 워크플로우

```sql
-- 1. 모델 생성 및 학습
CREATE OR REPLACE MODEL `project.dataset.model_name`
OPTIONS(model_type='linear_reg') AS
SELECT feature1, feature2, label
FROM `project.dataset.training_data`;

-- 2. 모델 평가
SELECT * FROM ML.EVALUATE(MODEL `project.dataset.model_name`);

-- 3. 예측 실행
SELECT * FROM ML.PREDICT(MODEL `project.dataset.model_name`,
  SELECT feature1, feature2 FROM `project.dataset.new_data`);
```

---

## 2. 지원하는 모델 유형

### 2.1 지도 학습 모델

```sql
-- 선형 회귀 (Linear Regression)
CREATE MODEL `project.dataset.linear_model`
OPTIONS(model_type='linear_reg') AS
SELECT features, target FROM training_data;

-- 로지스틱 회귀 (Logistic Regression)  
CREATE MODEL `project.dataset.logistic_model`
OPTIONS(model_type='logistic_reg') AS
SELECT features, label FROM training_data;

-- 부스트 트리 (Boosted Tree)
CREATE MODEL `project.dataset.boosted_tree_model`
OPTIONS(model_type='boosted_tree_classifier') AS
SELECT features, label FROM training_data;

-- 랜덤 포레스트 (Random Forest)
CREATE MODEL `project.dataset.random_forest_model`
OPTIONS(
  model_type='random_forest_classifier',
  num_parallel_tree=100
) AS
SELECT features, label FROM training_data;

-- DNN (Deep Neural Network)
CREATE MODEL `project.dataset.dnn_model`
OPTIONS(
  model_type='dnn_classifier',
  hidden_units=[128, 64, 32]
) AS
SELECT features, label FROM training_data;
```

### 2.2 비지도 학습 모델

```sql
-- K-평균 클러스터링
CREATE MODEL `project.dataset.kmeans_model`
OPTIONS(
  model_type='kmeans',
  num_clusters=4
) AS
SELECT feature1, feature2, feature3 FROM training_data;

-- PCA (Principal Component Analysis)
CREATE MODEL `project.dataset.pca_model`
OPTIONS(
  model_type='pca',
  num_principal_components=3
) AS
SELECT feature1, feature2, feature3, feature4 FROM training_data;
```

### 2.3 시계열 예측 모델

```sql
-- ARIMA_PLUS 모델
CREATE MODEL `project.dataset.arima_model`
OPTIONS(
  model_type='arima_plus',
  time_series_timestamp_col='timestamp',
  time_series_data_col='sales'
) AS
SELECT timestamp, sales FROM time_series_data;
```

---

## 3. 선형 회귀 모델

### 3.1 기본 선형 회귀

```sql
-- 주택 가격 예측 모델
CREATE OR REPLACE MODEL `project.ml_models.house_price_model`
OPTIONS(
  model_type='linear_reg',
  input_label_cols=['price']
) AS
SELECT
  bedrooms,
  bathrooms,
  sqft_living,
  sqft_lot,
  floors,
  waterfront,
  view_rating,
  condition_rating,
  grade,
  yr_built,
  yr_renovated,
  zipcode,
  price  -- 타겟 변수
FROM `project.real_estate.house_data`
WHERE price IS NOT NULL
  AND price > 0;
```

### 3.2 고급 선형 회귀 설정

```sql
-- 정규화 및 고급 설정을 포함한 모델
CREATE OR REPLACE MODEL `project.ml_models.advanced_regression_model`
OPTIONS(
  model_type='linear_reg',
  input_label_cols=['revenue'],
  l1_reg=0.1,                    -- L1 정규화
  l2_reg=0.05,                   -- L2 정규화
  max_iterations=50,             -- 최대 반복 횟수
  learn_rate=0.01,              -- 학습률
  early_stop=true,              -- 조기 중단
  min_rel_progress=0.005,       -- 최소 상대 진전도
  data_split_method='seq',      -- 데이터 분할 방식
  data_split_eval_fraction=0.2  -- 검증 데이터 비율
) AS
SELECT
  marketing_spend,
  sales_team_size,
  product_launches,
  seasonality_index,
  competitor_count,
  economic_indicator,
  EXTRACT(MONTH FROM date) as month,
  EXTRACT(QUARTER FROM date) as quarter,
  revenue
FROM `project.sales.monthly_data`
WHERE date >= '2020-01-01';
```

### 3.3 범주형 변수 처리

```sql
-- 범주형 변수가 포함된 회귀 모델
CREATE OR REPLACE MODEL `project.ml_models.categorical_regression`
OPTIONS(
  model_type='linear_reg',
  input_label_cols=['salary']
) AS
SELECT
  -- 수치 변수
  years_experience,
  education_years,
  
  -- 범주형 변수 (자동 원-핫 인코딩)
  department,        -- 'Engineering', 'Sales', 'Marketing'
  job_level,        -- 'Junior', 'Mid', 'Senior', 'Lead'
  location,         -- 'NYC', 'SF', 'LA', 'Remote'
  
  -- 타겟 변수
  salary
FROM `project.hr.employee_data`
WHERE salary IS NOT NULL;
```

---

## 4. 로지스틱 회귀 모델

### 4.1 이진 분류

```sql
-- 고객 이탈 예측 모델 (Binary Classification)
CREATE OR REPLACE MODEL `project.ml_models.customer_churn_model`
OPTIONS(
  model_type='logistic_reg',
  input_label_cols=['churned'],
  auto_class_weights=true  -- 클래스 불균형 자동 조정
) AS
SELECT
  -- 고객 특성
  tenure_months,
  monthly_charges,
  total_charges,
  
  -- 서비스 사용 패턴
  phone_service,
  internet_service,
  online_security,
  tech_support,
  
  -- 계약 정보  
  contract_type,
  payment_method,
  paperless_billing,
  
  -- 타겟 (0: 유지, 1: 이탈)
  CASE WHEN churn_date IS NOT NULL THEN 1 ELSE 0 END as churned
  
FROM `project.customers.customer_data`
WHERE signup_date <= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);
```

### 4.2 다중 클래스 분류

```sql
-- 제품 카테고리 분류 모델 (Multi-class Classification)
CREATE OR REPLACE MODEL `project.ml_models.product_category_model`
OPTIONS(
  model_type='logistic_reg',
  input_label_cols=['category']
) AS
SELECT
  -- 제품 설명에서 추출한 특징들
  LENGTH(product_description) as description_length,
  (SELECT COUNT(*) FROM UNNEST(SPLIT(product_description, ' ')) as word) as word_count,
  
  -- 가격 관련 특징
  price,
  LOG(price + 1) as log_price,
  
  -- 브랜드 특성
  brand,
  
  -- 평점 정보
  avg_rating,
  review_count,
  
  -- 타겟 카테고리
  category  -- 'Electronics', 'Clothing', 'Home', 'Books', 'Sports'
  
FROM `project.products.product_catalog`
WHERE category IS NOT NULL;
```

### 4.3 클래스 가중치 설정

```sql
-- 불균형 데이터셋을 위한 가중치 설정
CREATE OR REPLACE MODEL `project.ml_models.fraud_detection_model`
OPTIONS(
  model_type='logistic_reg',
  input_label_cols=['is_fraud'],
  -- 수동 클래스 가중치 설정 (정상:사기 = 1:10)
  class_weights=[('0', 1), ('1', 10)]
) AS
SELECT
  transaction_amount,
  LOG(transaction_amount + 1) as log_amount,
  hour_of_day,
  day_of_week,
  merchant_category,
  payment_method,
  
  -- 사용자 행동 패턴
  transactions_last_hour,
  transactions_last_day,
  avg_transaction_amount,
  
  -- 지리적 정보
  merchant_state,
  user_home_state,
  CASE WHEN merchant_state = user_home_state THEN 1 ELSE 0 END as same_state,
  
  -- 타겟 (0: 정상, 1: 사기)
  is_fraud
  
FROM `project.payments.transaction_data`
WHERE transaction_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY);
```

---

## 5. 클러스터링 모델

### 5.1 K-평균 클러스터링

```sql
-- 고객 세그멘테이션을 위한 K-평균 클러스터링
CREATE OR REPLACE MODEL `project.ml_models.customer_segments`
OPTIONS(
  model_type='kmeans',
  num_clusters=5,
  standardize_features=true,  -- 특성 표준화
  kmeans_init_method='kmeans++'
) AS
SELECT
  -- RFM 특성
  recency_days,
  frequency_orders,
  monetary_total,
  
  -- 추가 고객 특성
  avg_order_value,
  tenure_months,
  
  -- 행동 패턴
  mobile_app_usage,
  email_open_rate,
  support_tickets,
  
  -- 선호도 점수
  discount_sensitivity,
  premium_product_ratio
  
FROM (
  SELECT 
    customer_id,
    DATE_DIFF(CURRENT_DATE(), MAX(order_date), DAY) as recency_days,
    COUNT(DISTINCT order_id) as frequency_orders,
    SUM(order_value) as monetary_total,
    AVG(order_value) as avg_order_value,
    DATE_DIFF(CURRENT_DATE(), MIN(signup_date), DAY) / 30 as tenure_months,
    SUM(mobile_orders) / COUNT(*) as mobile_app_usage,
    AVG(email_opens) as email_open_rate,
    COUNT(support_ticket_id) as support_tickets,
    AVG(discount_used) as discount_sensitivity,
    SUM(CASE WHEN product_tier = 'Premium' THEN 1 ELSE 0 END) / COUNT(*) as premium_product_ratio
  FROM `project.customers.customer_activity`
  GROUP BY customer_id
  HAVING COUNT(DISTINCT order_id) >= 3  -- 최소 3회 구매 고객만
);
```

### 5.2 클러스터 분석 및 해석

```sql
-- 클러스터별 특성 분석
WITH cluster_predictions AS (
  SELECT 
    customer_id,
    CENTROID_ID as cluster_id
  FROM ML.PREDICT(
    MODEL `project.ml_models.customer_segments`,
    (SELECT customer_id, recency_days, frequency_orders, monetary_total, 
            avg_order_value, tenure_months, mobile_app_usage, 
            email_open_rate, support_tickets, discount_sensitivity, 
            premium_product_ratio
     FROM customer_features)
  )
),
cluster_summary AS (
  SELECT 
    cp.cluster_id,
    COUNT(*) as customer_count,
    ROUND(AVG(cf.recency_days), 1) as avg_recency,
    ROUND(AVG(cf.frequency_orders), 1) as avg_frequency,
    ROUND(AVG(cf.monetary_total), 2) as avg_monetary,
    ROUND(AVG(cf.avg_order_value), 2) as avg_order_value,
    ROUND(AVG(cf.tenure_months), 1) as avg_tenure,
    ROUND(AVG(cf.mobile_app_usage) * 100, 1) as mobile_usage_pct,
    ROUND(AVG(cf.discount_sensitivity) * 100, 1) as discount_sensitivity_pct
  FROM cluster_predictions cp
  JOIN customer_features cf ON cp.customer_id = cf.customer_id
  GROUP BY cp.cluster_id
)
SELECT 
  cluster_id,
  customer_count,
  -- 클러스터 특성 기반 라벨링
  CASE cluster_id
    WHEN 1 THEN 'VIP Customers'
    WHEN 2 THEN 'Loyal Regulars' 
    WHEN 3 THEN 'Price Sensitive'
    WHEN 4 THEN 'New Customers'
    WHEN 5 THEN 'At Risk'
  END as cluster_label,
  avg_recency,
  avg_frequency,
  avg_monetary,
  avg_order_value,
  mobile_usage_pct
FROM cluster_summary
ORDER BY cluster_id;
```

---

## 6. 시계열 예측 모델

### 6.1 ARIMA_PLUS 모델

```sql
-- 매출 예측을 위한 ARIMA_PLUS 모델
CREATE OR REPLACE MODEL `project.ml_models.sales_forecast_model`
OPTIONS(
  model_type='arima_plus',
  time_series_timestamp_col='date',
  time_series_data_col='daily_sales',
  auto_arima=true,              -- 자동 ARIMA 파라미터 선택
  data_frequency='daily',       -- 데이터 주기
  decompose_time_series=true,   -- 시계열 분해
  holiday_region='US'           -- 휴일 효과 고려
) AS
SELECT
  date,
  SUM(sales_amount) as daily_sales
FROM `project.sales.daily_transactions`
WHERE date BETWEEN '2020-01-01' AND '2023-12-31'
  AND sales_amount > 0
GROUP BY date
ORDER BY date;
```

### 6.2 외부 변수를 포함한 시계열 모델

```sql
-- 외부 요인을 고려한 수요 예측 모델
CREATE OR REPLACE MODEL `project.ml_models.demand_forecast_with_regressors`
OPTIONS(
  model_type='arima_plus',
  time_series_timestamp_col='date',
  time_series_data_col='demand',
  time_series_id_col='product_id',  -- 제품별 개별 모델
  auto_arima=true,
  holiday_region='US'
) AS
SELECT
  product_id,
  date,
  demand,
  
  -- 외부 회귀 변수들
  marketing_spend,
  competitor_price_ratio,
  weather_temperature,
  economic_index,
  
  -- 시간 특성
  EXTRACT(MONTH FROM date) as month,
  EXTRACT(DAYOFWEEK FROM date) as day_of_week,
  
  -- 이벤트 변수
  CASE WHEN date IN (SELECT holiday_date FROM holidays) THEN 1 ELSE 0 END as is_holiday,
  CASE WHEN EXTRACT(DAYOFWEEK FROM date) IN (1, 7) THEN 1 ELSE 0 END as is_weekend
  
FROM `project.supply_chain.daily_demand`
WHERE date BETWEEN '2021-01-01' AND '2023-12-31'
ORDER BY product_id, date;
```

### 6.3 시계열 예측 실행

```sql
-- 향후 30일 예측
SELECT 
  product_id,
  forecast_timestamp as forecast_date,
  forecast_value as predicted_demand,
  prediction_interval_lower_bound as lower_bound,
  prediction_interval_upper_bound as upper_bound,
  standard_error
FROM ML.FORECAST(
  MODEL `project.ml_models.demand_forecast_with_regressors`,
  STRUCT(
    30 AS horizon,              -- 30일 예측
    0.95 AS confidence_level    -- 95% 신뢰구간
  )
)
ORDER BY product_id, forecast_date;
```

---

## 7. 딥러닝 모델

### 7.1 DNN 분류기

```sql
-- 이미지 메타데이터 기반 분류를 위한 DNN
CREATE OR REPLACE MODEL `project.ml_models.image_classification_dnn`
OPTIONS(
  model_type='dnn_classifier',
  input_label_cols=['category'],
  hidden_units=[512, 256, 128, 64],   -- 4개 은닉층
  dropout=0.3,                        -- 드롭아웃 비율
  batch_size=64,                      -- 배치 크기  
  max_iterations=100,                 -- 최대 에포크
  learn_rate=0.001,                   -- 학습률
  activation_fn='relu',               -- 활성화 함수
  optimizer='adam'                    -- 옵티마이저
) AS
SELECT
  -- 이미지 메타데이터 특성들
  image_width,
  image_height,
  image_channels,
  file_size_kb,
  
  -- 색상 히스토그램 특성
  red_mean, red_std,
  green_mean, green_std, 
  blue_mean, blue_std,
  
  -- 텍스처 특성
  contrast_score,
  brightness_score,
  saturation_score,
  
  -- 기하학적 특성
  aspect_ratio,
  edge_density,
  
  -- 라벨
  category
FROM `project.images.image_features`
WHERE category IS NOT NULL;
```

### 7.2 텍스트 분류를 위한 DNN

```sql
-- 리뷰 감정 분석을 위한 DNN
CREATE OR REPLACE MODEL `project.ml_models.sentiment_analysis_dnn`
OPTIONS(
  model_type='dnn_classifier',
  input_label_cols=['sentiment'],
  hidden_units=[256, 128, 64],
  dropout=0.4,
  l2_reg=0.01,
  max_iterations=50,
  early_stop=true
) AS
SELECT
  -- 텍스트 길이 특성
  LENGTH(review_text) as text_length,
  ARRAY_LENGTH(SPLIT(review_text, ' ')) as word_count,
  ARRAY_LENGTH(SPLIT(review_text, '.')) as sentence_count,
  
  -- 감정 어휘 점수 (사전 계산된 특성)
  positive_word_count,
  negative_word_count,
  neutral_word_count,
  
  -- 구두점 사용 패턴
  exclamation_count,
  question_count,
  
  -- 대소문자 사용 패턴
  uppercase_ratio,
  
  -- 평점 정보 (있는 경우)
  rating,
  
  -- 타겟 (positive, negative, neutral)
  sentiment
FROM `project.reviews.processed_reviews`
WHERE sentiment IS NOT NULL;
```

---

## 8. 모델 평가 및 해석

### 8.1 회귀 모델 평가

```sql
-- 선형 회귀 모델 평가
SELECT 
  mean_absolute_error,
  mean_squared_error,
  mean_squared_log_error,
  median_absolute_error,
  r2_score,
  explained_variance
FROM ML.EVALUATE(
  MODEL `project.ml_models.house_price_model`
);

-- 예측 vs 실제값 비교
WITH predictions AS (
  SELECT 
    actual.price as actual_price,
    predicted_price,
    ABS(actual.price - predicted_price) as absolute_error,
    ABS((actual.price - predicted_price) / actual.price * 100) as percentage_error
  FROM ML.PREDICT(
    MODEL `project.ml_models.house_price_model`,
    (SELECT * FROM `project.real_estate.test_data`)
  ) pred
  JOIN `project.real_estate.test_data` actual
  ON pred.house_id = actual.house_id
)
SELECT 
  ROUND(AVG(percentage_error), 2) as mean_percentage_error,
  ROUND(PERCENTILE_CONT(percentage_error, 0.5) OVER(), 2) as median_percentage_error,
  ROUND(MAX(percentage_error), 2) as max_percentage_error,
  COUNT(*) as total_predictions
FROM predictions;
```

### 8.2 분류 모델 평가

```sql
-- 분류 모델 종합 평가
SELECT *
FROM ML.EVALUATE(
  MODEL `project.ml_models.customer_churn_model`
);

-- 혼동 행렬 (Confusion Matrix)
SELECT 
  actual_label,
  predicted_label,
  COUNT(*) as count
FROM ML.PREDICT(
  MODEL `project.ml_models.customer_churn_model`,
  (SELECT * FROM `project.customers.test_data`)
)
GROUP BY actual_label, predicted_label
ORDER BY actual_label, predicted_label;

-- ROC 곡선 데이터
SELECT 
  threshold,
  recall,
  false_positive_rate,
  true_negatives,
  false_positives,
  true_positives,
  false_negatives,
  precision
FROM ML.ROC_CURVE(
  MODEL `project.ml_models.customer_churn_model`
);
```

### 8.3 특성 중요도 분석

```sql
-- 트리 기반 모델의 특성 중요도
SELECT 
  feature,
  importance_weight,
  importance_gain,
  importance_cover
FROM ML.FEATURE_IMPORTANCE(
  MODEL `project.ml_models.boosted_tree_model`
)
ORDER BY importance_weight DESC;

-- 선형 모델의 계수
SELECT 
  feature,
  weight,
  ABS(weight) as abs_weight
FROM ML.WEIGHTS(
  MODEL `project.ml_models.linear_model`
)
ORDER BY abs_weight DESC;
```

### 8.4 모델 해석

```sql
-- EXPLAIN_PREDICT를 사용한 개별 예측 설명
SELECT 
  customer_id,
  predicted_churn_prob,
  -- 상위 기여 특성들
  (SELECT feature FROM UNNEST(top_feature_attributions) ORDER BY attribution DESC LIMIT 1) as top_feature,
  (SELECT attribution FROM UNNEST(top_feature_attributions) ORDER BY attribution DESC LIMIT 1) as top_attribution
FROM ML.EXPLAIN_PREDICT(
  MODEL `project.ml_models.customer_churn_model`,
  (SELECT * FROM `project.customers.high_risk_customers` LIMIT 10),
  STRUCT(3 as top_k_features)  -- 상위 3개 특성만
);
```

---

## 9. 모델 배포 및 운영

### 9.1 배치 예측

```sql
-- 대용량 배치 예측
CREATE OR REPLACE TABLE `project.predictions.daily_churn_predictions` AS
SELECT 
  customer_id,
  predicted_churned_probs[OFFSET(1)] as churn_probability,
  CASE 
    WHEN predicted_churned_probs[OFFSET(1)] > 0.7 THEN 'High Risk'
    WHEN predicted_churned_probs[OFFSET(1)] > 0.3 THEN 'Medium Risk' 
    ELSE 'Low Risk'
  END as risk_category,
  CURRENT_TIMESTAMP() as prediction_timestamp
FROM ML.PREDICT(
  MODEL `project.ml_models.customer_churn_model`,
  (SELECT * FROM `project.customers.active_customers`)
)
WHERE predicted_churned_probs[OFFSET(1)] > 0.1;  -- 최소 임계값 적용
```

### 9.2 실시간 예측 (스트리밍)

```sql
-- 실시간 사기 탐지 예측
CREATE OR REPLACE VIEW `project.realtime.fraud_alerts` AS
SELECT 
  transaction_id,
  customer_id,
  transaction_amount,
  predicted_is_fraud_probs[OFFSET(1)] as fraud_probability,
  CASE 
    WHEN predicted_is_fraud_probs[OFFSET(1)] > 0.9 THEN 'BLOCK'
    WHEN predicted_is_fraud_probs[OFFSET(1)] > 0.5 THEN 'REVIEW'
    ELSE 'APPROVE'
  END as recommendation,
  CURRENT_TIMESTAMP() as prediction_time
FROM ML.PREDICT(
  MODEL `project.ml_models.fraud_detection_model`,
  (SELECT * FROM `project.payments.streaming_transactions`)
)
WHERE predicted_is_fraud_probs[OFFSET(1)] > 0.3;
```

### 9.3 모델 성능 모니터링

```sql
-- 모델 성능 drift 감지
WITH recent_predictions AS (
  SELECT 
    DATE(prediction_timestamp) as prediction_date,
    AVG(churn_probability) as avg_churn_prob,
    STDDEV(churn_probability) as std_churn_prob,
    COUNT(*) as prediction_count
  FROM `project.predictions.daily_churn_predictions`
  WHERE prediction_timestamp >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  GROUP BY prediction_date
),
baseline_stats AS (
  SELECT 
    AVG(avg_churn_prob) as baseline_avg,
    AVG(std_churn_prob) as baseline_std
  FROM recent_predictions
  WHERE prediction_date <= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
)
SELECT 
  rp.prediction_date,
  rp.avg_churn_prob,
  bs.baseline_avg,
  ABS(rp.avg_churn_prob - bs.baseline_avg) as drift_magnitude,
  CASE 
    WHEN ABS(rp.avg_churn_prob - bs.baseline_avg) > 2 * bs.baseline_std THEN 'HIGH_DRIFT'
    WHEN ABS(rp.avg_churn_prob - bs.baseline_avg) > bs.baseline_std THEN 'MEDIUM_DRIFT'
    ELSE 'NORMAL'
  END as drift_status
FROM recent_predictions rp
CROSS JOIN baseline_stats bs
WHERE rp.prediction_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
ORDER BY rp.prediction_date DESC;
```

### 9.4 모델 재학습 자동화

```sql
-- 모델 재학습 조건 확인 및 실행
CREATE OR REPLACE PROCEDURE `project.ml_ops.retrain_churn_model`()
BEGIN
  DECLARE model_age_days INT64;
  DECLARE recent_accuracy FLOAT64;
  DECLARE retrain_needed BOOL DEFAULT FALSE;
  
  -- 모델 나이 확인
  SET model_age_days = (
    SELECT DATE_DIFF(CURRENT_DATE(), EXTRACT(DATE FROM creation_time), DAY)
    FROM `project.ml_models.INFORMATION_SCHEMA.MODELS`
    WHERE model_name = 'customer_churn_model'
  );
  
  -- 최근 정확도 확인
  SET recent_accuracy = (
    SELECT accuracy 
    FROM `project.ml_ops.model_performance_log`
    WHERE model_name = 'customer_churn_model'
      AND evaluation_date = CURRENT_DATE()
  );
  
  -- 재학습 조건 확인
  IF model_age_days > 30 OR recent_accuracy < 0.85 THEN
    SET retrain_needed = TRUE;
  END IF;
  
  -- 재학습 실행
  IF retrain_needed THEN
    -- 새로운 학습 데이터로 모델 재생성
    EXECUTE IMMEDIATE """
      CREATE OR REPLACE MODEL `project.ml_models.customer_churn_model`
      OPTIONS(
        model_type='logistic_reg',
        input_label_cols=['churned'],
        auto_class_weights=true
      ) AS
      SELECT * FROM `project.customers.updated_training_data`
      WHERE training_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY)
    """;
    
    -- 재학습 로그 기록
    INSERT INTO `project.ml_ops.retraining_log` (
      model_name,
      retrain_date,
      trigger_reason,
      previous_accuracy,
      model_age_days
    ) VALUES (
      'customer_churn_model',
      CURRENT_DATE(),
      CASE 
        WHEN model_age_days > 30 THEN 'MODEL_AGE'
        ELSE 'LOW_ACCURACY'
      END,
      recent_accuracy,
      model_age_days
    );
  END IF;
END;
```

---

## 10. 실제 활용 사례

### 10.1 추천 시스템

```sql
-- 협업 필터링 기반 상품 추천
CREATE OR REPLACE MODEL `project.ml_models.product_recommendation`
OPTIONS(
  model_type='matrix_factorization',
  user_col='customer_id',
  item_col='product_id', 
  rating_col='rating',
  l2_reg=0.01,
  num_factors=50
) AS
SELECT 
  customer_id,
  product_id,
  rating
FROM `project.ecommerce.customer_ratings`
WHERE rating IS NOT NULL;

-- 개인화된 상품 추천
SELECT 
  customer_id,
  product_id,
  predicted_rating,
  ROW_NUMBER() OVER (
    PARTITION BY customer_id 
    ORDER BY predicted_rating DESC
  ) as recommendation_rank
FROM ML.RECOMMEND(
  MODEL `project.ml_models.product_recommendation`
)
WHERE customer_id IN ('CUST001', 'CUST002', 'CUST003')
  AND predicted_rating >= 4.0
ORDER BY customer_id, recommendation_rank
LIMIT 30;  -- 각 고객에게 상위 10개 추천
```

### 10.2 수요 예측

```sql
-- 소매점 수요 예측 파이프라인
CREATE OR REPLACE MODEL `project.ml_models.retail_demand_forecast`
OPTIONS(
  model_type='arima_plus',
  time_series_timestamp_col='date',
  time_series_data_col='demand',
  time_series_id_col='store_product_id',
  auto_arima=true,
  holiday_region='US'
) AS
SELECT
  CONCAT(store_id, '_', product_id) as store_product_id,
  date,
  quantity_sold as demand,
  
  -- 외부 요인
  promotion_flag,
  competitor_promo_count,
  temperature,
  precipitation,
  local_events_count
FROM `project.retail.daily_sales`
WHERE date BETWEEN '2021-01-01' AND '2023-12-31'
  AND quantity_sold > 0;

-- 재고 최적화를 위한 예측
WITH demand_forecast AS (
  SELECT 
    SPLIT(forecast_id, '_')[OFFSET(0)] as store_id,
    SPLIT(forecast_id, '_')[OFFSET(1)] as product_id,
    forecast_timestamp,
    forecast_value as predicted_demand,
    prediction_interval_upper_bound as max_demand
  FROM ML.FORECAST(
    MODEL `project.ml_models.retail_demand_forecast`,
    STRUCT(7 AS horizon, 0.95 AS confidence_level)
  )
),
inventory_recommendations AS (
  SELECT 
    df.*,
    -- 안전재고 계산 (95% 신뢰구간 상한 + 버퍼)
    CEIL(df.max_demand * 1.1) as recommended_stock,
    
    -- 현재 재고와 비교
    COALESCE(inv.current_stock, 0) as current_stock,
    GREATEST(0, CEIL(df.max_demand * 1.1) - COALESCE(inv.current_stock, 0)) as reorder_quantity
    
  FROM demand_forecast df
  LEFT JOIN `project.retail.current_inventory` inv
    ON df.store_id = inv.store_id 
    AND df.product_id = inv.product_id
)
SELECT 
  store_id,
  product_id,
  predicted_demand,
  recommended_stock,
  current_stock,
  reorder_quantity,
  CASE 
    WHEN reorder_quantity > 0 THEN 'REORDER_NEEDED'
    WHEN current_stock > recommended_stock * 2 THEN 'OVERSTOCK'
    ELSE 'OPTIMAL'
  END as inventory_status
FROM inventory_recommendations
WHERE forecast_timestamp = DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY)
ORDER BY reorder_quantity DESC;
```

### 10.3 가격 최적화

```sql
-- 동적 가격 책정을 위한 수요 탄력성 모델
CREATE OR REPLACE MODEL `project.ml_models.price_elasticity_model`
OPTIONS(
  model_type='linear_reg',
  input_label_cols=['quantity_sold']
) AS
SELECT
  product_id,
  
  -- 가격 관련 변수
  price,
  LOG(price) as log_price,
  
  -- 경쟁사 가격 정보
  competitor_avg_price,
  price / competitor_avg_price as price_ratio,
  
  -- 시간 요인
  EXTRACT(MONTH FROM sale_date) as month,
  EXTRACT(DAYOFWEEK FROM sale_date) as day_of_week,
  
  -- 프로모션 효과
  discount_percent,
  promotion_type,
  
  -- 재고 수준
  inventory_level,
  
  -- 고객 특성
  customer_segment,
  
  -- 타겟 변수
  quantity_sold
  
FROM `project.sales.detailed_transactions`
WHERE sale_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 730 DAY);

-- 최적 가격 시뮬레이션
WITH price_scenarios AS (
  SELECT 
    product_id,
    current_price,
    scenario_price,
    scenario_price / current_price - 1 as price_change_pct
  FROM (
    SELECT 
      product_id,
      current_price,
      -- 가격 시나리오 생성 (-20% ~ +20%)
      GENERATE_ARRAY(current_price * 0.8, current_price * 1.2, current_price * 0.05) as price_scenarios
    FROM `project.products.current_prices`
  ),
  UNNEST(price_scenarios) as scenario_price
),
demand_predictions AS (
  SELECT 
    ps.product_id,
    ps.scenario_price,
    ps.price_change_pct,
    predicted_quantity_sold
  FROM price_scenarios ps
  JOIN ML.PREDICT(
    MODEL `project.ml_models.price_elasticity_model`,
    (SELECT 
       product_id,
       scenario_price as price,
       LOG(scenario_price) as log_price,
       competitor_avg_price,
       scenario_price / competitor_avg_price as price_ratio,
       EXTRACT(MONTH FROM CURRENT_DATE()) as month,
       EXTRACT(DAYOFWEEK FROM CURRENT_DATE()) as day_of_week,
       0 as discount_percent,
       'none' as promotion_type,
       100 as inventory_level,
       'regular' as customer_segment
     FROM price_scenarios)
  ) pred USING (product_id)
)
SELECT 
  product_id,
  scenario_price,
  price_change_pct,
  predicted_quantity_sold,
  -- 수익 계산 (비용은 별도 테이블에서 조인)
  scenario_price * predicted_quantity_sold as projected_revenue,
  -- 최적 가격 식별
  ROW_NUMBER() OVER (
    PARTITION BY product_id 
    ORDER BY scenario_price * predicted_quantity_sold DESC
  ) as revenue_rank
FROM demand_predictions
WHERE predicted_quantity_sold > 0
ORDER BY product_id, revenue_rank;
```

---

BigQuery ML을 활용하면 복잡한 ML 인프라 구축 없이도 강력한 머신러닝 모델을 개발하고 운영할 수 있습니다. SQL 기반의 간편한 인터페이스와 BigQuery의 확장성을 통해 대규모 데이터 과학 프로젝트를 효율적으로 수행할 수 있습니다.
