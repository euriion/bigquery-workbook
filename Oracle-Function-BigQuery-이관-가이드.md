# Oracle Function BigQuery 이관 가이드

## 개요
Oracle Stored Function을 BigQuery User-Defined Function (UDF)로 이관할 때 고려해야 할 주요 사항들과 변환 방법을 설명합니다.

## Oracle Function vs BigQuery UDF 비교

| 구분 | Oracle Function | BigQuery UDF |
|------|----------------|---------------|
| 함수 타입 | PL/SQL Function | SQL UDF, JavaScript UDF |
| 반환값 | 단일 값 또는 커서 | 스칼라 값, 테이블, 구조체 |
| 상태 관리 | 세션별 변수 지원 | 상태 없는 함수만 지원 |
| 재귀 호출 | 지원 | 제한적 지원 |
| 예외 처리 | EXCEPTION 블록 | ERROR 함수 |

## 함수 타입별 이관 방법

### 1. 단순 계산 함수

#### Oracle 예제
```sql
CREATE OR REPLACE FUNCTION calculate_tax(
  p_amount IN NUMBER,
  p_rate IN NUMBER DEFAULT 0.1
) RETURN NUMBER IS
  v_result NUMBER;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RETURN 0;
  END IF;
  
  v_result := p_amount * p_rate;
  RETURN ROUND(v_result, 2);
EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;
END;
```

#### BigQuery SQL UDF 변환
```sql
CREATE OR REPLACE FUNCTION `project.dataset.calculate_tax`(
  amount FLOAT64,
  rate FLOAT64
) RETURNS FLOAT64
AS (
  CASE 
    WHEN amount IS NULL OR amount <= 0 THEN 0
    WHEN rate IS NULL THEN 0
    ELSE ROUND(amount * rate, 2)
  END
);
```

### 2. 복잡한 로직을 포함한 함수

#### Oracle 예제
```sql
CREATE OR REPLACE FUNCTION get_customer_grade(
  p_customer_id IN NUMBER
) RETURN VARCHAR2 IS
  v_total_amount NUMBER := 0;
  v_order_count NUMBER := 0;
  v_grade VARCHAR2(20);
BEGIN
  SELECT NVL(SUM(order_amount), 0), COUNT(*)
  INTO v_total_amount, v_order_count
  FROM orders 
  WHERE customer_id = p_customer_id
    AND order_date >= ADD_MONTHS(SYSDATE, -12);
  
  IF v_total_amount >= 10000 AND v_order_count >= 10 THEN
    v_grade := 'PLATINUM';
  ELSIF v_total_amount >= 5000 AND v_order_count >= 5 THEN
    v_grade := 'GOLD';
  ELSIF v_total_amount >= 1000 THEN
    v_grade := 'SILVER';
  ELSE
    v_grade := 'BRONZE';
  END IF;
  
  RETURN v_grade;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'BRONZE';
  WHEN OTHERS THEN
    RETURN 'ERROR';
END;
```

#### BigQuery JavaScript UDF 변환
```sql
CREATE OR REPLACE FUNCTION `project.dataset.get_customer_grade`(
  customer_id INT64
) RETURNS STRING
LANGUAGE js AS """
  // 복잡한 로직은 별도 프로시저로 분리하거나
  // 뷰를 통해 구현하는 것을 권장
  
  if (!customer_id) return 'BRONZE';
  
  // JavaScript로 구현하기보다는
  // SQL UDF + 서브쿼리 조합을 권장
  return 'CALCULATED_GRADE';
""";

-- 권장 방식: SQL UDF + 서브쿼리
CREATE OR REPLACE FUNCTION `project.dataset.get_customer_grade_v2`(
  customer_id INT64
) RETURNS STRING
AS (
  (
    SELECT 
      CASE 
        WHEN total_amount >= 10000 AND order_count >= 10 THEN 'PLATINUM'
        WHEN total_amount >= 5000 AND order_count >= 5 THEN 'GOLD'
        WHEN total_amount >= 1000 THEN 'SILVER'
        ELSE 'BRONZE'
      END
    FROM (
      SELECT 
        COALESCE(SUM(order_amount), 0) as total_amount,
        COUNT(*) as order_count
      FROM `project.dataset.orders`
      WHERE customer_id = customer_id
        AND order_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
    )
  )
);
```

