import pendulum

from airflow.sdk import dag, CronPartitionTimetable, Asset

from airflow.providers.standard.operators.empty import EmptyOperator

from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

from email_alerts import email_on_failure


send_failure_email = email_on_failure(email_to="champirom.rames@gmail.com")
BKK = "Asia/Bangkok"

# ปกติ partition_key = today = 2026-11-01
# run_off=-1 partition_key = yesterday = 2026-30-31

@dag(
    schedule=CronPartitionTimetable("0 0 * * *", timezone=BKK, run_offset=-1, key_format='%Y-%m-%d'),
    start_date=pendulum.datetime(2026, 11, 5, tz=BKK),
    default_args={
        "owner" : "claude",
        "retries" : 0,
        "on_failure_callback" : send_failure_email
    },
    tags=['daily', 'products'],
)
def dim_products():
  
  ingest_products = SQLExecuteQueryOperator(
    task_id="ingest_products",
    conn_id="trino",
    sql="sql/products_bronze.sql",
    split_statements=True
  )
  
  transform_products = SQLExecuteQueryOperator(
    task_id="transform_products",
    conn_id="trino",
    sql="sql/products_silver.sql",
    split_statements=True
  )
  
  ingest_category = SQLExecuteQueryOperator(
      task_id="ingest_category",
      conn_id="trino",
      sql="sql/category_bronze.sql",
      split_statements=True
    )
    
  transform_category = SQLExecuteQueryOperator(
    task_id="transform_category",
    conn_id="trino",
    sql="sql/category_silver.sql",
    split_statements=True
  )
  
  load_to_dim_products = SQLExecuteQueryOperator(
      task_id="load_to_dim_products",
      conn_id="trino",
      sql="sql/products_gold.sql",
      split_statements=True,
    )
  
  return_asset = EmptyOperator(
    task_id='return_asset',
    outlets=[Asset('gold.dim_products')]
  )
  
  
  ingest_products >> transform_products 
  ingest_category >> transform_category
  
  [transform_products, transform_category] >> load_to_dim_products >> return_asset


dim_products()
