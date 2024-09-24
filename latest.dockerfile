latest

# .env file

# Airflow Home Directory in Container
AIRFLOW_HOME=/opt/airflow

# PostgreSQL Database Connection
POSTGRES_USER=airflow
POSTGRES_PASSWORD=airflow
POSTGRES_DB=airflow_db
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# SQLAlchemy Connection String
SQL_ALCHEMY_CONN=postgresql+psycopg2://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}

# Host Paths for DAGs and Logs (absolute paths)
HOST_DAGS_PATH=/var/airflow/dags
HOST_LOGS_PATH=/var/airflow/logs


-----------------------


version: '3'
services:
  # PostgreSQL service
  postgres:
    image: postgres:13
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - airflow_network

  # Airflow webserver service
  airflow-webserver:
    build:
      context: .
      dockerfile: Dockerfile
    env_file:
      - .env  # Use the common .env file
    environment:
      AIRFLOW_ROLE: webserver  # Role is defined directly here
    ports:
      - "8080:8080"
    volumes:
      - ${HOST_LOGS_PATH}:/opt/airflow/logs
      - ${HOST_DAGS_PATH}:/opt/airflow/dags
    depends_on:
      - postgres
    networks:
      - airflow_network

  # Airflow scheduler service
  airflow-scheduler:
    build:
      context: .
      dockerfile: Dockerfile
    env_file:
      - .env  # Use the common .env file
    environment:
      AIRFLOW_ROLE: scheduler  # Role is defined directly here
    volumes:
      - ${HOST_LOGS_PATH}:/opt/airflow/logs
      - ${HOST_DAGS_PATH}:/opt/airflow/dags
    depends_on:
      - postgres
    networks:
      - airflow_network

volumes:
  postgres_data:
    driver: local

networks:
  airflow_network:
    driver: bridge


-----------------------

# Use Ubuntu as the base image
FROM ubuntu:20.04

# Set environment variables needed at build time
ENV AIRFLOW_HOME=/opt/airflow

# Set the default shell to bash and disable interactive prompts for apt-get
SHELL ["/bin/bash", "-c"]
ARG DEBIAN_FRONTEND=noninteractive
ARG AIRFLOW_HOME
ARG SQL_ALCHEMY_CONN

# Set environment variables from build args
ENV AIRFLOW_HOME=${AIRFLOW_HOME}
ENV SQL_ALCHEMY_CONN=${SQL_ALCHEMY_CONN}

# Rest of your Dockerfile...
#export $(cat .env | xargs) && docker build --build-arg AIRFLOW_HOME --build-arg SQL_ALCHEMY_CONN -t airflow-latest .

# Update Ubuntu and install necessary packages
RUN apt-get update && apt-get install -y \
    python3.8 \
    python3.8-venv \
    python3.8-dev \
    postgresql-client \
    build-essential \
    vim \
    curl \
    netcat

# Create the Airflow home directory
RUN mkdir -p $AIRFLOW_HOME

# Create a virtual environment for Airflow
RUN python3 -m venv $AIRFLOW_HOME/venv

# Activate the virtual environment and upgrade pip using the specified index URL
RUN source $AIRFLOW_HOME/venv/bin/activate && \
    pip install --upgrade pip --index-url https://vagrant:vagrant@gbmt-nexus.prd.fx.gbm.cloud.uk.hsbc/repository/pypi-group/simple --trusted-host efx-nexus.systems.uk.hsbc:8084

# Install Apache Airflow and required providers
RUN source $AIRFLOW_HOME/venv/bin/activate && \
    pip install apache-airflow[postgres,celery,redis,crypto,ssh]==2.8.0 --index-url https://vagrant:vagrant@gbmt-nexus.prd.fx.gbm.cloud.uk.hsbc/repository/pypi-group/simple --trusted-host efx-nexus.systems.uk.hsbc:8084

# Install psycopg2 for PostgreSQL connection
RUN source $AIRFLOW_HOME/venv/bin/activate && \
    pip install apache-airflow[psycopg2]==2.8.0 --index-url https://vagrant:vagrant@gbmt-nexus.prd.fx.gbm.cloud.uk.hsbc/repository/pypi-group/simple --trusted-host efx-nexus.systems.uk.hsbc:8084

# Install the Airflow Spark provider
RUN source $AIRFLOW_HOME/venv/bin/activate && \
    pip install apache-airflow-providers-apache-spark==2.1.3 --index-url https://vagrant:vagrant@gbmt-nexus.prd.fx.gbm.cloud.uk.hsbc/repository/pypi-group/simple --trusted-host efx-nexus.systems.uk.hsbc:8084 --cache-dir=/opt/airflow/cache/

# Expose the necessary Airflow ports (8080 for webserver)
EXPOSE 8080

# Copy the entrypoint script to manage starting the services
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]


-----------------------
entrypoint.sh

#!/bin/bash

# Activate the virtual environment
source /opt/airflow/venv/bin/activate

# Update the SQLAlchemy connection string based on environment variables
sed -i "s#sql_alchemy_conn = .*#sql_alchemy_conn = $SQL_ALCHEMY_CONN#g" $AIRFLOW_HOME/airflow.cfg

# Check the role and start the appropriate service
if [ "$AIRFLOW_ROLE" = "webserver" ]; then
    echo "Starting Airflow Webserver..."
    exec airflow webserver --port 8080
elif [ "$AIRFLOW_ROLE" = "scheduler" ]; then
    echo "Starting Airflow Scheduler..."
    exec airflow scheduler
else
    echo "No valid AIRFLOW_ROLE specified, exiting."
    exit 1
fi


-----------------------
#airflow.cfg
[core]
executor = LocalExecutor
dags_folder = ${AIRFLOW_HOME}/dags
base_log_folder = ${AIRFLOW_HOME}/logs
airflow_home = ${AIRFLOW_HOME}

[database]
# Moved from [core] section
sql_alchemy_conn = ${SQL_ALCHEMY_CONN}

[webserver]
web_server_port = 8080

[logging]
base_log_folder = ${AIRFLOW_HOME}/logs
remote_logging = False

[scheduler]
scheduler_heartbeat_sec = 5
max_threads = 2


