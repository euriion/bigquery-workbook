# BigQuery Materialized View 히스토리

## 초기 릴리스

### Beta 공개 (2020-04-08)

BigQuery의 Materialized View가 Beta로 공개되었습니다.

### General Availability (2021-02-25)

Materialized View가 정식 GA로 발표되었습니다.

## GA 이후 주요 업데이트 (최신순)

### 2025-06-30 (GA)

**Apache Iceberg 외부 테이블 지원**
- MV에서 Apache Iceberg 외부 테이블을 직접 참조 가능
- BigLake Iceberg 데이터를 BigQuery로 이동 없이 MV 생성 가능

### 2024-08-07 (Preview)

**Iceberg 테이블과 파티션 정렬 MV 지원**
- 시간 단위 파티션 정렬 지원 (YEAR/MONTH/DAY/HOUR 변환)

### 2024-04-04 (GA)

**비증분 MV 및 지연 허용 기능**

- `allow_non_incremental_definition`: 비증분(전체 재계산) MV 허용
  - OUTER JOIN, UNION, HAVING, 분석함수 등 더 넓은 SQL 패턴 지원
- `max_staleness`: 허용 가능한 결과 지연 시간 지정으로 비용/지연 제어

### 2024-02-29 (GA)

**크로스-클라우드 MV**

- Amazon S3 BigLake 테이블 위에 MV 및 MV Replica 생성 가능
- 데이터 이그레스 없이 로컬에서 조인/쿼리 가능 (Omni 교차 조인 지원)

### 2024-02-29 (Preview)

**논리 뷰 참조 지원**

- MV가 논리 뷰(Logical View)를 참조할 수 있음

### 2023-12-12 (Preview)

**MV Replica 소개**

- 크로스-클라우드 지원 (2024-02-29에 GA로 승격)

### 2023-04-05 (Preview)

**비증분 MV 최초 공개**

- `allow_non_incremental` 기능 도입
- OUTER JOIN/UNION/HAVING/분석함수 등 광범위 SQL 지원

## 현재 주요 기능

### 파티션/클러스터링 최적화

- 베이스 테이블과 동일한 파티션 키/단위 정렬 지원  
- 부분 무효화 및 증분 갱신 효율화

### 스마트 튜닝 (자동 쿼리 리라이트)

- 조건이 맞으면 원본 테이블 쿼리를 자동으로 MV로 리라이트

### 추천 기능 (Preview)

- Materialized View Recommender
- 지난 30일 쿼리 히스토리를 기반으로 MV 후보 제안

## 참고사항

구체적인 쿼리 패턴이나 대시보드 요구사항에 따른 MV 설계, 파티션/클러스터링/max_staleness 값 설정에 대한 상세 가이드가 필요한 경우 별도 문서를 참조하시기 바랍니다.

## 출처

Google Cloud 공식 문서 및 릴리스 노트 기반

