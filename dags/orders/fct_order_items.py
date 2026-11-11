import pendulum

from airflow.sdk import dag, PartitionedAssetTimetable, Asset

from airflow.providers.standard.operators.empty import EmptyOperator

from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

from email_alerts import email_on_failure


send_failure_email = email_on_failure(email_to="champirom.rames@gmail.com")
BKK = "Asia/Bangkok"


@dag(
    schedule=PartitionedAssetTimetable(
        assets=Asset('gold.dim_products') & Asset('gold.dim_customers')
        ),
    start_date=pendulum.datetime(2026, 11, 5, tz=BKK),
    default_args={
        "owner" : "claude",
        "retries" : 0,
        "on_failure_callback" : send_failure_email
    },
    tags=['asset_trigger', 'orders'],
)
def fct_order_items():
  
  
  ingest_orders = SQLExecuteQueryOperator(
    task_id="ingest_orders",
    conn_id="trino",
    sql="sql/orders_bronze.sql",
    split_statements=True
  )
  
  
  transform_orders = SQLExecuteQueryOperator(
    task_id="transform_orders",
    conn_id="trino",
    sql="sql/orders_silver.sql",
    split_statements=True
  )
  
  
  ingest_order_items = SQLExecuteQueryOperator(
      task_id="ingest_order_items",
      conn_id="trino",
      sql="sql/order_items_bronze.sql",
      split_statements=True
    )
    
    
  transform_order_items = SQLExecuteQueryOperator(
    task_id="transform_order_items",
    conn_id="trino",
    sql="sql/order_items_silver.sql",
    split_statements=True
  )
  
  
  load_to_fct_order_items = SQLExecuteQueryOperator(
        task_id="load_to_fct_order_items",
        conn_id="trino",
        sql="sql/order_items_gold.sql",
        split_statements=True
      )
  
  
  return_asset = EmptyOperator(
      task_id='return_asset',
      outlets=[Asset('gold.fct_order_items')]
    )
  

  ingest_orders >> transform_orders 
  ingest_order_items >> transform_order_items
  
  [transform_orders, transform_order_items] >> load_to_fct_order_items >> return_asset


fct_order_items()
