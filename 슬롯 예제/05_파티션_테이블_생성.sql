-- 파티션 테이블 생성
CREATE TABLE `project.dataset.partitioned_table`
(
    id           INT64,
    name         STRING,
    created_date DATE
)
    PARTITION BY created_date
    CLUSTER BY id;