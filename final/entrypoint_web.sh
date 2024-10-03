#!/bin/bash
# Initialize the Airflow database
airflow db init

# Create Airflow admin user
airflow users create \
  --username ${AIRFLOW_ADMIN_USERNAME:-admin} \
  --firstname ${AIRFLOW_ADMIN_FIRSTNAME:-Admin} \
  --lastname ${AIRFLOW_ADMIN_LASTNAME:-User} \
  --role Admin \
  --email ${AIRFLOW_ADMIN_EMAIL:-admin@example.com} \
  --password ${AIRFLOW_ADMIN_PASSWORD:-Airflowtest}

# Start Airflow webserver
exec airflow webserver --port 8080
