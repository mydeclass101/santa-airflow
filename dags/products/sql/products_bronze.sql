CREATE TABLE IF NOT EXISTS lakehouse.bronze.products
WITH (partitioning = ARRAY['batch_date'])
AS SELECT
    product_id,
    sku,
    product_name,
    category_id,
    brand_id,
    supplier_id,
    unit_price,
    cost_price,
    weight_grams,
    status,
    launched_at,
    discontinued_at,
    created_at,
    updated_at,
    CAST(null as DATE) as batch_date,
    localtimestamp as ingest_datetime
  FROM shop.public.products
WITH NO DATA; 


INSERT INTO lakehouse.bronze.products
SELECT
  product_id,
  sku,
  product_name,
  category_id,
  brand_id,
  supplier_id,
  unit_price,
  cost_price,
  weight_grams,
  status,
  launched_at,
  discontinued_at,
  created_at,
  updated_at,
  DATE '{{ partition_key }}' as batch_date,
  localtimestamp as ingest_datetime
FROM shop.public.products;


DELETE FROM lakehouse.bronze.products
WHERE batch_date = DATE '{{ partition_key }}'
  AND ingest_datetime < (SELECT max(ingest_datetime) FROM lakehouse.bronze.products WHERE batch_date = DATE '{{ partition_key }}');