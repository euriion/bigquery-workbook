# BigQuery API 활용 완벽 가이드

BigQuery의 다양한 API를 활용한 프로그래밍 방식의 데이터 처리 방법을 다루는 가이드입니다.

---

## 목차

1. [BigQuery API 개요](#1-bigquery-api-개요)
2. [Python 클라이언트 라이브러리](#2-python-클라이언트-라이브러리)
3. [JavaScript/Node.js 활용](#3-javascriptnodejs-활용)
4. [REST API 직접 호출](#4-rest-api-직접-호출)
5. [스트리밍 API](#5-스트리밍-api)
6. [실제 활용 사례](#6-실제-활용-사례)

---

## 1. BigQuery API 개요

### 1.1 지원하는 API 유형

- **REST API**: HTTP 기반 직접 호출
- **클라이언트 라이브러리**: Python, Java, Node.js, Go 등
- **gRPC API**: 고성능 스트리밍
- **Storage Write API**: 고성능 스트리밍 삽입

### 1.2 인증 설정

```python
from google.cloud import bigquery
from google.oauth2 import service_account

# 서비스 계정 키 파일 사용
credentials = service_account.Credentials.from_service_account_file(
    'path/to/service-account-key.json'
)
client = bigquery.Client(credentials=credentials, project='your-project-id')

# 기본 인증 (gcloud auth application-default login 사용)
client = bigquery.Client()
```

---

## 2. Python 클라이언트 라이브러리

### 2.1 기본 쿼리 실행

```python
from google.cloud import bigquery
import pandas as pd

def run_query(sql_query):
    """기본 쿼리 실행"""
    client = bigquery.Client()
    
    # 쿼리 실행
    query_job = client.query(sql_query)
    
    # 결과 가져오기
    results = query_job.result()
    
    # DataFrame으로 변환
    df = results.to_dataframe()
    return df

# 사용 예시
sql = """
    SELECT 
        customer_id,
        SUM(order_amount) as total_amount
    FROM `project.dataset.orders`
    WHERE order_date >= '2024-01-01'
    GROUP BY customer_id
    ORDER BY total_amount DESC
    LIMIT 10
"""

top_customers = run_query(sql)
print(top_customers)
```

### 2.2 테이블 생성 및 데이터 로드

```python
def create_table_from_dataframe(df, table_id, schema=None):
    """DataFrame에서 테이블 생성"""
    client = bigquery.Client()
    
    # 작업 구성
    job_config = bigquery.LoadJobConfig()
    if schema:
        job_config.schema = schema
    else:
        job_config.autodetect = True
    
    # 기존 테이블 덮어쓰기
    job_config.write_disposition = bigquery.WriteDisposition.WRITE_TRUNCATE
    
    # 데이터 로드
    job = client.load_table_from_dataframe(
        df, table_id, job_config=job_config
    )
    job.result()  # 작업 완료까지 대기
    
    print(f"Loaded {job.output_rows} rows into {table_id}")

# 사용 예시
import pandas as pd

sample_data = pd.DataFrame({
    'customer_id': [1, 2, 3],
    'customer_name': ['Alice', 'Bob', 'Charlie'],
    'signup_date': ['2024-01-01', '2024-01-02', '2024-01-03']
})

create_table_from_dataframe(
    sample_data, 
    'project.dataset.customers'
)
```

### 2.3 배치 작업 관리

```python
def run_batch_queries(queries):
    """여러 쿼리를 배치로 실행"""
    client = bigquery.Client()
    jobs = []
    
    # 모든 쿼리 시작
    for i, query in enumerate(queries):
        job_config = bigquery.QueryJobConfig(
            job_id=f"batch_job_{i}_{int(time.time())}"
        )
        job = client.query(query, job_config=job_config)
        jobs.append(job)
        print(f"Started job: {job.job_id}")
    
    # 모든 작업 완료 대기
    results = []
    for job in jobs:
        result = job.result()
        results.append({
            'job_id': job.job_id,
            'state': job.state,
            'total_bytes_processed': job.total_bytes_processed,
            'rows': [dict(row) for row in result]
        })
    
    return results

# 사용 예시
batch_queries = [
    "SELECT COUNT(*) as total_orders FROM `project.dataset.orders`",
    "SELECT COUNT(DISTINCT customer_id) as unique_customers FROM `project.dataset.orders`",
    "SELECT AVG(order_amount) as avg_order_amount FROM `project.dataset.orders`"
]

batch_results = run_batch_queries(batch_queries)
for result in batch_results:
    print(f"Job {result['job_id']}: {result['rows']}")
```

### 2.4 동적 쿼리 생성

```python
class DynamicQueryBuilder:
    """동적 쿼리 빌더 클래스"""
    
    def __init__(self, base_table):
        self.base_table = base_table
        self.select_fields = []
        self.where_conditions = []
        self.group_by_fields = []
        self.order_by_fields = []
        self.limit_count = None
    
    def select(self, *fields):
        self.select_fields.extend(fields)
        return self
    
    def where(self, condition):
        self.where_conditions.append(condition)
        return self
    
    def group_by(self, *fields):
        self.group_by_fields.extend(fields)
        return self
    
    def order_by(self, field, direction='ASC'):
        self.order_by_fields.append(f"{field} {direction}")
        return self
    
    def limit(self, count):
        self.limit_count = count
        return self
    
    def build(self):
        """쿼리 문자열 생성"""
        query_parts = []
        
        # SELECT
        select_clause = "SELECT " + ", ".join(self.select_fields or ["*"])
        query_parts.append(select_clause)
        
        # FROM
        query_parts.append(f"FROM `{self.base_table}`")
        
        # WHERE
        if self.where_conditions:
            where_clause = "WHERE " + " AND ".join(self.where_conditions)
            query_parts.append(where_clause)
        
        # GROUP BY
        if self.group_by_fields:
            group_clause = "GROUP BY " + ", ".join(self.group_by_fields)
            query_parts.append(group_clause)
        
        # ORDER BY
        if self.order_by_fields:
            order_clause = "ORDER BY " + ", ".join(self.order_by_fields)
            query_parts.append(order_clause)
        
        # LIMIT
        if self.limit_count:
            query_parts.append(f"LIMIT {self.limit_count}")
        
        return "\n".join(query_parts)
    
    def execute(self):
        """쿼리 실행"""
        client = bigquery.Client()
        query = self.build()
        print(f"Executing query:\n{query}")
        return client.query(query).result().to_dataframe()

# 사용 예시
builder = DynamicQueryBuilder('project.dataset.orders')
result = (builder
    .select('customer_id', 'SUM(order_amount) as total_spent')
    .where('order_date >= "2024-01-01"')
    .where('order_amount > 100')
    .group_by('customer_id')
    .order_by('total_spent', 'DESC')
    .limit(10)
    .execute()
)
```

---

## 3. JavaScript/Node.js 활용

### 3.1 기본 설정

```javascript
// npm install @google-cloud/bigquery

const { BigQuery } = require('@google-cloud/bigquery');

// 클라이언트 초기화
const bigquery = new BigQuery({
    projectId: 'your-project-id',
    keyFilename: 'path/to/service-account-key.json'
});

async function runQuery(sqlQuery) {
    const options = {
        query: sqlQuery,
        location: 'US',
    };

    try {
        const [job] = await bigquery.createQueryJob(options);
        console.log(`Job ${job.id} started.`);

        const [rows] = await job.getQueryResults();
        return rows;
    } catch (error) {
        console.error('Query failed:', error);
        throw error;
    }
}

// 사용 예시
async function getTopCustomers() {
    const query = `
        SELECT 
            customer_id,
            SUM(order_amount) as total_amount
        FROM \`project.dataset.orders\`
        GROUP BY customer_id
        ORDER BY total_amount DESC
        LIMIT 5
    `;
    
    const rows = await runQuery(query);
    console.log('Top customers:');
    rows.forEach(row => {
        console.log(`Customer ${row.customer_id}: $${row.total_amount}`);
    });
}
```

### 3.2 스트리밍 삽입

```javascript
async function streamData(tableId, data) {
    const dataset = bigquery.dataset('your-dataset');
    const table = dataset.table(tableId);

    try {
        await table.insert(data);
        console.log(`Inserted ${data.length} rows`);
    } catch (error) {
        if (error.name === 'PartialFailureError') {
            console.log('Some rows failed to insert:');
            error.errors.forEach(err => console.log(err));
        } else {
            console.error('Insert failed:', error);
        }
    }
}

// 사용 예시
const eventData = [
    {
        user_id: '12345',
        event_type: 'page_view',
        timestamp: new Date().toISOString(),
        properties: { page: '/home' }
    },
    {
        user_id: '67890', 
        event_type: 'click',
        timestamp: new Date().toISOString(),
        properties: { button: 'signup' }
    }
];

streamData('events', eventData);
```

---

## 4. REST API 직접 호출

### 4.1 HTTP 요청 예시

```python
import requests
import json
from google.auth.transport.requests import Request
from google.oauth2 import service_account

def get_access_token():
    """액세스 토큰 획득"""
    credentials = service_account.Credentials.from_service_account_file(
        'path/to/service-account-key.json',
        scopes=['https://www.googleapis.com/auth/bigquery']
    )
    credentials.refresh(Request())
    return credentials.token

def run_query_rest_api(project_id, sql_query):
    """REST API로 쿼리 실행"""
    token = get_access_token()
    
    url = f'https://bigquery.googleapis.com/bigquery/v2/projects/{project_id}/queries'
    
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    payload = {
        'query': sql_query,
        'useLegacySql': False,
        'maxResults': 1000
    }
    
    response = requests.post(url, headers=headers, json=payload)
    
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f"Query failed: {response.text}")

# 사용 예시
result = run_query_rest_api(
    'your-project-id',
    'SELECT COUNT(*) as total FROM `project.dataset.table`'
)
print(json.dumps(result, indent=2))
```

### 4.2 테이블 메타데이터 조회

```python
def get_table_metadata(project_id, dataset_id, table_id):
    """테이블 메타데이터 조회"""
    token = get_access_token()
    
    url = f'https://bigquery.googleapis.com/bigquery/v2/projects/{project_id}/datasets/{dataset_id}/tables/{table_id}'
    
    headers = {'Authorization': f'Bearer {token}'}
    
    response = requests.get(url, headers=headers)
    
    if response.status_code == 200:
        metadata = response.json()
        return {
            'table_id': metadata.get('id'),
            'description': metadata.get('description'),
            'num_rows': metadata.get('numRows'),
            'num_bytes': metadata.get('numBytes'),
            'creation_time': metadata.get('creationTime'),
            'last_modified': metadata.get('lastModifiedTime'),
            'schema_fields': len(metadata.get('schema', {}).get('fields', []))
        }
    else:
        raise Exception(f"Failed to get metadata: {response.text}")

# 사용 예시
metadata = get_table_metadata('project', 'dataset', 'table')
print(f"Table has {metadata['num_rows']} rows and {metadata['schema_fields']} columns")
```

---

## 5. 스트리밍 API

### 5.1 Storage Write API 활용

```python
from google.cloud import bigquery_storage_v1
from google.cloud.bigquery_storage_v1 import types
from google.cloud.bigquery_storage_v1 import writer
import json

def stream_data_storage_api(project_id, dataset_id, table_id, data):
    """Storage Write API를 사용한 고성능 스트리밍"""
    
    client = bigquery_storage_v1.BigQueryWriteClient()
    table_path = client.table_path(project_id, dataset_id, table_id)
    
    # 스트림 생성
    write_stream = types.WriteStream()
    write_stream.type_ = types.WriteStream.Type.COMMITTED
    write_stream = client.create_write_stream(
        parent=table_path,
        write_stream=write_stream
    )
    
    # 스트리밍 writer 생성
    stream_writer = writer.AppendRowsStream(
        client, write_stream.name
    )
    
    try:
        # 데이터 전송
        for batch in data:
            # JSON 직렬화
            serialized_rows = []
            for row in batch:
                serialized_rows.append(json.dumps(row).encode('utf-8'))
            
            # 요청 생성
            append_request = types.AppendRowsRequest()
            append_request.write_stream = write_stream.name
            
            json_rows = types.AppendRowsRequest.ProtoData()
            json_rows.rows.serialized_rows = serialized_rows
            append_request.proto_rows = json_rows
            
            # 전송
            response = stream_writer.send(append_request)
            print(f"Streamed batch, offset: {response.append_result.offset}")
    
    finally:
        # 스트림 종료
        stream_writer.close()
        
        # 스트림 완료
        client.finalize_write_stream(name=write_stream.name)

# 사용 예시
sample_data = [
    [
        {'user_id': '123', 'action': 'login', 'timestamp': '2024-01-01T10:00:00'},
        {'user_id': '456', 'action': 'logout', 'timestamp': '2024-01-01T11:00:00'}
    ]
]

stream_data_storage_api('project', 'dataset', 'events', sample_data)
```

---

## 6. 실제 활용 사례

### 6.1 실시간 ETL 파이프라인

```python
class RealTimeETLPipeline:
    """실시간 ETL 파이프라인"""
    
    def __init__(self, project_id):
        self.project_id = project_id
        self.client = bigquery.Client(project=project_id)
        
    def extract_from_source(self, source_table, last_sync_time):
        """소스에서 데이터 추출"""
        query = f"""
            SELECT *
            FROM `{source_table}`
            WHERE updated_at > TIMESTAMP('{last_sync_time}')
            ORDER BY updated_at
        """
        return self.client.query(query).result().to_dataframe()
    
    def transform_data(self, df):
        """데이터 변환"""
        # 데이터 정제
        df = df.dropna(subset=['customer_id'])
        
        # 새 컬럼 추가
        df['full_name'] = df['first_name'] + ' ' + df['last_name']
        df['processed_at'] = pd.Timestamp.now()
        
        # 데이터 타입 변환
        df['customer_id'] = df['customer_id'].astype(str)
        
        return df
    
    def load_to_target(self, df, target_table):
        """타겟 테이블로 로드"""
        job_config = bigquery.LoadJobConfig()
        job_config.write_disposition = bigquery.WriteDisposition.WRITE_APPEND
        job_config.schema_update_options = [
            bigquery.SchemaUpdateOption.ALLOW_FIELD_ADDITION
        ]
        
        job = self.client.load_table_from_dataframe(
            df, target_table, job_config=job_config
        )
        job.result()
        
        return job.output_rows
    
    def run_etl(self, source_table, target_table, last_sync_time):
        """ETL 실행"""
        try:
            print(f"Starting ETL: {source_table} -> {target_table}")
            
            # Extract
            df = self.extract_from_source(source_table, last_sync_time)
            print(f"Extracted {len(df)} rows")
            
            if len(df) == 0:
                print("No new data to process")
                return
            
            # Transform
            df_transformed = self.transform_data(df)
            print(f"Transformed data: {df_transformed.shape}")
            
            # Load
            rows_loaded = self.load_to_target(df_transformed, target_table)
            print(f"Loaded {rows_loaded} rows to {target_table}")
            
            return df_transformed['updated_at'].max()
            
        except Exception as e:
            print(f"ETL failed: {e}")
            raise

# 사용 예시
pipeline = RealTimeETLPipeline('your-project')
last_sync = pipeline.run_etl(
    'project.raw.customers',
    'project.processed.customers',
    '2024-01-01 00:00:00'
)
```

### 6.2 데이터 품질 모니터링

```python
class DataQualityMonitor:
    """데이터 품질 모니터링 시스템"""
    
    def __init__(self, project_id):
        self.client = bigquery.Client(project=project_id)
    
    def check_data_quality(self, table_id):
        """데이터 품질 검사"""
        checks = {
            'total_rows': self._count_rows(table_id),
            'null_percentage': self._calculate_null_percentage(table_id),
            'duplicate_percentage': self._calculate_duplicate_percentage(table_id),
            'data_freshness_hours': self._calculate_data_freshness(table_id)
        }
        
        # 품질 점수 계산
        quality_score = self._calculate_quality_score(checks)
        checks['quality_score'] = quality_score
        
        # 결과 저장
        self._save_quality_results(table_id, checks)
        
        return checks
    
    def _count_rows(self, table_id):
        query = f"SELECT COUNT(*) as count FROM `{table_id}`"
        result = list(self.client.query(query))[0]
        return result.count
    
    def _calculate_null_percentage(self, table_id):
        # 모든 컬럼의 NULL 비율 계산
        schema = self.client.get_table(table_id).schema
        
        null_checks = []
        for field in schema:
            null_checks.append(f"COUNTIF({field.name} IS NULL)")
        
        query = f"""
            SELECT 
                ({' + '.join(null_checks)}) as total_nulls,
                COUNT(*) * {len(schema)} as total_cells
            FROM `{table_id}`
        """
        
        result = list(self.client.query(query))[0]
        return (result.total_nulls / result.total_cells * 100) if result.total_cells > 0 else 0
    
    def _calculate_quality_score(self, checks):
        # 간단한 점수 계산 로직
        score = 100
        score -= min(checks['null_percentage'], 50)  # NULL 비율만큼 차감
        score -= min(checks['duplicate_percentage'], 30)  # 중복 비율만큼 차감
        
        if checks['data_freshness_hours'] > 24:
            score -= 20  # 24시간 이상 오래된 데이터
        
        return max(score, 0)
    
    def _save_quality_results(self, table_id, results):
        # 결과를 품질 모니터링 테이블에 저장
        quality_data = [{
            'table_id': table_id,
            'check_timestamp': pd.Timestamp.now().isoformat(),
            **results
        }]
        
        df = pd.DataFrame(quality_data)
        self.client.load_table_from_dataframe(
            df, 'project.monitoring.data_quality_results'
        ).result()

# 사용 예시
monitor = DataQualityMonitor('your-project')
quality_results = monitor.check_data_quality('project.data.customers')
print(f"Quality Score: {quality_results['quality_score']}")
```

### 6.3 자동화된 보고서 생성

```python
class AutomatedReporting:
    """자동화된 보고서 생성 시스템"""
    
    def __init__(self, project_id):
        self.client = bigquery.Client(project=project_id)
    
    def generate_sales_report(self, start_date, end_date):
        """매출 보고서 생성"""
        queries = {
            'daily_sales': f"""
                SELECT 
                    DATE(order_timestamp) as date,
                    SUM(amount) as daily_sales,
                    COUNT(*) as order_count,
                    COUNT(DISTINCT customer_id) as unique_customers
                FROM `project.sales.orders`
                WHERE DATE(order_timestamp) BETWEEN '{start_date}' AND '{end_date}'
                GROUP BY date
                ORDER BY date
            """,
            'product_performance': f"""
                SELECT 
                    product_name,
                    SUM(quantity) as units_sold,
                    SUM(amount) as revenue,
                    AVG(amount / quantity) as avg_unit_price
                FROM `project.sales.orders` o
                JOIN `project.catalog.products` p ON o.product_id = p.product_id
                WHERE DATE(order_timestamp) BETWEEN '{start_date}' AND '{end_date}'
                GROUP BY product_name
                ORDER BY revenue DESC
                LIMIT 20
            """,
            'customer_segments': f"""
                WITH customer_stats AS (
                    SELECT 
                        customer_id,
                        SUM(amount) as total_spent,
                        COUNT(*) as order_count
                    FROM `project.sales.orders`
                    WHERE DATE(order_timestamp) BETWEEN '{start_date}' AND '{end_date}'
                    GROUP BY customer_id
                )
                SELECT 
                    CASE 
                        WHEN total_spent >= 1000 THEN 'VIP'
                        WHEN total_spent >= 500 THEN 'Premium'
                        WHEN total_spent >= 100 THEN 'Regular'
                        ELSE 'Basic'
                    END as segment,
                    COUNT(*) as customer_count,
                    SUM(total_spent) as segment_revenue,
                    AVG(total_spent) as avg_customer_value
                FROM customer_stats
                GROUP BY segment
                ORDER BY segment_revenue DESC
            """
        }
        
        report_data = {}
        for report_name, query in queries.items():
            df = self.client.query(query).result().to_dataframe()
            report_data[report_name] = df
        
        # 보고서 생성
        report = self._create_report(report_data, start_date, end_date)
        
        # 보고서 저장
        self._save_report(report, f"sales_report_{start_date}_{end_date}")
        
        return report
    
    def _create_report(self, data, start_date, end_date):
        """HTML 보고서 생성"""
        html = f"""
        <html>
        <head>
            <title>Sales Report ({start_date} - {end_date})</title>
            <style>
                body {{ font-family: Arial, sans-serif; }}
                table {{ border-collapse: collapse; width: 100%; }}
                th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
                th {{ background-color: #f2f2f2; }}
            </style>
        </head>
        <body>
            <h1>Sales Report</h1>
            <p>Period: {start_date} to {end_date}</p>
            
            <h2>Daily Sales Summary</h2>
            {data['daily_sales'].to_html(index=False)}
            
            <h2>Top Products</h2>
            {data['product_performance'].to_html(index=False)}
            
            <h2>Customer Segments</h2>
            {data['customer_segments'].to_html(index=False)}
        </body>
        </html>
        """
        return html
    
    def _save_report(self, html_content, filename):
        """보고서를 Cloud Storage에 저장"""
        # Cloud Storage 업로드 로직
        with open(f'/tmp/{filename}.html', 'w') as f:
            f.write(html_content)
        print(f"Report saved: {filename}.html")

# 사용 예시
reporter = AutomatedReporting('your-project')
report = reporter.generate_sales_report('2024-01-01', '2024-01-31')
```

---

BigQuery API를 활용하면 프로그래밍 방식으로 복잡한 데이터 처리 워크플로우를 구축하고 자동화할 수 있습니다. 각 언어별 클라이언트 라이브러리와 REST API를 적절히 조합하여 효율적인 데이터 파이프라인을 만들어보세요.
