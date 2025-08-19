# Oracle 스토어드 프로시저 BigQuery 이관 가이드

## 개요
Oracle 스토어드 프로시저를 BigQuery로 이관할 때 고려해야 할 주요 사항들과 변환 방법을 설명합니다.

## 주요 차이점 및 주의사항

### 1. 구문 및 문법 차이
- **변수 선언**
  - Oracle: `DECLARE variable_name data_type;`
  - BigQuery: `DECLARE variable_name data_type DEFAULT value;`

- **조건문**
  - Oracle: `IF condition THEN ... END IF;`
  - BigQuery: `IF condition THEN ... END IF;`

- **반복문**
  - Oracle: `FOR ... LOOP ... END LOOP;`
  - BigQuery: `FOR record IN (SELECT ...) DO ... END FOR;`

### 2. 데이터 타입 변환
| Oracle 타입 | BigQuery 타입 | 주의사항 |
|-------------|---------------|----------|
| VARCHAR2 | STRING | 길이 제한 차이 |
| NUMBER | NUMERIC, INT64 | 정밀도 고려 필요 |
| DATE | DATE, DATETIME | 타임존 처리 차이 |
| CLOB/BLOB | STRING/BYTES | 크기 제한 확인 |
| ROWID | - | BigQuery에서 지원 안함 |

### 3. 함수 매핑

#### 문자열 함수
```sql
-- Oracle
SUBSTR(string, start, length)
-- BigQuery
SUBSTR(string, start, length)

-- Oracle  
LENGTH(string)
-- BigQuery
LENGTH(string)

-- Oracle
INSTR(string, substring)
-- BigQuery  
STRPOS(string, substring)
```

#### 날짜 함수
```sql
-- Oracle
SYSDATE
-- BigQuery
CURRENT_DATETIME()

-- Oracle
TO_DATE(string, format)
-- BigQuery
PARSE_DATETIME(format, string)

-- Oracle
ADD_MONTHS(date, months)
-- BigQuery
DATE_ADD(date, INTERVAL months MONTH)
```

### 4. 커서(Cursor) 처리
Oracle의 커서는 BigQuery에서 다음과 같이 변환:

```sql
-- Oracle 커서 예제
DECLARE
  CURSOR emp_cursor IS SELECT * FROM employees;
  emp_rec employees%ROWTYPE;
BEGIN
  FOR emp_rec IN emp_cursor LOOP
    -- 처리 로직
  END LOOP;
END;

-- BigQuery 변환
FOR emp_rec IN (
  SELECT * FROM employees
) DO
  -- 처리 로직
END FOR;
```

### 5. 예외 처리
```sql
-- Oracle
BEGIN
  -- 코드
EXCEPTION
  WHEN OTHERS THEN
    -- 예외 처리
END;

-- BigQuery
BEGIN
  -- 코드
EXCEPTION WHEN ERROR THEN
  -- 예외 처리
END;
```

### 6. 패키지 및 네임스페이스
- Oracle의 패키지 개념이 BigQuery에는 없음
- 프로시저명에 프리픽스를 사용하여 구분
- 스키마 레벨에서 구조화 고려

## 이관 절차

### 1. 사전 분석
```bash
# Oracle 스토어드 프로시저 목록 추출
SELECT object_name, object_type, status 
FROM user_objects 
WHERE object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE');

# 의존성 분석
SELECT name, type, referenced_name, referenced_type 
FROM user_dependencies 
WHERE type IN ('PROCEDURE', 'FUNCTION');
```

### 2. 변환 우선순위 결정
1. 단순 로직 프로시저 (조건문, 기본 함수만 사용)
2. 복잡한 비즈니스 로직 프로시저
3. 외부 의존성이 있는 프로시저

### 3. BigQuery 프로시저 생성
```sql
CREATE OR REPLACE PROCEDURE `project.dataset.procedure_name`(
  param1 STRING,
  param2 INT64
)
BEGIN
  DECLARE variable1 STRING DEFAULT '';
  
  -- 로직 구현
  
EXCEPTION WHEN ERROR THEN
  -- 에러 처리
END;
```

