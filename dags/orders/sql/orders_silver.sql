CREATE TABLE IF NOT EXISTS lakehouse.silver.orders (
    order_id          bigint,
    order_number      varchar,
    customer_id       bigint,
    sales_channel     varchar,
    status            varchar,
    payment_method    varchar,
    subtotal_amount   decimal(12,2),
    discount_amount   decimal(12,2),
    shipping_fee      decimal(12,2),
    shipping_discount decimal(12,2),
    total_amount      decimal(12,2),
    ordered_at        timestamp(6),
    order_date        date,
    paid_at           timestamp(6),
    cancelled_at      timestamp(6),
    created_at        timestamp(6),
    updated_at        timestamp(6),
    silver_updated_at timestamp(6)
);


MERGE INTO lakehouse.silver.orders AS t
USING (
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
        date(ordered_at)  AS order_date,
        paid_at,
        cancelled_at,
        created_at,
        updated_at,
        localtimestamp    AS silver_updated_at
    FROM lakehouse.bronze.orders
    WHERE batch_date = DATE '{{ partition_key }}'
) AS s
ON t.order_id = s.order_id

WHEN MATCHED AND s.updated_at >= t.updated_at THEN UPDATE SET
    order_number = s.order_number, 
    customer_id = s.customer_id, 
    sales_channel = s.sales_channel,
    status = s.status, 
    payment_method = s.payment_method, 
    subtotal_amount = s.subtotal_amount,
    discount_amount = s.discount_amount, 
    shipping_fee = s.shipping_fee,
    shipping_discount = s.shipping_discount, 
    total_amount = s.total_amount, 
    ordered_at = s.ordered_at,
    order_date = s.order_date, 
    paid_at = s.paid_at, 
    cancelled_at = s.cancelled_at,
    created_at = s.created_at,
    updated_at = s.updated_at, 
    silver_updated_at = s.silver_updated_at
    
WHEN NOT MATCHED THEN INSERT VALUES (
    s.order_id, 
    s.order_number, 
    s.customer_id, 
    s.sales_channel, 
    s.status, 
    s.payment_method,
    s.subtotal_amount, 
    s.discount_amount, 
    s.shipping_fee, 
    s.shipping_discount, 
    s.total_amount,
    s.ordered_at, 
    s.order_date, 
    s.paid_at, 
    s.cancelled_at, 
    s.created_at,
    s.updated_at, 
    s.silver_updated_at
)