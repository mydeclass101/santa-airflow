CREATE TABLE IF NOT EXISTS lakehouse.bronze.customers
WITH (partitioning = ARRAY['batch_date'])
AS SELECT
    customer_id,
    customer_code,
    gender,
    birth_date,
    membership_tier,
    status,
    acquisition_channel,
    marketing_opt_in,
    registered_at,
    created_at,
    updated_at,
    CAST(null as DATE) as batch_date,
    localtimestamp as ingest_datetime
  FROM shop.public.customers
WITH NO DATA; 
  
INSERT INTO lakehouse.bronze.customers
SELECT
  customer_id,
  customer_code,
  gender,
  birth_date,
  membership_tier,
  status,
  acquisition_channel,
  marketing_opt_in,
  registered_at,
  created_at,
  updated_at,
  DATE '{{ partition_key }}' as batch_date,
  localtimestamp as ingest_datetime
FROM shop.public.customers
WHERE date(created_at) = DATE '{{ partition_key }}'
   OR date(updated_at) = DATE '{{ partition_key }}';
   
DELETE FROM lakehouse.bronze.customers
WHERE batch_date = DATE '{{ partition_key }}'
  AND ingest_datetime < (SELECT max(ingest_datetime) FROM lakehouse.bronze.customers WHERE batch_date = DATE '{{ partition_key }}');