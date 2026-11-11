CREATE TABLE IF NOT EXISTS lakehouse.gold.dim_products (
    product_id        integer,
    sku               varchar,
    product_name      varchar,
    category_id       integer,
    category_code      varchar,
    parent_category_id integer,

    parent_category_name varchar,

    category_name        varchar,
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
    built_at          timestamp(6)
);


CREATE OR REPLACE TABLE lakehouse.gold.dim_products AS
SELECT
    p.product_id,
    p.sku,
    p.product_name,
    p.category_id,

    c.category_code,
    c.parent_category_id,
    coalesce(main_c.name_en , c.name_en ) AS parent_category_name,
    c.name_en AS category_name,
    
    p.brand_id,
    p.supplier_id,
    p.unit_price,
    p.cost_price,
    p.weight_grams,
    p.status,
    p.launched_at,
    p.discontinued_at,
    p.created_at,
    p.updated_at,
    localtimestamp AS built_at
FROM lakehouse.silver.products p
LEFT JOIN lakehouse.silver.categories c ON p.category_id = c.category_id
LEFT JOIN lakehouse.silver.categories main_c on c.parent_category_id = main_c.category_id;