## 성능 최적화 고려사항

### 1. 데이터 스캔 최소화
```sql
-- 파티션 컬럼 활용
WHERE partition_date = CURRENT_DATE()

-- 클러스터링 컬럼 활용  
WHERE customer_id = input_customer_id
```

### 2. 배치 처리
```sql
-- 단건 처리 대신 배치 처리 활용
INSERT INTO target_table
SELECT * FROM source_table 
WHERE condition;
```

### 3. 임시 테이블 활용
```sql
-- 복잡한 조인이나 집계는 임시 테이블로 분할
CREATE TEMP TABLE temp_result AS
SELECT ...;
```

## 제한사항 및 대안

### 1. 지원되지 않는 기능들
- **PRAGMA**: BigQuery에서 지원 안함
- **GOTO**: 구조적 프로그래밍으로 재작성
- **동적 SQL**: `EXECUTE IMMEDIATE` 대신 스크립트 생성 고려

### 2. 대안 방법
```sql
-- Oracle 동적 SQL
EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || table_name || ' WHERE id = ' || p_id;

-- BigQuery 대안: 스크립트 생성 또는 사전 정의된 쿼리 사용
```

### 3. 외부 연동
- Oracle의 외부 프로시저 호출은 Cloud Functions나 외부 API로 대체

## 테스트 및 검증

### 1. 단위 테스트
```sql
-- 테스트 프로시저 작성
CREATE OR REPLACE PROCEDURE `project.dataset.test_procedure`()
BEGIN
  DECLARE test_result BOOL DEFAULT FALSE;
  
  CALL `project.dataset.target_procedure`('test_param');
  
  -- 결과 검증
  SET test_result = (SELECT COUNT(*) > 0 FROM result_table);
  
  ASSERT test_result = TRUE AS 'Test failed';
END;
```

### 2. 성능 테스트
```sql
-- 실행 시간 측정
SELECT 
  job_id,
  total_slot_ms,
  total_bytes_processed,
  creation_time,
  end_time
FROM `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE job_type = 'SCRIPT'
  AND creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR);
```

## 모니터링 및 운영

### 1. 로깅
```sql
-- 로그 테이블 생성
CREATE TABLE `project.dataset.procedure_logs` (
  log_time TIMESTAMP,
  procedure_name STRING,
  execution_id STRING,
  status STRING,
  error_message STRING,
  duration_seconds FLOAT64
);
```

### 2. 알림 설정
```yaml
# Cloud Monitoring 알림 정책
displayName: "BigQuery Procedure Error Alert"
conditions:
  - displayName: "Procedure execution failed"
    conditionThreshold:
      filter: 'resource.type="bigquery_project"'
      comparison: COMPARISON_GREATER_THAN
      thresholdValue: 0
```

## 체크리스트

### 이관 전
- [ ] Oracle 프로시저 의존성 분석 완료
- [ ] 데이터 타입 매핑 계획 수립
- [ ] 함수 변환 매핑 테이블 작성
- [ ] 테스트 계획 수립

### 이관 중
- [ ] 구문 변환 완료
- [ ] 변수 선언 방식 변경
- [ ] 예외 처리 로직 변환
- [ ] 성능 최적화 적용

### 이관 후
- [ ] 단위 테스트 실행
- [ ] 성능 테스트 완료
- [ ] 로깅 및 모니터링 설정
- [ ] 문서화 업데이트

## 참고 자료
- [BigQuery 스크립트 및 저장 프로시저 문서](https://cloud.google.com/bigquery/docs/reference/standard-sql/scripting)
- [BigQuery 함수 참조](https://cloud.google.com/bigquery/docs/reference/standard-sql/functions-and-operators)
- [Oracle to BigQuery 마이그레이션 가이드](https://cloud.google.com/architecture/oracle-to-bigquery-migration)