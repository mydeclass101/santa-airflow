CREATE TABLE IF NOT EXISTS lakehouse.silver.products (
    product_id        integer,
    sku               varchar,
    product_name      varchar,
    category_id       integer,
    brand_id          integer,
    supplier_id       integer,
    unit_price        decimal(12,2),
    cost_price        decimal(12,2),
    weight_grams      integer,
    status            varchar,
    launched_at       timestamp(6),
    discontinued_at   timestamp(6),
    created_at        timestamp(6),
    updated_at        timestamp(6),
    silver_updated_at timestamp(6)
);
    

CREATE OR REPLACE TABLE lakehouse.silver.products AS
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
    localtimestamp AS silver_updated_at
FROM lakehouse.bronze.products
WHERE batch_date = DATE '{{ partition_key }}'