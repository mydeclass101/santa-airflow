CREATE TABLE IF NOT EXISTS lakehouse.gold.daily_sales (
    order_date      date,
    category_name   varchar,
    membership_tier varchar,
    orders          bigint,
    units           bigint,
    revenue         decimal(18,2),
    built_at        timestamp(6)
);


CREATE OR REPLACE TABLE lakehouse.gold.daily_sales AS
SELECT f.order_date,
       CAST(coalesce(p.parent_category_name, 'unknown') AS varchar)  AS category_name,
       CAST(coalesce(c.membership_tier, 'unknown') AS varchar)    AS membership_tier,
       count(DISTINCT f.order_id)                                 AS orders,
       CAST(sum(f.quantity) AS bigint)                            AS units,
       CAST(sum(f.line_total) AS decimal(18,2))                   AS revenue,     -- sum ได้ decimal(38,2) ตารางเก็บ (18,2)
       CAST(localtimestamp AS timestamp(6))                       AS built_at     -- localtimestamp = timestamp(3)
FROM lakehouse.gold.fct_order_items f
LEFT JOIN lakehouse.gold.dim_products p  ON p.product_id = f.product_id       -- LEFT: หา dim ไม่เจอ ยอดยังไม่หาย
LEFT JOIN lakehouse.gold.dim_customers c ON c.customer_sk = f.customer_sk     -- เวอร์ชันของลูกค้าตอนสั่ง
WHERE f.order_status <> 'cancelled'
  AND f.order_date >= date_trunc('month', DATE '{{ partition_key }}')            -- วันที่ 1 ของเดือน
  AND f.order_date <= DATE '{{ partition_key }}'
GROUP BY 1, 2, 3;