### 3. Table Function (Pipelined Function)

#### Oracle 예제
```sql
CREATE TYPE t_number_array AS TABLE OF NUMBER;

CREATE OR REPLACE FUNCTION split_string(
  p_string IN VARCHAR2,
  p_delimiter IN VARCHAR2 DEFAULT ','
) RETURN t_number_array PIPELINED IS
  v_start NUMBER := 1;
  v_pos NUMBER;
BEGIN
  LOOP
    v_pos := INSTR(p_string, p_delimiter, v_start);
    
    IF v_pos = 0 THEN
      PIPE ROW(TO_NUMBER(SUBSTR(p_string, v_start)));
      EXIT;
    ELSE
      PIPE ROW(TO_NUMBER(SUBSTR(p_string, v_start, v_pos - v_start)));
      v_start := v_pos + 1;
    END IF;
  END LOOP;
  
  RETURN;
END;
```

#### BigQuery Table UDF 변환
```sql
CREATE OR REPLACE TABLE FUNCTION `project.dataset.split_string_to_numbers`(
  input_string STRING,
  delimiter STRING
) RETURNS TABLE<number_value INT64>
AS (
  SELECT 
    CAST(value AS INT64) as number_value
  FROM UNNEST(SPLIT(input_string, delimiter)) as value
  WHERE SAFE_CAST(value AS INT64) IS NOT NULL
);

-- 사용 예제
SELECT * FROM `project.dataset.split_string_to_numbers`('1,2,3,4,5', ',');
```

## 주요 변환 패턴

### 1. 변수 처리
```sql
-- Oracle
DECLARE
  v_variable NUMBER := 100;
BEGIN
  v_variable := v_variable * 2;
  RETURN v_variable;
END;

-- BigQuery SQL UDF (단순한 경우)
CREATE FUNCTION example() RETURNS INT64
AS (200);

-- BigQuery JavaScript UDF (복잡한 경우)
CREATE FUNCTION example() RETURNS INT64
LANGUAGE js AS """
  let variable = 100;
  variable = variable * 2;
  return variable;
""";
```

### 2. 조건문 처리
```sql
-- Oracle
IF condition1 THEN
  RETURN value1;
ELSIF condition2 THEN
  RETURN value2;
ELSE
  RETURN value3;
END IF;

-- BigQuery SQL UDF
CASE 
  WHEN condition1 THEN value1
  WHEN condition2 THEN value2
  ELSE value3
END
```

### 3. 루프 처리
```sql
-- Oracle
FOR i IN 1..10 LOOP
  -- 처리 로직
END LOOP;

-- BigQuery JavaScript UDF
for (let i = 1; i <= 10; i++) {
  // 처리 로직
}
```

## 데이터 타입 매핑

### 스칼라 타입
| Oracle | BigQuery | 주의사항 |
|--------|----------|----------|
| VARCHAR2/CHAR | STRING | 길이 제한 차이 |
| NUMBER | FLOAT64, INT64 | 정밀도 고려 |
| DATE | DATE, DATETIME | 기본 포맷 차이 |
| TIMESTAMP | TIMESTAMP | 타임존 처리 |
| CLOB | STRING | 크기 제한 확인 |
| BOOLEAN | BOOL | Oracle 12c 이상 |

### 복합 타입
```sql
-- Oracle Record Type
TYPE t_employee_rec IS RECORD (
  emp_id NUMBER,
  emp_name VARCHAR2(100),
  salary NUMBER
);

-- BigQuery STRUCT
CREATE FUNCTION get_employee() RETURNS STRUCT<
  emp_id INT64,
  emp_name STRING,
  salary FLOAT64
>
AS (
  STRUCT(1 as emp_id, 'John' as emp_name, 50000.0 as salary)
);
```

## 성능 고려사항

