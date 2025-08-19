# BigQuery Dataform UI 완벽 가이드

## 목차
1. [개요](#개요)
2. [Google Cloud Console 액세스](#google-cloud-console-액세스)
3. [워크스페이스 관리](#워크스페이스-관리)
4. [저장소 생성 및 설정](#저장소-생성-및-설정)
5. [개발 워크스페이스](#개발-워크스페이스)
6. [코드 편집기 (Web IDE)](#코드-편집기-web-ide)
7. [워크플로우 실행 및 관리](#워크플로우-실행-및-관리)
8. [릴리스 관리](#릴리스-관리)
9. [모니터링 및 로그](#모니터링-및-로그)
10. [설정 및 구성](#설정-및-구성)
11. [권한 및 보안](#권한-및-보안)
12. [팁 및 단축키](#팁-및-단축키)

---

## 개요

Google Cloud DataForm은 완전 관리형 웹 기반 IDE를 제공하여 SQL 기반 데이터 변환 워크플로우를 쉽게 개발, 테스트, 배포할 수 있습니다.

### 주요 UI 구성 요소

```
Google Cloud Console
├── DataForm 서비스 메인 페이지
├── 저장소(Repositories) 관리
├── 개발 워크스페이스(Development Workspaces)  
├── 릴리스 설정(Release Configurations)
├── 워크플로우 실행(Workflow Executions)
└── 모니터링 및 로그
```

---

## Google Cloud Console 액세스

### 1. DataForm 서비스 접속

**단계별 접속 방법:**

1. **Google Cloud Console 접속**
   - 브라우저에서 `console.cloud.google.com` 접속
   - 프로젝트 선택

2. **DataForm 서비스 찾기**
   ```
   방법 1: 검색 사용
   - 상단 검색 바에 "Dataform" 입력
   - "Dataform" 서비스 선택
   
   방법 2: 네비게이션 메뉴
   - 왼쪽 메뉴 → Analytics → Dataform
   
   방법 3: 직접 URL
   - https://console.cloud.google.com/bigquery/dataform
   ```

3. **API 활성화 확인**
   ```bash
   # 필요한 API들이 활성화되어 있는지 확인
   - Dataform API
   - BigQuery API
   - Cloud Resource Manager API
   ```

### 2. 첫 접속 시 화면

**초기 설정 마법사:**
- 저장소 생성 옵션 제시
- Git 연동 설정 안내
- 샘플 프로젝트 제공

---

## 워크스페이스 관리

### 1. 워크스페이스 개요 화면

**메인 대시보드 구성:**

```
📊 워크스페이스 대시보드
├── 📁 저장소 목록 (Repositories)
│   ├── 저장소명, 브랜치, 마지막 업데이트
│   ├── 연결된 Git 저장소 정보
│   └── 액세스 권한 상태
│
├── 🚀 최근 워크플로우 실행 (Recent Executions)  
│   ├── 실행 시간, 상태, 지속 시간
│   ├── 성공/실패 통계
│   └── 빠른 액세스 링크
│
├── 📋 릴리스 구성 (Release Configurations)
│   ├── 프로덕션 릴리스 목록
│   ├── 스케줄링 정보
│   └── 자동화 설정 상태
│
└── 📈 사용량 및 비용 요약
    ├── 월간 쿼리 실행 통계
    ├── 예상 BigQuery 비용
    └── 리소스 사용량 차트
```

### 2. 저장소 목록 뷰

**저장소 카드 정보:**
- **저장소 이름**: 프로젝트 식별자
- **Git 연동 상태**: 연결된 Git 저장소 URL
- **기본 브랜치**: main/master 브랜치 표시
- **최근 커밋**: 마지막 변경사항 정보
- **액세스 레벨**: 읽기/쓰기 권한 표시

**사용 가능한 액션:**
```
저장소 카드 → 우클릭 메뉴
├── 🔍 개발 워크스페이스 열기
├── ⚙️ 저장소 설정 수정  
├── 📊 워크플로우 실행 기록
├── 🗂️ 릴리스 구성 관리
└── 🗑️ 저장소 삭제
```

---

## 저장소 생성 및 설정

### 1. 새 저장소 생성

**"저장소 만들기" 버튼 클릭 시:**

```
📋 저장소 생성 폼
├── 기본 정보
│   ├── 저장소 ID (필수, 소문자, 하이픈 가능)
│   ├── 표시 이름 (선택사항)
│   ├── 설명 (선택사항)
│   └── 리전 선택 (US, EU, ASIA 등)
│
├── Git 연동 설정 (선택사항)
│   ├── 🔗 GitHub 연동
│   │   ├── GitHub 저장소 URL
│   │   ├── 개인 액세스 토큰
│   │   └── 기본 브랜치 설정
│   │
│   ├── 🔗 Cloud Source Repositories 연동
│   │   ├── 프로젝트 선택
│   │   ├── 저장소 선택
│   │   └── 브랜치 설정
│   │
│   └── 🔗 GitLab 연동
│       ├── GitLab 인스턴스 URL
│       ├── 프로젝트 ID
│       └── 액세스 토큰
│
└── 고급 설정
    ├── 기본 데이터베이스 (BigQuery 프로젝트)
    ├── 기본 스키마
    ├── 기본 리전
    └── 서비스 계정 설정
```

### 2. Git 연동 설정 세부사항

**GitHub 연동 시:**
```yaml
필수 정보:
  - GitHub 저장소 URL: https://github.com/username/repo-name
  - Personal Access Token: ghp_xxxxxxxxxxxxxxxxxxxxx
  - 권한: repo, read:user, read:org

선택 설정:
  - 기본 브랜치: main (또는 master)
  - 웹훅 설정: 자동 동기화 활성화
  - 브랜치 보호: 프로덕션 브랜치 제한
```

**연동 후 표시되는 정보:**
- ✅ Git 연결 상태
- 📊 마지막 동기화 시간  
- 🔄 자동 동기화 설정
- 🌿 추적 중인 브랜치 목록

---

## 개발 워크스페이스

### 1. 워크스페이스 생성

**"개발 워크스페이스 만들기" 화면:**

```
🛠️ 워크스페이스 설정
├── 기본 정보
│   ├── 워크스페이스 ID
│   └── Git 브랜치 선택
│
├── 실행 환경
│   ├── BigQuery 프로젝트
│   ├── 기본 위치 (리전)
│   └── 서비스 계정
│
└── 개발자 설정
    ├── 기본 스키마 접두사
    ├── 테이블 만료 정책
    └── 쿼리 라벨 설정
```

**워크스페이스 생성 후:**
- 자동으로 Git 브랜치 생성 (선택한 경우)
- 개발 환경용 BigQuery 데이터셋 생성
- 격리된 개발 환경 제공

### 2. 워크스페이스 상태 관리

**상태 표시:**
```
워크스페이스 상태 아이콘
├── 🟢 활성 (Active) - 개발 중
├── 🟡 유휴 (Idle) - 비활성 상태  
├── 🔴 오류 (Error) - 동기화 실패
└── ⏸️ 일시정지 (Paused) - 리소스 절약
```

**관리 옵션:**
- 🔄 Git에서 최신 변경사항 가져오기
- 💾 변경사항을 Git에 푸시
- 🧹 워크스페이스 정리 (임시 테이블 삭제)
- 🗑️ 워크스페이스 삭제

---

## 코드 편집기 (Web IDE)

### 1. IDE 메인 인터페이스

**화면 레이아웃:**

```
🖥️ DataForm Web IDE
├── 왼쪽 사이드바 (Explorer)
│   ├── 📁 파일 탐색기
│   │   ├── definitions/ (SQL 정의 파일들)
│   │   ├── includes/ (JavaScript 함수들)  
│   │   ├── dataform.json (프로젝트 설정)
│   │   └── package.json (의존성)
│   │
│   ├── 🔍 검색 (Search)
│   │   ├── 텍스트 검색
│   │   ├── 파일명 검색
│   │   └── 정규식 지원
│   │
│   ├── 🌿 Git (Source Control)
│   │   ├── 변경사항 스테이징
│   │   ├── 커밋 메시지 작성
│   │   ├── 브랜치 관리
│   │   └── 변경 내역 비교
│   │
│   └── 🧩 의존성 그래프 (Dependencies)
│       ├── 테이블 간 관계 시각화
│       ├── 실행 순서 확인
│       └── 순환 의존성 감지
│
├── 메인 편집 영역 (Editor)
│   ├── 탭 기반 다중 파일 편집
│   ├── SQL 및 JavaScript 구문 강조
│   ├── 자동 완성 (IntelliSense)
│   ├── 오류 및 경고 표시
│   ├── 코드 폴딩 지원
│   └── 미니맵 표시
│
├── 하단 패널 (Bottom Panel)  
│   ├── 📊 컴파일 결과 (Compilation Results)
│   │   ├── 생성된 SQL 미리보기
│   │   ├── 의존성 트리
│   │   └── 컴파일 오류/경고
│   │
│   ├── ▶️ 실행 결과 (Execution Results)
│   │   ├── 쿼리 실행 로그
│   │   ├── 데이터 미리보기
│   │   ├── 실행 시간 및 비용
│   │   └── 오류 메시지
│   │
│   ├── 🧪 테스트 결과 (Test Results)
│   │   ├── 어서션 검증 결과  
│   │   ├── 데이터 품질 검사
│   │   └── 테스트 커버리지
│   │
│   └── 🔍 검색 결과 (Search Results)
│       ├── 매치된 파일 목록
│       ├── 코드 컨텍스트 표시
│       └── 바로가기 링크
│
└── 우측 사이드바 (선택사항)
    ├── 📋 개요 (Outline)
    │   ├── 함수 및 테이블 목록
    │   └── 빠른 네비게이션
    │
    └── 🏷️ 태그 및 라벨
        ├── 실행 태그 관리
        └── 메타데이터 편집
```

### 2. 파일 탐색기 상세 기능

**폴더 구조 표시:**
```
📁 프로젝트 루트
├── 📁 definitions/
│   ├── 📁 staging/     [스테이징 테이블들]
│   ├── 📁 marts/       [데이터 마트들] 
│   ├── 📁 assertions/  [데이터 검증]
│   └── 📄 *.sqlx       [개별 정의 파일들]
│
├── 📁 includes/
│   ├── 📄 *.js         [JavaScript 매크로]
│   └── 📄 constants.js [상수 정의]
│
├── 📄 dataform.json    [프로젝트 설정]
├── 📄 package.json     [Node.js 의존성]
└── 📄 .gitignore       [Git 제외 파일]
```

**파일 아이콘 의미:**
- 📄 `.sqlx`: SQL 정의 파일
- 📄 `.js`: JavaScript 매크로
- 📄 `.json`: 설정 파일
- ✅ 초록색: 최신 상태
- 🟡 노란색: 수정됨 (저장 안됨)
- 🔴 빨간색: 오류 있음
- 📊 그래프: 의존성 있음

### 3. 코드 편집 기능

**SQL 편집기 특화 기능:**

```sql
-- 1. 자동 완성 (Ctrl+Space)
config {
  type: "table",  -- ← 자동 완성 제안: table, view, incremental, assertion
  schema: "analytics"
}

-- 2. 구문 강조
SELECT 
  ${ref("source_table")}  -- ← DataForm 함수 강조
FROM table_name           -- ← SQL 키워드 강조
WHERE date >= '2024-01-01' -- ← 문자열 강조

-- 3. 오류 감지
SELECT *
FROM ${ref("nonexistent_table")}  -- ← 빨간 밑줄로 오류 표시
```

**JavaScript 편집기 기능:**
```javascript
// 자동 완성 및 타입 추론
function generateSalesSummary(startDate, endDate) {
  return `
    SELECT 
      DATE(order_date) as date,
      SUM(amount) as total_sales
    FROM ${ref("orders")}
    WHERE DATE(order_date) BETWEEN '${startDate}' AND '${endDate}'
    GROUP BY 1
  `;
}

module.exports = { generateSalesSummary }; // ← 내보내기 자동 완성
```

**키보드 단축키:**
```
편집 단축키:
- Ctrl+S: 파일 저장
- Ctrl+Z: 되돌리기  
- Ctrl+Y: 다시 실행
- Ctrl+F: 파일 내 검색
- Ctrl+H: 찾기 및 바꾸기
- Ctrl+G: 특정 라인으로 이동

DataForm 전용:
- Ctrl+Shift+C: 컴파일
- Ctrl+Shift+E: 실행
- Ctrl+Shift+T: 테스트
- F12: 정의로 이동 (ref 함수)
- Shift+F12: 참조 찾기
```

### 4. 의존성 그래프 뷰

**그래프 시각화:**
```
의존성 그래프 화면
├── 📊 노드 표현
│   ├── 🟦 파란색: 소스 테이블
│   ├── 🟩 초록색: 스테이징 테이블  
│   ├── 🟨 노란색: 마트 테이블
│   ├── 🟥 빨간색: 어서션
│   └── ⚪ 회색: 외부 테이블
│
├── 🔗 엣지 (연결선)
│   ├── 실선: 직접 의존성
│   ├── 점선: 조건부 의존성
│   └── 화살표: 의존성 방향
│
├── 🎛️ 제어판
│   ├── 확대/축소 (Zoom)
│   ├── 필터링 (특정 테이블만)
│   ├── 레이아웃 변경 (계층/원형)
│   └── 전체화면 모드
│
└── 📋 정보 패널
    ├── 선택된 노드 세부정보
    ├── 의존성 경로 추적
    └── 실행 순서 미리보기
```

**상호작용 기능:**
- 노드 클릭: 해당 파일로 이동
- 노드 호버: 간단한 정보 툴팁
- 경로 추적: 특정 테이블까지의 의존성 경로 강조
- 임팩트 분석: 변경 시 영향받는 테이블 표시

---

## 워크플로우 실행 및 관리

### 1. 워크플로우 실행 인터페이스

**실행 설정 패널:**

```
🚀 워크플로우 실행 설정
├── 실행 범위 선택
│   ├── 🔘 전체 프로젝트 실행
│   ├── 🔘 특정 태그만 실행
│   ├── 🔘 선택된 테이블만 실행
│   └── 🔘 변경된 테이블만 실행
│
├── 실행 옵션
│   ├── ☑️ 종속성 포함 (Include dependencies)
│   ├── ☑️ 병렬 실행 (Parallel execution)
│   ├── ☑️ 실패 시 중단 (Fail fast)
│   └── ☑️ 드라이런 모드 (Dry run)
│
├── 환경 설정
│   ├── BigQuery 프로젝트: [선택]
│   ├── 기본 위치: US/EU/ASIA
│   ├── 최대 병렬도: [1-50]
│   └── 타임아웃: [분 단위]
│
└── 고급 설정  
    ├── 🏷️ 실행 라벨 추가
    ├── 📧 알림 설정 (성공/실패)
    ├── 🔄 재시도 정책
    └── 📊 실행 우선순위
```

### 2. 실시간 실행 모니터링

**실행 중 화면:**
```
⏳ 워크플로우 실행 중...
├── 📊 진행 상황 표시
│   ├── 전체 진행률: [■■■□□] 60%
│   ├── 완료: 12개 테이블
│   ├── 실행 중: 3개 테이블  
│   ├── 대기 중: 8개 테이블
│   └── 실패: 1개 테이블
│
├── 📋 실시간 로그
│   ├── [14:23:01] 시작: dim_customers
│   ├── [14:23:15] 완료: dim_customers (524 rows)
│   ├── [14:23:16] 시작: fact_orders  
│   ├── [14:23:45] ❌ 실패: stg_products (구문 오류)
│   └── [14:23:50] 일시정지: 실패로 인한 종속성 대기
│
├── 🔍 상세 정보
│   ├── 시작 시간: 14:22:30
│   ├── 실행 시간: 00:01:20
│   ├── 예상 완료: 14:25:15
│   ├── 사용된 슬롯: 평균 25개
│   └── 예상 비용: $0.15
│
└── 🎛️ 제어 옵션
    ├── ⏸️ 일시정지
    ├── ⏹️ 중단
    ├── 📄 상세 로그 보기
    └── 📧 알림 설정
```

### 3. 실행 결과 분석

**완료 후 결과 화면:**
```
✅ 워크플로우 실행 완료
├── 📈 실행 통계
│   ├── 총 실행 시간: 00:03:45
│   ├── 성공: 23개 액션
│   ├── 실패: 2개 액션  
│   ├── 건너뜀: 1개 액션
│   └── 총 처리 행: 1,234,567개
│
├── 💰 비용 정보
│   ├── BigQuery 쿼리 비용: $0.48
│   ├── 스캔된 데이터: 0.08 TB
│   ├── 사용된 슬롯 시간: 12.5분
│   └── 예상 월간 비용: $14.40
│
├── 📊 성능 분석
│   ├── 가장 느린 쿼리: fact_sales (45초)
│   ├── 가장 비싼 쿼리: customer_analytics ($0.12)
│   ├── 병렬 실행 효율성: 85%
│   └── 평균 대기 시간: 2.3초
│
└── 🚨 오류 및 경고
    ├── ❌ stg_products: 구문 오류 (라인 23)
    ├── ❌ dim_categories: 테이블 없음 오류  
    ├── ⚠️ fact_orders: 성능 경고 (파티션 미사용)
    └── ⚠️ customer_summary: 데이터 품질 경고
```

### 4. 개별 액션 상세 정보

**테이블별 실행 결과:**
```
📋 dim_customers 실행 상세정보
├── 기본 정보
│   ├── 테이블 유형: table
│   ├── 실행 시간: 00:00:15  
│   ├── 상태: ✅ 성공
│   └── 생성된 행 수: 12,543개
│
├── 쿼리 정보  
│   ├── 실행된 SQL: [쿼리 미리보기]
│   ├── 스캔된 바이트: 125.3 MB
│   ├── 슬롯 시간: 0.25분
│   └── 예상 비용: $0.001
│
├── 테이블 정보
│   ├── 생성된 테이블: analytics.dim_customers
│   ├── 파티셔닝: DATE(created_date)
│   ├── 클러스터링: customer_id, region
│   └── 만료일: 설정 없음
│
└── 액션 버튼
    ├── 🔍 쿼리 결과 미리보기
    ├── 📊 테이블 스키마 보기
    ├── 🔄 단독 재실행
    └── 📋 로그 복사
```

---

## 릴리스 관리

### 1. 릴리스 구성 생성

**릴리스 구성 설정:**
```
🎯 릴리스 구성 만들기
├── 기본 정보
│   ├── 릴리스 구성 ID: prod-daily-etl
│   ├── 표시 이름: "프로덕션 일일 ETL"
│   ├── 설명: 매일 실행되는 프로덕션 데이터 파이프라인
│   └── Git 참조: refs/heads/main
│
├── 실행 설정
│   ├── BigQuery 프로젝트: company-prod
│   ├── 기본 위치: US
│   ├── 서비스 계정: dataform-prod@company.iam
│   └── 실행 태그: production, daily
│
├── 스케줄링 (선택사항)
│   ├── ☑️ 자동 실행 활성화
│   ├── Cron 표현식: 0 2 * * * (매일 오전 2시)
│   ├── 시간대: Asia/Seoul
│   └── 재시도 정책: 3회, 10분 간격
│
└── 알림 설정
    ├── ☑️ 실행 시작 시 알림
    ├── ☑️ 실행 완료 시 알림  
    ├── ☑️ 실행 실패 시 알림
    ├── 이메일: data-team@company.com
    └── Slack 웹훅: (선택사항)
```

### 2. 스케줄된 실행 관리

**스케줄 대시보드:**
```
📅 스케줄된 실행 관리
├── 📊 실행 캘린더
│   ├── 이번 달 실행 일정 표시
│   ├── 성공/실패 상태 컬러 코딩
│   ├── 예정된 실행 미리보기
│   └── 휴일/점검일 표시
│
├── 📋 최근 실행 기록
│   ├── [2024-01-15 02:00] ✅ 성공 (03:45)
│   ├── [2024-01-14 02:00] ✅ 성공 (03:32)  
│   ├── [2024-01-13 02:00] ❌ 실패 (01:15)
│   └── [2024-01-12 02:00] ✅ 성공 (04:01)
│
├── 📈 성능 트렌드
│   ├── 평균 실행 시간: 3분 42초
│   ├── 성공률: 94.2% (지난 30일)
│   ├── 실행 시간 트렌드 차트
│   └── 비용 트렌드 분석
│
└── 🔧 관리 옵션
    ├── ⏸️ 스케줄 일시정지
    ├── ⚡ 즉시 실행
    ├── ⚙️ 스케줄 설정 수정
    └── 📊 상세 분석 보기
```

### 3. 수동 릴리스 실행

**즉시 실행 인터페이스:**
```
🚀 릴리스 즉시 실행
├── 릴리스 선택
│   ├── 🔘 prod-daily-etl (프로덕션 일일 ETL)
│   ├── 🔘 staging-test (스테이징 테스트)
│   └── 🔘 analytics-weekly (주간 분석)
│
├── 실행 옵션 오버라이드
│   ├── Git 브랜치: main [변경 가능]
│   ├── 실행 태그: production [수정 가능]
│   ├── BigQuery 프로젝트: [오버라이드 가능]
│   └── 병렬성: 기본값 사용/사용자 정의
│
├── 실행 확인
│   ├── ⚠️ 프로덕션 환경에서 실행됩니다
│   ├── 📊 예상 영향: 25개 테이블 업데이트
│   ├── 💰 예상 비용: $2.45
│   └── ⏱️ 예상 실행 시간: 12분
│
└── 📋 실행 사전 점검
    ├── ✅ Git 브랜치 접근 가능
    ├── ✅ BigQuery 권한 확인
    ├── ✅ 의존성 테이블 존재 확인
    └── ⚠️ 일부 테이블이 이미 업데이트됨
```

---

## 모니터링 및 로그

### 1. 실행 기록 조회

**워크플로우 실행 목록:**
```
📊 워크플로우 실행 기록
├── 🔍 필터링 옵션
│   ├── 날짜 범위: [2024-01-01] ~ [2024-01-31]
│   ├── 실행 상태: 전체/성공/실패/진행중
│   ├── 릴리스 구성: 전체/특정 릴리스만
│   ├── 실행 유형: 수동/자동/API
│   └── 실행자: 전체/특정 사용자만
│
├── 📋 실행 목록 테이블
│   ├── 실행 ID | 시작 시간 | 지속시간 | 상태 | 액션 수 | 실행자
│   ├── abc123   | 01-15 02:00 | 03:45   | ✅   | 25/25  | 스케줄러
│   ├── def456   | 01-14 15:30 | 02:12   | ✅   | 12/12  | user@company.com  
│   ├── ghi789   | 01-14 02:00 | 01:15   | ❌   | 8/25   | 스케줄러
│   └── jkl012   | 01-13 14:20 | -       | ⏳   | 15/25  | user@company.com
│
├── 📈 요약 통계
│   ├── 총 실행 횟수: 47회
│   ├── 성공률: 89.4%
│   ├── 평균 실행 시간: 3분 12초
│   ├── 총 처리 데이터: 1.2TB
│   └── 총 예상 비용: $15.67
│
└── 📊 차트 및 분석
    ├── 일별 실행 횟수 트렌드
    ├── 성공/실패율 파이 차트
    ├── 실행 시간 히스토그램
    └── 비용 트렌드 라인 차트
```

### 2. 상세 로그 뷰어

**개별 실행 로그 화면:**
```
📄 실행 상세 로그 - abc123
├── 🎛️ 로그 제어
│   ├── 🔍 로그 검색 (텍스트/정규식)
│   ├── 🎚️ 로그 레벨: ALL/ERROR/WARN/INFO
│   ├── 📅 시간 필터: 전체/특정 시간대
│   ├── 📋 액션 필터: 전체/특정 테이블만
│   └── 💾 로그 다운로드 (TXT/JSON)
│
├── 📊 실행 개요
│   ├── 시작: 2024-01-15 02:00:00 KST
│   ├── 완료: 2024-01-15 05:45:23 KST  
│   ├── 총 시간: 03:45:23
│   ├── 실행자: dataform-scheduler@project.iam
│   └── Git 커밋: a1b2c3d (feat: add customer segmentation)
│
├── 📋 로그 출력  
│   ├── [02:00:01] INFO  워크플로우 시작: prod-daily-etl
│   ├── [02:00:02] INFO  Git 브랜치 체크아웃: main (a1b2c3d)
│   ├── [02:00:03] INFO  컴파일 시작...
│   ├── [02:00:05] INFO  컴파일 완료: 25개 액션 생성
│   ├── [02:00:06] INFO  실행 시작: 의존성 순서로 정렬됨
│   ├── [02:00:07] INFO  [1/25] 시작: stg_orders
│   ├── [02:00:23] INFO  [1/25] 완료: stg_orders (1,234 행, $0.02)
│   ├── [02:00:24] INFO  [2/25] 시작: stg_customers  
│   ├── [02:00:35] INFO  [2/25] 완료: stg_customers (5,678 행, $0.01)
│   ├── [02:01:45] ERROR [15/25] 실패: fact_sales - 구문 오류
│   ├── [02:01:46] WARN  종속성으로 인한 대기: customer_analytics
│   └── [05:45:23] INFO  워크플로우 완료: 23개 성공, 2개 실패
│
└── 🔗 관련 링크
    ├── 🔍 BigQuery 작업 기록 보기
    ├── 📊 컴파일된 SQL 보기  
    ├── 🐛 실패한 액션 디버깅
    └── 📧 이 실행에 대한 알림 내역
```

### 3. 오류 진단 및 디버깅

**오류 분석 인터페이스:**
```
🐛 오류 진단 - fact_sales 실패
├── 📋 오류 정보
│   ├── 오류 타입: SQL 구문 오류
│   ├── 오류 코드: INVALID_SYNTAX  
│   ├── 발생 시간: 2024-01-15 02:01:45
│   ├── 실행 위치: 라인 23, 컬럼 15
│   └── Job ID: bquxjob_7a8b9c0d_123456789
│
├── 📄 오류 메시지
│   ├── 원본 오류:
│   │   "Syntax error: Expected end of input but got keyword SELECT at [23:15]"
│   ├── 한국어 번역:  
│   │   "구문 오류: 입력 종료가 예상되었지만 SELECT 키워드를 만났습니다 (23행 15열)"
│   └── 가능한 원인:
│       ├── • 누락된 괄호 또는 쉼표
│       ├── • 잘못된 WITH 절 구조
│       └── • 예약어 사용 문제
│
├── 🔍 코드 컨텍스트
│   ├── 20: FROM ${ref("stg_orders")} o
│   ├── 21: LEFT JOIN ${ref("dim_customers")} c
│   ├── 22:   ON o.customer_id = c.customer_id
│   ├── 23: SELECT COUNT(*) -- ← 🚨 오류 발생 지점
│   ├── 24: FROM some_table
│   ├── 25: GROUP BY region
│   └── [라인 23으로 이동] [전체 파일 보기]
│
├── 💡 제안된 해결책
│   ├── 1. WITH 절을 올바르게 종료하세요:
│   │      "FROM some_table" 앞에 "),\n" 추가
│   ├── 2. 별도의 CTE로 분리하는 것을 고려하세요
│   └── 3. 유사한 패턴의 다른 파일 참조: dim_products.sqlx
│
└── 🛠️ 빠른 액션
    ├── 📝 파일 수정하러 가기
    ├── 🔄 이 액션만 재실행  
    ├── 📋 오류 보고서 생성
    └── 📚 관련 문서 보기
```

### 4. 실시간 알림 설정

**알림 구성 패널:**
```
🔔 알림 설정
├── 이메일 알림
│   ├── ☑️ 워크플로우 실행 시작
│   ├── ☑️ 워크플로우 실행 완료  
│   ├── ☑️ 워크플로우 실행 실패
│   ├── ☑️ 장시간 실행 중 (30분 초과)
│   ├── ☑️ 비용 임계값 초과 ($10)
│   ├── 수신자: data-team@company.com
│   └── 템플릿: 기본/상세/사용자정의
│
├── Webhook 알림
│   ├── Slack 웹훅 URL: https://hooks.slack.com/...
│   ├── 채널: #data-pipeline
│   ├── 알림 레벨: ERROR, SUCCESS
│   └── 메시지 형식: [JSON 템플릿]
│
├── Cloud Pub/Sub 알림  
│   ├── 토픽: projects/company/topics/dataform-events
│   ├── 메시지 속성: 포함할 메타데이터 선택
│   └── 필터: 특정 릴리스/상태만
│
└── 모바일 푸시 (Google Cloud 앱)
    ├── ☑️ 중요 오류만 푸시
    ├── 조용한 시간: 22:00 ~ 08:00
    └── 그룹화: 동일 릴리스는 하나로 묶음
```

---

## 설정 및 구성

### 1. 프로젝트 설정

**dataform.json 편집 인터페이스:**
```
⚙️ 프로젝트 설정 (dataform.json)
├── 기본 설정
│   ├── 기본 데이터베이스: [company-analytics-prod]
│   ├── 기본 스키마: [analytics]
│   ├── 기본 위치: [US/EU/asia-northeast1]
│   └── 어서션 스키마: [data_quality]
│
├── 환경 변수 (vars)
│   ├── environment: "production"
│   ├── start_date: "2024-01-01"  
│   ├── lookback_days: 7
│   ├── enable_debug: false
│   └── [➕ 새 변수 추가]
│
├── 테이블 설정 기본값
│   ├── 기본 파티션 만료일: 1095일 (3년)
│   ├── 기본 클러스터링: 활성화
│   ├── 기본 라벨:
│   │   ├── team: "data-engineering"
│   │   ├── environment: "production"
│   │   └── cost-center: "analytics"
│   └── 쿼리 타임아웃: 3600초
│
└── 고급 설정
    ├── 컴파일러 옵션
    │   ├── 엄격 모드: ☑️ 활성화
    │   ├── 사용하지 않는 의존성 경고: ☑️
    │   └── 네이밍 규칙 검사: ☑️
    ├── 실행 설정
    │   ├── 최대 병렬 액션: 10개
    │   ├── 실패 시 중단: ☑️
    │   └── 드라이런 모드 기본값: ☐
    └── 로깅 레벨: INFO/DEBUG/ERROR
```

### 2. 저장소 설정 관리

**저장소별 고급 설정:**
```
🏗️ 저장소 설정 - analytics-repo
├── Git 연동 설정
│   ├── 원격 저장소 URL: https://github.com/company/analytics
│   ├── 인증 방법: 개인 액세스 토큰
│   ├── 기본 브랜치: main
│   ├── 보호된 브랜치: main, production
│   └── 자동 동기화: ☑️ 5분마다
│
├── 접근 제어
│   ├── 소유자: data-admin@company.com
│   ├── 편집자:
│   │   ├── data-engineer@company.com
│   │   ├── analytics-team@company.com
│   │   └── [➕ 사용자 추가]
│   ├── 뷰어:
│   │   ├── product-team@company.com
│   │   └── business-analyst@company.com
│   └── 브랜치별 권한:
│       ├── main: 관리자만 병합
│       └── feature/*: 개발자 자유 수정
│
├── 개발 워크스페이스 정책
│   ├── 최대 워크스페이스 수: 5개 (사용자당)
│   ├── 자동 삭제: 30일 미사용 시
│   ├── 리소스 할당량:
│   │   ├── BigQuery 슬롯: 최대 100개
│   │   ├── 일일 쿼리 한도: $50
│   │   └── 스토리지 한도: 1TB
│   └── 개발 환경 접두사: dev_{username}_
│
└── 릴리스 정책
    ├── 자동 테스트 필수: ☑️
    ├── 코드 리뷰 필수: ☑️ (관리자 승인)
    ├── 스테이징 테스트 필수: ☑️
    ├── 프로덕션 배포 승인자:
    │   ├── data-lead@company.com
    │   └── platform-admin@company.com
    └── 롤백 정책: 자동 (실패 시)
```

### 3. 사용자 및 팀 관리

**사용자 관리 인터페이스:**
```
👥 사용자 및 권한 관리
├── 👤 개별 사용자
│   ├── 사용자명: john.doe@company.com
│   ├── 역할: Data Engineer
│   ├── 저장소 접근권한:
│   │   ├── analytics-repo: 편집자
│   │   ├── marketing-repo: 뷰어
│   │   └── finance-repo: 접근 불가
│   ├── 릴리스 권한:
│   │   ├── dev-releases: 실행 가능
│   │   ├── staging-releases: 실행 가능  
│   │   └── prod-releases: 승인 후 실행
│   └── 할당량:
│       ├── 일일 쿼리 비용: $20
│       ├── 활성 워크스페이스: 3개
│       └── BigQuery 슬롯: 50개
│
├── 👥 팀 및 그룹
│   ├── 📊 data-engineering-team
│   │   ├── 구성원: 5명
│   │   ├── 기본 권한: 저장소 편집자
│   │   └── 특별 권한: 릴리스 생성
│   ├── 📈 analytics-team
│   │   ├── 구성원: 8명  
│   │   ├── 기본 권한: 저장소 뷰어
│   │   └── 특별 권한: 개발 워크스페이스 생성
│   └── 🏢 business-users
│       ├── 구성원: 15명
│       ├── 기본 권한: 결과 데이터 뷰어
│       └── 제한사항: 워크플로우 실행 불가
│
└── 🔒 보안 정책
    ├── 로그인 요구사항:
    │   ├── Google Workspace SSO 필수
    │   ├── 2단계 인증 필수  
    │   └── IP 화이트리스트: 사무실만
    ├── 세션 관리:
    │   ├── 최대 세션 시간: 8시간
    │   ├── 유휴 타임아웃: 2시간
    │   └── 동시 세션 제한: 3개
    └── 감사 로그:
        ├── 모든 실행 기록 보관: 1년
        ├── 설정 변경 기록: 영구 보관
        └── 로그 내보내기: Cloud Logging 연동
```

---

## 권한 및 보안

### 1. IAM 역할 및 권한

**DataForm IAM 역할:**
```
🔐 DataForm IAM 역할 체계
├── 역할별 권한 매트릭스
│   │                    │ 뷰어 │ 편집자 │ 관리자 │ 소유자 │
│   ├─────────────────────┼─────┼───────┼───────┼───────┤
│   │ 저장소 목록 조회      │  ✅  │   ✅   │   ✅   │   ✅   │
│   │ 워크스페이스 생성     │  ❌  │   ✅   │   ✅   │   ✅   │
│   │ 코드 편집            │  ❌  │   ✅   │   ✅   │   ✅   │
│   │ 워크플로우 실행       │  ❌  │   ✅   │   ✅   │   ✅   │
│   │ 릴리스 구성 생성      │  ❌  │   ❌   │   ✅   │   ✅   │
│   │ 사용자 권한 관리      │  ❌  │   ❌   │   ❌   │   ✅   │
│   └ 저장소 삭제          │  ❌  │   ❌   │   ❌   │   ✅   │
│
├── BigQuery 연동 권한
│   ├── 필수 BigQuery 역할:
│   │   ├── BigQuery Data Editor (읽기/쓰기)
│   │   ├── BigQuery Job User (쿼리 실행)
│   │   └── BigQuery Resource Viewer (메타데이터)
│   ├── 개발용 권한:
│   │   ├── 개발 데이터셋: [project]:dataset.dev_*
│   │   ├── 임시 테이블: CREATE/DROP 권한
│   │   └── 쿼리 실행 제한: 일일 $50
│   └── 프로덕션 권한:
│       ├── 프로덕션 데이터셋: 읽기 전용
│       ├── 특정 스키마만: analytics.*, marts.*
│       └── 승인된 릴리스만: 자동 실행
│
└── 서비스 계정 설정
    ├── 개발용 서비스 계정:
    │   ├── dataform-dev@project.iam.gserviceaccount.com
    │   ├── 권한: 개발 데이터셋 제한  
    │   └── 키 관리: Google 관리형
    ├── 프로덕션 서비스 계정:
    │   ├── dataform-prod@project.iam.gserviceaccount.com
    │   ├── 권한: 프로덕션 전체 액세스
    │   └── 키 관리: 수동 로테이션 필요
    └── 모니터링 서비스 계정:
        ├── dataform-monitor@project.iam.gserviceaccount.com
        ├── 권한: 로그 및 메트릭 읽기만
        └── 사용: 알림 및 대시보드
```

### 2. 데이터 보안 및 프라이버시

**데이터 보호 설정:**
```
🛡️ 데이터 보안 정책
├── 민감 데이터 처리
│   ├── PII 데이터 마스킹:
│   │   ├── 이메일: user***@domain.com
│   │   ├── 전화번호: ***-***-1234
│   │   ├── 주민번호: ******-*******
│   │   └── 신용카드: ****-****-****-1234
│   ├── 암호화 요구사항:
│   │   ├── 저장 시 암호화: Google 기본 (AES-256)
│   │   ├── 전송 중 암호화: TLS 1.2+
│   │   └── 백업 암호화: Cloud KMS
│   └── 접근 로그:
│       ├── 모든 PII 접근 기록
│       ├── 실시간 이상 탐지
│       └── 규정 준수 보고서 생성
│
├── 지역별 데이터 거버넌스
│   ├── 🇰🇷 한국 데이터 (개인정보보호법):
│   │   ├── 저장 위치: asia-northeast3 (서울)
│   │   ├── 처리 제한: 한국 사용자만 접근
│   │   ├── 보존 기간: 최대 3년
│   │   └── 삭제 요청: 자동 처리 지원
│   ├── 🇪🇺 유럽 데이터 (GDPR):
│   │   ├── 저장 위치: europe-west4 (네덜란드)
│   │   ├── 합법적 근거: 계약 이행
│   │   ├── 데이터 주체 권리: 완전 지원
│   │   └── 데이터 보호 영향 평가: 완료
│   └── 🇺🇸 미국 데이터 (CCPA):
│       ├── 저장 위치: us-central1
│       ├── 개인정보 판매: 금지
│       ├── 옵트아웃 지원: 자동화
│       └── 소비자 권리: 완전 지원
│
└── 감사 및 컴플라이언스
    ├── SOC 2 Type II 준수:
    │   ├── 접근 제어 모니터링
    │   ├── 변경 관리 프로세스
    │   └── 연간 감사 준비
    ├── ISO 27001 준수:
    │   ├── 정보 보안 관리 시스템
    │   ├── 위험 평가 및 관리
    │   └── 사고 대응 절차
    └── 규제 보고:
        ├── 월간 보안 리포트
        ├── 분기별 컴플라이언스 체크
        └── 연간 외부 감사 지원
```

### 3. 접근 로그 및 모니터링

**보안 모니터링 대시보드:**
```
🔍 보안 모니터링 대시보드
├── 실시간 접근 모니터링
│   ├── 현재 활성 사용자: 12명
│   ├── 진행 중인 워크플로우: 3개
│   ├── 비정상 접근 시도: 0회
│   └── 높은 권한 사용: 2회 (승인됨)
│
├── 접근 패턴 분석
│   ├── 📊 시간별 접근 패턴:
│   │   ├── 피크 시간: 09:00-18:00 KST
│   │   ├── 야간 접근: 자동 스케줄만
│   │   └── 주말 접근: 최소한의 모니터링
│   ├── 🌍 지역별 접근:
│   │   ├── 한국: 85% (정상)
│   │   ├── 싱가포르: 10% (원격 근무)
│   │   ├── 미국: 5% (글로벌 팀)
│   │   └── 🚨 기타 지역: 0% (차단됨)
│   └── 🔐 권한 사용 분석:
│       ├── 읽기 전용: 70%
│       ├── 개발 작업: 25%
│       ├── 관리 작업: 4%
│       └── 높은 권한: 1% (감시됨)
│
├── 보안 이벤트 로그
│   ├── [09:15:23] ✅ 정상 로그인: john@company.com (서울)
│   ├── [09:16:45] ✅ 워크스페이스 생성: feature-customer-analytics
│   ├── [10:22:11] ⚠️ 권한 상승: 릴리스 실행 요청 (승인됨)
│   ├── [11:05:38] ✅ 프로덕션 배포: daily-etl (성공)
│   ├── [14:33:07] 🚨 실패한 로그인: unknown@external.com (차단)
│   └── [15:18:52] ⚠️ 대용량 쿼리: 경고 임계값 초과 ($15.30)
│
└── 알림 및 대응
    ├── 자동 알림 설정:
    │   ├── 🔴 보안 위반: 즉시 Slack/이메일
    │   ├── 🟡 의심 활동: 5분 내 알림
    │   ├── 🔵 정책 위반: 1시간 내 리포트
    │   └── 📊 일일 요약: 매일 08:00 발송
    ├── 자동 대응 액션:
    │   ├── IP 차단: 의심스러운 지역
    │   ├── 세션 종료: 비정상 활동 감지
    │   ├── 권한 일시정지: 정책 위반 시
    │   └── 승인 요구: 높은 권한 사용 시
    └── 에스컬레이션 절차:
        ├── 1단계: 자동 차단 (30초)
        ├── 2단계: 보안팀 알림 (5분)
        ├── 3단계: 관리자 개입 (15분)
        └── 4단계: 전체 시스템 격리 (최후 수단)
```

---

## 팁 및 단축키

### 1. 키보드 단축키

**편집 관련:**
```
⌨️ 편집 단축키
├── 파일 관리
│   ├── Ctrl+N: 새 파일 생성
│   ├── Ctrl+O: 파일 열기  
│   ├── Ctrl+S: 현재 파일 저장
│   ├── Ctrl+Shift+S: 모든 파일 저장
│   └── Ctrl+W: 현재 탭 닫기
│
├── 편집 작업
│   ├── Ctrl+Z: 되돌리기
│   ├── Ctrl+Y: 다시 실행
│   ├── Ctrl+C/V: 복사/붙여넣기
│   ├── Ctrl+X: 잘라내기
│   ├── Ctrl+A: 전체 선택
│   └── Ctrl+D: 현재 줄 복제
│
├── 검색 및 바꾸기
│   ├── Ctrl+F: 현재 파일에서 찾기
│   ├── Ctrl+H: 찾기 및 바꾸기
│   ├── Ctrl+Shift+F: 전체 프로젝트 검색
│   ├── F3: 다음 찾기
│   └── Shift+F3: 이전 찾기
│
└── 네비게이션
    ├── Ctrl+G: 특정 라인으로 이동
    ├── Ctrl+P: 파일 빠른 열기
    ├── Ctrl+Shift+P: 명령 팔레트
    ├── F12: 정의로 이동 (ref 함수)
    └── Alt+F12: 정의 미리보기
```

**DataForm 전용 단축키:**
```
🚀 DataForm 단축키
├── 컴파일 및 실행
│   ├── Ctrl+Shift+C: 프로젝트 컴파일
│   ├── Ctrl+Enter: 현재 파일만 실행
│   ├── Ctrl+Shift+E: 전체 워크플로우 실행
│   ├── Ctrl+Shift+T: 테스트 실행
│   └── Ctrl+Shift+D: 드라이런 모드 실행
│
├── 뷰 전환
│   ├── Ctrl+Shift+G: 의존성 그래프 토글
│   ├── Ctrl+Shift+L: 로그 패널 토글
│   ├── Ctrl+Shift+R: 실행 결과 토글  
│   ├── Ctrl+`: 터미널 토글
│   └── Ctrl+Shift+`: 새 터미널
│
├── Git 작업
│   ├── Ctrl+Shift+G: Git 사이드바 열기
│   ├── Ctrl+K Ctrl+S: 변경사항 스테이지
│   ├── Ctrl+K Ctrl+U: 스테이지 해제
│   ├── Ctrl+Shift+U: Git 상태 새로고침
│   └── Ctrl+K Ctrl+C: Git 커밋
│
└── 도움말 및 정보
    ├── F1: 도움말 열기
    ├── Ctrl+Shift+H: DataForm 문서
    ├── Ctrl+K Ctrl+I: 함수 정보 표시
    └── Ctrl+Space: 자동 완성 트리거
```

### 2. 유용한 팁과 트릭

**코드 편집 팁:**
```sql
-- 💡 팁 1: ref() 함수에서 자동 완성 활용
SELECT * 
FROM ${ref("stg_")} -- ← "stg_" 타이핑 후 Ctrl+Space로 목록 보기

-- 💡 팁 2: 다중 커서로 빠른 편집
-- Ctrl+D로 동일한 단어 선택, 동시에 편집 가능
SELECT 
  customer_id,    -- ← 여기서 customer_id 선택 후 Ctrl+D
  customer_name,  -- ← customer를 client로 한번에 변경 가능
  customer_email

-- 💡 팁 3: 코드 폴딩으로 가독성 향상
config {  -- ← 이 블록을 접거나 펼 수 있음
  type: "table",
  description: "긴 설명이 있는 테이블..."
}

-- 💡 팁 4: 컬럼 주석을 활용한 문서화
SELECT 
  customer_id,           -- PK: 고객 고유 식별자
  UPPER(customer_name) as customer_name,  -- 대문자로 정규화된 고객명
  -- 이메일 마스킹 처리
  CONCAT(LEFT(email, 3), '***', SUBSTR(email, STRPOS(email, '@'))) as masked_email
```

**워크플로우 최적화 팁:**
```javascript
// 💡 팁 5: 환경별 설정을 활용한 유연한 개발
// includes/config.js
const isDev = dataform.projectConfig.vars.environment === 'dev';
const sampleSize = isDev ? 0.01 : 1.0;  // 개발환경에서는 1% 샘플링

function getTableConfig(tableName) {
  return {
    type: "table",
    // 개발환경에서는 파티셔닝 비활성화로 빠른 테스트
    bigquery: {
      partitionBy: isDev ? undefined : "DATE(created_date)",
      clusterBy: isDev ? undefined : ["customer_id"]
    }
  };
}
```

**디버깅 팁:**
```sql
-- 💡 팁 6: 단계적 디버깅을 위한 임시 테이블
-- 복잡한 쿼리는 CTE로 나누어 각 단계를 확인
WITH step1 AS (
  SELECT * FROM ${ref("raw_data")} 
  WHERE created_date >= '2024-01-01'
),
step2 AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_date) as rn
  FROM step1
),
step3 AS (
  SELECT * FROM step2 WHERE rn = 1
)
-- 각 CTE를 개별적으로 실행해서 결과 확인 가능
SELECT * FROM step3;

-- 💡 팁 7: 어서션을 활용한 데이터 품질 체크
-- definitions/assertions/daily_data_quality.sqlx
config {
  type: "assertion",
  description: "일일 데이터 품질 체크"
}

-- 예상보다 적은 데이터가 들어왔는지 체크
SELECT 
  DATE(created_date) as date,
  COUNT(*) as row_count
FROM ${ref("daily_sales")}
WHERE DATE(created_date) = CURRENT_DATE()
GROUP BY 1
HAVING COUNT(*) < 1000  -- 최소 1000행 이상이어야 함
```

### 3. 성능 최적화 꿀팁

**쿼리 최적화:**
```sql
-- ❌ 비효율적: 전체 테이블 스캔
SELECT * FROM ${ref("large_table")} 
WHERE customer_region = 'Asia';

-- ✅ 효율적: 파티션 + 클러스터 활용
SELECT * FROM ${ref("large_table")} 
WHERE DATE(created_date) >= '2024-01-01'  -- 파티션 필터
  AND customer_region = 'Asia';           -- 클러스터 필터

-- 💡 팁 8: 윈도우 함수 최적화
-- ❌ 비효율적: 여러 번의 윈도우 함수
SELECT 
  *,
  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) as rn,
  COUNT(*) OVER (PARTITION BY customer_id) as total_orders,
  SUM(amount) OVER (PARTITION BY customer_id) as total_spent
FROM orders

-- ✅ 더 효율적: 집계를 먼저 수행
WITH customer_stats AS (
  SELECT 
    customer_id,
    COUNT(*) as total_orders,
    SUM(amount) as total_spent
  FROM orders 
  GROUP BY customer_id
),
ranked_orders AS (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) as rn
  FROM orders
)
SELECT 
  o.*,
  s.total_orders,
  s.total_spent
FROM ranked_orders o
JOIN customer_stats s ON o.customer_id = s.customer_id;
```

**개발 워크플로우 팁:**
```bash
# 💡 팁 9: Git 브랜치 전략
# feature 브랜치에서 개발
git checkout -b feature/customer-segmentation

# 작은 단위로 자주 커밋
git add definitions/marts/customer_segments.sqlx
git commit -m "Add customer RFM segmentation logic"

# 정기적으로 main에서 최신 변경사항 가져오기
git checkout main && git pull
git checkout feature/customer-segmentation
git rebase main

# 💡 팁 10: 환경별 테스트 전략
# 개발환경: 샘플 데이터로 빠른 검증
dataform run --profile=dev --vars='{"sample_rate": 0.01}'

# 스테이징: 실제 데이터로 전체 테스트  
dataform run --profile=staging --vars='{"enable_full_refresh": true}'

# 프로덕션: 증분 업데이트만
dataform run --profile=prod --tags=production
```

### 4. 문제 해결 체크리스트

**컴파일 오류 해결:**
```
🐛 컴파일 오류 체크리스트
├── ☐ 구문 검사
│   ├── 괄호 짝 맞추기 확인
│   ├── 쉼표 누락 확인  
│   ├── 따옴표 닫기 확인
│   └── 예약어 사용 검토
│
├── ☐ 의존성 검사
│   ├── ref() 함수의 테이블명 정확성
│   ├── 순환 의존성 여부 확인
│   ├── 외부 테이블 존재 여부 확인
│   └── includes/ 파일 import 검토
│
├── ☐ 설정 검사
│   ├── dataform.json 유효성 확인
│   ├── config 블록 문법 검토
│   ├── 환경 변수 값 확인
│   └── BigQuery 프로젝트 권한 확인
│
└── ☐ 고급 문제해결
    ├── 컴파일된 SQL 직접 확인
    ├── BigQuery 콘솔에서 SQL 테스트
    ├── 단계별 CTE로 문제 부분 격리
    └── 커뮤니티 포럼 검색
```

**실행 오류 해결:**
```
🔧 실행 오류 해결 가이드
├── BigQuery 권한 오류
│   ├── 서비스 계정 권한 재확인
│   ├── 데이터셋 접근권한 검토
│   ├── BigQuery Job User 역할 확인
│   └── 프로젝트 결제 계정 활성화 확인
│
├── 메모리/타임아웃 오류  
│   ├── 쿼리를 더 작은 단위로 분할
│   ├── 파티션 필터 추가로 스캔 데이터 축소
│   ├── 복잡한 JOIN을 단계별로 분리
│   └── 임시 테이블을 활용한 중간 결과 저장
│
├── 데이터 타입 오류
│   ├── SAFE_CAST() 함수로 안전한 형변환
│   ├── NULL 값 처리 로직 추가
│   ├── 날짜 형식 통일화
│   └── 문자열 인코딩 문제 해결
│
└── 성능 문제  
    ├── 실행 계획 분석 (BigQuery UI)
    ├── 슬롯 사용량 모니터링
    ├── 클러스터링 최적화
    └── 증분 처리로 전환 검토
```

---

이 DataForm UI 가이드를 통해 Google Cloud DataForm의 웹 인터페이스를 완전히 마스터하고 효율적으로 데이터 파이프라인을 관리할 수 있습니다!


