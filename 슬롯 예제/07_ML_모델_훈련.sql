-- ML 훈련용 예약 할당
CREATE OR REPLACE MODEL `ml_project.models.customer_segmentation`
    OPTIONS(
        model_type='KMEANS',
        num_clusters=5,
        reservation='ml-training-reservation'
    ) AS
SELECT customer_id,
       feature1,
       feature2,
       feature3
FROM `ml_project.features.customer_features`;