-- 비효율적인 쿼리 (피해야 할 패턴)
SELECT *
FROM large_table t1
         JOIN another_large_table t2 ON t1.id = t2.id
WHERE t1.date_column BETWEEN '2023-01-01' AND '2023-12-31';

-- 최적화된 쿼리
SELECT t1.id,
       t1.column1,
       t2.column2
FROM large_table t1
         JOIN another_large_table t2 ON t1.id = t2.id
WHERE t1.date_column BETWEEN '2023-01-01' AND '2023-12-31'
  AND t1._PARTITIONTIME BETWEEN TIMESTAMP('2023-01-01') AND TIMESTAMP('2023-12-31');