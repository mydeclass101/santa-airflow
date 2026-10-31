FROM apache/airflow:3.3.2
RUN pip install --no-cache-dir \
    "apache-airflow-providers-trino==6.7.1" \
    "apache-airflow-providers-amazon==9.38.0"