### 1. UDF 실행 비용
```sql
-- 비효율적: 로우별 함수 호출
SELECT 
  customer_id,
  get_customer_grade(customer_id) as grade
FROM customers;

-- 효율적: JOIN 또는 서브쿼리 활용
SELECT 
  c.customer_id,
  CASE 
    WHEN o.total_amount >= 10000 THEN 'PLATINUM'
    WHEN o.total_amount >= 5000 THEN 'GOLD'
    ELSE 'BRONZE'
  END as grade
FROM customers c
LEFT JOIN (
  SELECT 
    customer_id,
    SUM(order_amount) as total_amount
  FROM orders
  GROUP BY customer_id
) o ON c.customer_id = o.customer_id;
```

### 2. JavaScript UDF vs SQL UDF
```sql
-- JavaScript UDF (느림, 복잡한 로직용)
CREATE FUNCTION complex_calculation(input ARRAY<FLOAT64>)
RETURNS FLOAT64
LANGUAGE js AS """
  // 복잡한 수학적 계산
  return input.reduce((sum, val) => sum + Math.pow(val, 2), 0);
""";

-- SQL UDF (빠름, 단순 계산용)
CREATE FUNCTION simple_calculation(input ARRAY<FLOAT64>)
RETURNS FLOAT64
AS (
  (SELECT SUM(POW(value, 2)) FROM UNNEST(input) as value)
);
```

## 제한사항 및 대안

### 1. 지원되지 않는 기능
- **커서**: 테이블 함수나 배열로 대체
- **GOTO**: 구조적 프로그래밍으로 재작성
- **동적 SQL**: 사전 정의된 함수로 대체
- **세션 변수**: 함수 파라미터로 전달

### 2. 대안 방법
```sql
-- Oracle 커서 기반 함수
CURSOR emp_cursor IS SELECT * FROM employees;

-- BigQuery 대안: 배열 반환 함수
CREATE FUNCTION get_employees()
RETURNS ARRAY<STRUCT<emp_id INT64, emp_name STRING>>
AS (
  ARRAY(SELECT AS STRUCT emp_id, emp_name FROM employees)
);
```

### 3. 외부 라이브러리 연동
```sql
-- Oracle Java 함수
CREATE FUNCTION java_function(p_input VARCHAR2) RETURN VARCHAR2
AS LANGUAGE JAVA NAME 'MyClass.myMethod(java.lang.String) return java.lang.String';

-- BigQuery 대안: Cloud Functions 호출 또는 외부 연결
-- 복잡한 로직은 애플리케이션 레벨에서 처리
```

## 이관 절차

### 1. 함수 분류 및 우선순위
```sql
-- Oracle 함수 목록 조회
SELECT 
  object_name,
  object_type,
  status,
  created,
  last_ddl_time
FROM user_objects 
WHERE object_type = 'FUNCTION'
ORDER BY last_ddl_time DESC;

-- 의존성 분석
SELECT 
  name,
  type,
  referenced_name,
  referenced_type
FROM user_dependencies 
WHERE type = 'FUNCTION';
```

### 2. 변환 전략 수립
1. **단순 계산 함수**: SQL UDF로 직접 변환
2. **복잡한 비즈니스 로직**: JavaScript UDF 또는 프로시저로 분할
3. **Table Function**: Table UDF로 변환
4. **커서 기반 함수**: 뷰 또는 테이블 함수로 재설계

### 3. BigQuery 함수 생성 예제
```sql
-- 템플릿: SQL UDF
CREATE OR REPLACE FUNCTION `project.dataset.function_name`(
  param1 DATA_TYPE,
  param2 DATA_TYPE
) RETURNS RETURN_TYPE
AS (
  -- SQL 표현식
);

-- 템플릿: JavaScript UDF  
CREATE OR REPLACE FUNCTION `project.dataset.function_name`(
  param1 DATA_TYPE,
  param2 DATA_TYPE
) RETURNS RETURN_TYPE
LANGUAGE js AS """
  // JavaScript 코드
  return result;
""";

-- 템플릿: Table UDF
CREATE OR REPLACE TABLE FUNCTION `project.dataset.function_name`(
  param1 DATA_TYPE
) RETURNS TABLE<column1 DATA_TYPE, column2 DATA_TYPE>
AS (
  SELECT column1, column2 FROM table WHERE condition
);
```

