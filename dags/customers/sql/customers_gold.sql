-- dim_customers SCD TYPE 2

CREATE TABLE IF NOT EXISTS lakehouse.gold.dim_customers (
    customer_sk varchar,
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
    valid_from timestamp(6),
    valid_to timestamp(6),
    is_current boolean,
    build_at timestamp(6)
);



MERGE INTO lakehouse.gold.dim_customers AS t
USING (
    SELECT
        customer_id,
        customer_code,
        gender,
        birth_date,
        membership_tier,
        status,
        acquisition_channel,
        acquisition_type,
        marketing_opt_in,
        registered_at,
        created_at,
        updated_at,
        silver_updated_at
    FROM lakehouse.silver.customers
    WHERE silver_updated_at >= (SELECT coalesce(max(build_at), TIMESTAMP '1900-01-01') FROM lakehouse.gold.dim_customers)
) AS s
ON t.customer_id = s.customer_id AND t.is_current
WHEN MATCHED AND (   t.customer_code       IS DISTINCT FROM s.customer_code
                  OR t.gender              IS DISTINCT FROM s.gender
                  OR t.birth_date          IS DISTINCT FROM s.birth_date
                  OR t.membership_tier     IS DISTINCT FROM s.membership_tier
                  OR t.status              IS DISTINCT FROM s.status
                  OR t.acquisition_channel IS DISTINCT FROM s.acquisition_channel
                  OR t.acquisition_type    IS DISTINCT FROM s.acquisition_type
                  OR t.marketing_opt_in    IS DISTINCT FROM s.marketing_opt_in
                  OR t.registered_at       IS DISTINCT FROM s.registered_at
                  )
THEN UPDATE SET is_current = false, valid_to = s.updated_at;


INSERT INTO lakehouse.gold.dim_customers
-- CTE (WITH)
WITH changed AS (
    SELECT
        customer_id,
        customer_code,
        gender,
        birth_date,
        membership_tier,
        status,
        acquisition_channel,
        acquisition_type,
        marketing_opt_in,
        registered_at,
        created_at,
        updated_at,
        silver_updated_at
    FROM lakehouse.silver.customers AS s
    WHERE silver_updated_at >= (SELECT coalesce(max(build_at), TIMESTAMP '1900-01-01') FROM lakehouse.gold.dim_customers)
        AND NOT EXISTS (SELECT 1 FROM lakehouse.gold.dim_customers AS t WHERE t.customer_id = s.customer_id AND t.is_current)
), 
    last_closed AS (
    SELECT customer_id, max(valid_to) AS closed_at
    FROM lakehouse.gold.dim_customers
    WHERE NOT is_current
    GROUP BY 1
),
    new_versions AS (
    SELECT 
        c.customer_id,
        c.customer_code,
        c.gender,
        c.birth_date,
        c.membership_tier,
        c.status,
        c.acquisition_channel,
        c.acquisition_type,
        c.marketing_opt_in,
        c.registered_at,
        c.created_at,
        coalesce(l.closed_at, c.registered_at) AS valid_from
    FROM changed AS c
    LEFT JOIN last_closed AS l 
    ON c.customer_id = l.customer_id
)

SELECT

    to_hex(md5(to_utf8(CAST(customer_id AS varchar) || '|' || CAST(valid_from AS varchar)))) AS customer_sk,
    customer_id,
    customer_code,
    gender,
    birth_date,
    membership_tier,
    status,
    acquisition_channel,
    acquisition_type,
    marketing_opt_in,
    registered_at,
    created_at,
    valid_from,
    TIMESTAMP '9999-12-31 00:00:00' AS valid_to,
    true AS is_current,
    localtimestamp AS build_at

FROM new_versions

