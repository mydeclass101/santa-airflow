CREATE TABLE IF NOT EXISTS lakehouse.bronze.categories
WITH (partitioning = ARRAY['batch_date'])
AS SELECT
    category_id,
    category_code,
    parent_category_id,
    name_th,
    name_en,
    created_at,
    CAST(null as DATE) as batch_date,
    localtimestamp as ingest_datetime
  FROM shop.public.categories
WITH NO DATA;


INSERT INTO lakehouse.bronze.categories
SELECT
  category_id,
  category_code,
  parent_category_id,
  name_th,
  name_en,
  created_at,
  DATE '{{ partition_key }}' as batch_date,
  localtimestamp as ingest_datetime
FROM shop.public.categories;


DELETE FROM lakehouse.bronze.categories
WHERE batch_date = DATE '{{ partition_key }}'
  AND ingest_datetime < (SELECT max(ingest_datetime) FROM lakehouse.bronze.categories WHERE batch_date = DATE '{{ partition_key }}');
