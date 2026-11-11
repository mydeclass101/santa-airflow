CREATE TABLE IF NOT EXISTS lakehouse.silver.order_items (
    order_item_id     bigint,
    order_id          bigint,
    line_number       integer,
    product_id        integer,
    quantity          integer,
    unit_price        decimal(12,2),
    discount_amount   decimal(12,2),
    line_total        decimal(12,2),
    silver_updated_at timestamp(6)
);


MERGE INTO lakehouse.silver.order_items AS t
USING (
    SELECT
        order_item_id,
        order_id,
        line_number,
        product_id,
        quantity,
        unit_price,
        discount_amount,
        line_total,
        localtimestamp    AS silver_updated_at
    FROM lakehouse.bronze.order_items
    WHERE batch_date = DATE '{{ partition_key }}'
) AS s
ON t.order_item_id = s.order_item_id
WHEN NOT MATCHED THEN INSERT VALUES (
    s.order_item_id, 
    s.order_id, 
    s.line_number, 
    s.product_id, 
    s.quantity, 
    s.unit_price,
    s.discount_amount, 
    s.line_total, 
    s.silver_updated_at
)