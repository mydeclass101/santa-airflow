CREATE TABLE IF NOT EXISTS lakehouse.bronze.orders
WITH (partitioning = ARRAY['batch_date'])
AS SELECT
    order_id,
    order_number,
    customer_id,
    sales_channel,
    status,
    payment_method,
    subtotal_amount,
    discount_amount,
    shipping_fee,
    shipping_discount,
    total_amount,
    ordered_at,
    paid_at,
    cancelled_at,
    created_at,
    updated_at,
    CAST(null as DATE) as batch_date,
    localtimestamp as ingest_datetime
  FROM shop.public.orders
WITH NO DATA; 
  

INSERT INTO lakehouse.bronze.orders
SELECT
  order_id,
  order_number,
  customer_id,
  sales_channel,
  status,
  payment_method,
  subtotal_amount,
  discount_amount,
  shipping_fee,
  shipping_discount,
  total_amount,
  ordered_at,
  paid_at,
  cancelled_at,
  created_at,
  updated_at,
  DATE '{{ partition_key }}' as batch_date,
  localtimestamp as ingest_datetime
FROM shop.public.orders
WHERE date(created_at) = DATE '{{ partition_key }}'
   OR date(updated_at) = DATE '{{ partition_key }}';
   

DELETE FROM lakehouse.bronze.orders
WHERE batch_date = DATE '{{ partition_key }}'
  AND ingest_datetime < (SELECT max(ingest_datetime) FROM lakehouse.bronze.orders WHERE batch_date = DATE '{{ partition_key }}');