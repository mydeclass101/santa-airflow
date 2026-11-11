import pendulum

from airflow.sdk import dag, PartitionedAssetTimetable, Asset

from airflow.providers.standard.operators.empty import EmptyOperator

from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

from airflow.providers.smtp.operators.smtp import EmailOperator

from email_alerts import email_on_failure


send_failure_email = email_on_failure(email_to="champirom.rames@gmail.com")
REPORT_EMAIL_TO = "champirom.rames@gmail.com"
BKK = "Asia/Bangkok"


@dag(
    schedule=PartitionedAssetTimetable(
        assets=Asset('gold.fct_order_items')
        ),
    start_date=pendulum.datetime(2026, 11, 11, tz=BKK),
    default_args={
        "owner" : "claude",
        "retries" : 0,
        "on_failure_callback" : send_failure_email
    },
    tags=['asset_trigger', 'report', 'daily'],
)
def report_daily_sales():
  
  
  build_daily_sales = SQLExecuteQueryOperator(
    task_id="build_daily_sales",
    conn_id="trino",
    sql="sql/report_daily_sales.sql",
    split_statements=True
  )
  
  # ดึงข้อมูลก้อนเดียวกับที่ build_daily_sales เพิ่งเขียนลงตาราง (MTD ถึง partition_key)
  # ผลลัพธ์จะถูกเก็บใน XCom ให้ task ส่งอีเมลเอาไปวาดเป็นตาราง HTML
  fetch_daily_sales = SQLExecuteQueryOperator(
    task_id="fetch_daily_sales",
    conn_id="trino",
    sql="""
        SELECT order_date,
               category_name,
               membership_tier,
               orders,
               units,
               revenue
        FROM lakehouse.gold.daily_sales
        WHERE order_date >= date_trunc('month', DATE '{{ partition_key }}')
          AND order_date <= DATE '{{ partition_key }}'
        ORDER BY order_date, revenue DESC, category_name, membership_tier
    """,
    split_statements=False
  )
  
  send_daily_sales_email = EmailOperator(
    task_id="send_daily_sales_email",
    to=[REPORT_EMAIL_TO],
    subject="[REPORT] Daily Sales | 1 - {{ partition_key }}",
    html_content="""
    {% set rows = ti.xcom_pull(task_ids='fetch_daily_sales') or [] %}
    <div style="margin:0;padding:30px 12px;background:#f1f5f9;
                font-family:Arial,Helvetica,sans-serif;">

    <table role="presentation" cellpadding="0" cellspacing="0"
            style="width:100%;max-width:820px;margin:auto;
                    background:#ffffff;border-radius:12px;
                    border:1px solid #e2e8f0;">

        <!-- HEADER -->
        <tr>
        <td style="padding:28px;background:#1d4ed8;color:#ffffff;">
            <div style="font-size:13px;font-weight:bold;
                        letter-spacing:2px;">
            APACHE AIRFLOW
            </div>
            <h1 style="margin:14px 0 6px;font-size:26px;">
            Daily Sales Report
            </h1>
            <p style="margin:0;color:#dbeafe;font-size:14px;">
            1 - {{ partition_key }} | {{ rows | length }} rows
            </p>
        </td>
        </tr>

        <!-- SUMMARY -->
        <tr>
        <td style="padding:24px 28px 0;">
            <table role="presentation" cellpadding="0" cellspacing="0"
                style="width:100%;font-size:14px;border-collapse:collapse;">
            <tr>
                <td style="padding:12px 14px;background:#f8fafc;border:1px solid #e2e8f0;">
                <div style="color:#64748b;font-size:12px;">Orders</div>
                <b style="font-size:18px;color:#0f172a;">
                {{ '{:,}'.format(rows | map(attribute=3) | sum) if rows else 0 }}
                </b>
                </td>
                <td style="padding:12px 14px;background:#f8fafc;border:1px solid #e2e8f0;">
                <div style="color:#64748b;font-size:12px;">Units</div>
                <b style="font-size:18px;color:#0f172a;">
                {{ '{:,}'.format(rows | map(attribute=4) | sum) if rows else 0 }}
                </b>
                </td>
                <td style="padding:12px 14px;background:#f8fafc;border:1px solid #e2e8f0;">
                <div style="color:#64748b;font-size:12px;">Revenue</div>
                <b style="font-size:18px;color:#0f172a;">
                {{ '{:,.2f}'.format(rows | map(attribute=5) | sum) if rows else '0.00' }}
                </b>
                </td>
            </tr>
            </table>
        </td>
        </tr>

        <!-- TABLE -->
        <tr>
        <td style="padding:24px 28px 28px;">
            {% if rows %}
            <table role="presentation" cellpadding="9" cellspacing="0"
                style="width:100%;font-size:13px;
                        border-collapse:collapse;">
            <tr style="background:#1e293b;color:#ffffff;
                        text-align:left;">
                <th style="padding:10px;">Date</th>
                <th style="padding:10px;">Category</th>
                <th style="padding:10px;">Membership</th>
                <th style="padding:10px;text-align:right;">Orders</th>
                <th style="padding:10px;text-align:right;">Units</th>
                <th style="padding:10px;text-align:right;">Revenue</th>
            </tr>
            {% for row in rows %}
            <tr style="background:{{ '#ffffff' if loop.index is odd else '#f8fafc' }};
                        border-bottom:1px solid #e2e8f0;">
                <td style="padding:9px 10px;">{{ row[0] }}</td>
                <td style="padding:9px 10px;">{{ row[1] | e }}</td>
                <td style="padding:9px 10px;">{{ row[2] | e }}</td>
                <td style="padding:9px 10px;text-align:right;">
                {{ '{:,}'.format(row[3]) }}</td>
                <td style="padding:9px 10px;text-align:right;">
                {{ '{:,}'.format(row[4]) }}</td>
                <td style="padding:9px 10px;text-align:right;">
                {{ '{:,.2f}'.format(row[5]) }}</td>
            </tr>
            {% endfor %}
            </table>
            {% else %}
            <p style="padding:24px;background:#f8fafc;border:1px solid #e2e8f0;
                    border-radius:8px;color:#64748b;font-size:14px;
                    text-align:center;margin:0;">
                No sales data for this period.
            </p>
            {% endif %}

            <p style="margin:24px 0 0;font-size:12px;color:#94a3b8;">
            Generated by DAG
            <b>{{ dag.dag_id }}</b> | run <b>{{ run_id }}</b>
            </p>
        </td>
        </tr>
    </table>
    </div>
    """,
  )
  

  build_daily_sales >> fetch_daily_sales >> send_daily_sales_email

report_daily_sales()
