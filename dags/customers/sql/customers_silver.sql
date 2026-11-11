CREATE TABLE IF NOT EXISTS lakehouse.silver.customers (
    customer_id bigint,
    customer_code varchar,
    gender varchar,
    birth_date date,
    membership_tier varchar,
    status varchar,
    acquisition_channel varchar,
    acquisition_type varchar,
    marketing_opt_in boolean,
    registered_at timestamp(6),
    created_at timestamp(6),
    updated_at timestamp(6),
    silver_updated_at timestamp(6)
);


MERGE INTO lakehouse.silver.customers AS t
USING (
    SELECT
        customer_id,
        customer_code,

        CASE WHEN gender = 'M' THEN 'Male'
            WHEN gender = 'F' THEN 'Female'
            ELSE NULL
        END AS gender,

        birth_date,
        membership_tier,
        status,
        acquisition_channel,

        CASE WHEN acquisition_channel IN ('organic', 'referal', 'tiktok') THEN 'Unpaid'
            WHEN acquisition_channel IN ('googld_ads', 'facebook_ads') THEN 'Paid'
            WHEN acquisition_channel = 'line_oa' THEN 'Owned'
            ELSE 'Other'
        END AS acquisition_type,

        marketing_opt_in,
        registered_at,
        created_at,
        updated_at,
        localtimestamp AS silver_updated_at
    FROM lakehouse.bronze.customers
    WHERE batch_date = DATE '{{ partition_key }}'
) AS s
ON t.customer_id = s.customer_id
WHEN MATCHED AND s.updated_at >= t.updated_at THEN UPDATE SET
    customer_code = s.customer_code,
    gender = s.gender,
    birth_date = s.birth_date,
    membership_tier = s.membership_tier,
    status = s.status,
    acquisition_channel = s.acquisition_channel,
    acquisition_type = s.acquisition_type,
    marketing_opt_in = s.marketing_opt_in,
    registered_at = s.registered_at,
    created_at = s.created_at,
    updated_at = s.updated_at,
    silver_updated_at = s.silver_updated_at
WHEN NOT MATCHED THEN INSERT VALUES (
    s.customer_id,
    s.customer_code,
    s.gender,
    s.birth_date,
    s.membership_tier,
    s.status,
    s.acquisition_channel,
    s.acquisition_type,
    s.marketing_opt_in,
    s.registered_at,
    s.created_at,
    s.updated_at,
    s.silver_updated_at
)