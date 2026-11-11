import pendulum

from airflow.sdk import dag, CronPartitionTimetable, Asset, Param

from airflow.providers.standard.operators.empty import EmptyOperator

from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

from email_alerts import email_on_failure


send_failure_email = email_on_failure(email_to="champirom.rames@gmail.com")

BKK = "Asia/Bangkok"

# ปกติ partition_key = today = 2026-11-01
# run_off=-1 partition_key = yesterday = 2026-30-31

@dag(
    schedule=CronPartitionTimetable("0 0 * * *", timezone=BKK, run_offset=-1, key_format='%Y-%m-%d'),
    start_date=pendulum.datetime(2026, 11, 1, tz=BKK),
    default_args={
        "owner" : "claude",
        "retries" : 0,
        "on_failure_callback" : send_failure_email
    },
    tags=['daily', 'customers'],
    params={"full_load": Param(False, type="boolean")},
)
def dim_customers():
  
  ingest_customers = SQLExecuteQueryOperator(
    task_id="ingest_customers",
    conn_id="trino",
    sql="sql/customers_bronze.sql",
    split_statements=True
  )
  
  transform_customers = SQLExecuteQueryOperator(
    task_id="transform_customers",
    conn_id="trino",
    sql="sql/customers_silver.sql",
    split_statements=True
  )
  
  load_to_dim_customers = SQLExecuteQueryOperator(
      task_id="load_to_dim_customers",
      conn_id="trino",
      sql="sql/customers_gold.sql",
      split_statements=True
    )
  
  return_asset = EmptyOperator(
    task_id='return_asset',
    outlets=[Asset('gold.dim_customers')]
  )
  
  
  ingest_customers >> transform_customers >> load_to_dim_customers >> return_asset
     

dim_customers()
