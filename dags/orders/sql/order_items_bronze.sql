CREATE TABLE IF NOT EXISTS lakehouse.bronze.order_items
WITH (partitioning = ARRAY['batch_date'])
AS SELECT
    order_item_id,
    order_id,
    line_number,
    product_id,
    quantity,
    unit_price,
    discount_amount,
    line_total,
    CAST(null as DATE) as batch_date,
    localtimestamp as ingest_datetime
  FROM shop.public.order_items
WITH NO DATA; 
  

INSERT INTO lakehouse.bronze.order_items
SELECT
  order_item_id,
  order_id,
  line_number,
  product_id,
  quantity,
  unit_price,
  discount_amount,
  line_total,
  DATE '{{ partition_key }}' as batch_date,
  localtimestamp as ingest_datetime
FROM shop.public.order_items
WHERE order_id IN (
    SELECT 
        order_id 
    FROM shop.public.orders
    WHERE date(created_at) = DATE '{{ partition_key }}'
        OR date(updated_at) = DATE '{{ partition_key }}'
);
   

DELETE FROM lakehouse.bronze.order_items
WHERE batch_date = DATE '{{ partition_key }}'
  AND ingest_datetime < (SELECT max(ingest_datetime) FROM lakehouse.bronze.order_items WHERE batch_date = DATE '{{ partition_key }}');