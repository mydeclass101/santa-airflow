CREATE TABLE IF NOT EXISTS lakehouse.silver.categories (
    category_id        integer,
    category_code      varchar,
    parent_category_id integer,
    name_th            varchar,
    name_en            varchar,
    created_at         timestamp(6),
    silver_updated_at  timestamp(6)
);


CREATE OR REPLACE TABLE lakehouse.silver.categories AS
SELECT
    CAST(category_id AS integer)        AS category_id,
    CAST(category_code AS varchar)      AS category_code,
    CAST(parent_category_id AS integer) AS parent_category_id,
    CAST(name_th AS varchar)            AS name_th,
    CAST(name_en AS varchar)            AS name_en,
    CAST(created_at AS timestamp(6))    AS created_at,
    localtimestamp                      AS silver_updated_at
FROM lakehouse.bronze.categories
WHERE batch_date = DATE '{{ partition_key }}';