## 테스트 및 검증

### 1. 단위 테스트
```sql
-- 함수 테스트 프로시저
CREATE OR REPLACE PROCEDURE `project.dataset.test_functions`()
BEGIN
  DECLARE test_result BOOL DEFAULT TRUE;
  
  -- 테스트 케이스 1
  IF `project.dataset.calculate_tax`(1000, 0.1) != 100.0 THEN
    SELECT 'Test 1 Failed: calculate_tax' as error;
    SET test_result = FALSE;
  END IF;
  
  -- 테스트 케이스 2  
  IF `project.dataset.get_customer_grade`(12345) IS NULL THEN
    SELECT 'Test 2 Failed: get_customer_grade' as error;
    SET test_result = FALSE;
  END IF;
  
  IF test_result THEN
    SELECT 'All tests passed' as result;
  END IF;
END;
```

### 2. 성능 비교
```sql
-- 함수 실행 성능 측정
WITH test_data AS (
  SELECT customer_id 
  FROM customers 
  LIMIT 1000
)
SELECT 
  COUNT(*) as processed_rows,
  COUNT(DISTINCT `project.dataset.get_customer_grade`(customer_id)) as unique_grades
FROM test_data;

-- 실행 통계 확인
SELECT 
  job_id,
  total_slot_ms,
  total_bytes_processed,
  creation_time,
  end_time,
  TIMESTAMP_DIFF(end_time, start_time, MILLISECOND) as execution_time_ms
FROM `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE statement_type = 'SELECT'
  AND creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
ORDER BY creation_time DESC;
```

## 모범 사례

### 1. 함수 설계 원칙
```sql
-- Good: 순수 함수 (부작용 없음)
CREATE FUNCTION calculate_discount(price FLOAT64, rate FLOAT64) 
RETURNS FLOAT64
AS (price * (1 - rate));

-- Avoid: 테이블 수정하는 함수
-- BigQuery UDF에서는 DML 지원 안함
```

### 2. 에러 처리
```sql
-- 방어적 프로그래밍
CREATE FUNCTION safe_divide(numerator FLOAT64, denominator FLOAT64)
RETURNS FLOAT64
AS (
  CASE 
    WHEN denominator = 0 THEN NULL
    WHEN denominator IS NULL THEN NULL
    WHEN numerator IS NULL THEN NULL
    ELSE numerator / denominator
  END
);
```

### 3. 문서화
```sql
-- 함수 주석 및 설명
CREATE OR REPLACE FUNCTION `project.dataset.calculate_business_days`(
  start_date DATE,
  end_date DATE
) RETURNS INT64
AS (
  -- 두 날짜 사이의 영업일 수를 계산
  -- 토요일, 일요일 제외
  -- 공휴일은 별도 테이블에서 관리 필요
  (
    SELECT COUNT(*)
    FROM UNNEST(GENERATE_DATE_ARRAY(start_date, end_date)) as date
    WHERE EXTRACT(DAYOFWEEK FROM date) BETWEEN 2 AND 6
  )
);
```

## 체크리스트

### 이관 전
- [ ] Oracle 함수 목록 및 의존성 분석 완료
- [ ] 함수별 복잡도 평가 및 변환 방법 결정
- [ ] 테스트 케이스 준비
- [ ] 성능 벤치마크 기준 설정

### 이관 중  
- [ ] 데이터 타입 매핑 적용
- [ ] 로직 변환 및 최적화
- [ ] 에러 처리 로직 추가
- [ ] 함수명 및 스키마 규칙 적용

### 이관 후
- [ ] 단위 테스트 실행 및 통과
- [ ] 성능 테스트 완료
- [ ] 문서화 업데이트
- [ ] 모니터링 설정

## 참고 자료
- [BigQuery User-Defined Functions](https://cloud.google.com/bigquery/docs/reference/standard-sql/user-defined-functions)
- [BigQuery JavaScript UDF](https://cloud.google.com/bigquery/docs/reference/standard-sql/user-defined-functions#javascript-udf-structure)
- [BigQuery Table Functions](https://cloud.google.com/bigquery/docs/reference/standard-sql/table-functions)