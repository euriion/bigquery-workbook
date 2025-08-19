-- 쿼리 우선순위 설정 예시
SELECT *
FROM `project.dataset.table`
WHERE condition = true;
-- 실행 시 슬롯 우선순위: INTERACTIVE > BATCH