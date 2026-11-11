-- fct_order_items SCD TYPE 2

CREATE TABLE IF NOT EXISTS lakehouse.gold.fct_order_items (
    order_item_id bigint, order_id bigint, order_date date, ordered_at timestamp(6),
    customer_id bigint, customer_sk varchar, product_id integer,
    sales_channel varchar, payment_method varchar, order_status varchar,
    quantity integer, unit_price decimal(12,2), discount_amount decimal(12,2), line_total decimal(12,2),
    built_at timestamp(6)
);


MERGE INTO lakehouse.gold.fct_order_items AS t
USING (
    SELECT i.order_item_id, i.order_id, o.order_date, o.ordered_at, o.customer_id,
           d.customer_sk,
           i.product_id, o.sales_channel, o.payment_method, o.status AS order_status,
           i.quantity, i.unit_price, i.discount_amount, i.line_total,
           localtimestamp AS built_at
    FROM lakehouse.silver.order_items i
    JOIN lakehouse.silver.orders o ON o.order_id = i.order_id
    LEFT JOIN lakehouse.gold.dim_customers d                 
           ON d.customer_id = o.customer_id
          AND o.ordered_at >= d.valid_from
          AND o.ordered_at <  d.valid_to
    WHERE o.silver_updated_at >= (SELECT coalesce(max(built_at), TIMESTAMP '1900-01-01') FROM lakehouse.gold.fct_order_items)
       OR i.silver_updated_at >= (SELECT coalesce(max(built_at), TIMESTAMP '1900-01-01') FROM lakehouse.gold.fct_order_items)
) AS s
ON t.order_item_id = s.order_item_id 
WHEN MATCHED THEN UPDATE SET
    order_id = s.order_id, order_date = s.order_date, ordered_at = s.ordered_at, customer_id = s.customer_id,
    customer_sk = s.customer_sk, product_id = s.product_id, sales_channel = s.sales_channel,
    payment_method = s.payment_method, order_status = s.order_status, quantity = s.quantity,
    unit_price = s.unit_price, discount_amount = s.discount_amount, line_total = s.line_total, built_at = s.built_at
WHEN NOT MATCHED THEN INSERT VALUES (
    s.order_item_id, s.order_id, s.order_date, s.ordered_at, s.customer_id, s.customer_sk, s.product_id,
    s.sales_channel, s.payment_method, s.order_status, s.quantity, s.unit_price, s.discount_amount, s.line_total,
    s.built_at);
