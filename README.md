# testairflow
1. Install Docker and Docker Compose
Make sure Docker and Docker Compose are installed on your system. You can check the installation by running the following commands:

bash
Copy code
docker --version
docker-compose --version
If they are not installed, follow the official instructions for Docker and Docker Compose.

2. Create a Docker Compose File for Airflow
Create a docker-compose.yaml file in a new directory. This file will define the services for Airflow (Scheduler, Web Server, Worker, and PostgreSQL metadata database).

yaml
Copy code
version: '3'
services:
  postgres:
    image: postgres:13
    environment:
      POSTGRES_USER: airflow
      POSTGRES_PASSWORD: airflow
      POSTGRES_DB: airflow
    volumes:
      - postgres_data:/var/lib/postgresql/data

  webserver:
    image: apache/airflow:2.5.0
    environment:
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__CORE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres/airflow
      AIRFLOW__CORE__FERNET_KEY: 'YOUR_FERNET_KEY'
      AIRFLOW__CORE__LOAD_EXAMPLES: 'true'
    depends_on:
      - postgres
    ports:
      - "8080:8080"
    command: webserver

  scheduler:
    image: apache/airflow:2.5.0
    environment:
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__CORE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres/airflow
      AIRFLOW__CORE__FERNET_KEY: 'YOUR_FERNET_KEY'
      AIRFLOW__CORE__LOAD_EXAMPLES: 'true'
    depends_on:
      - postgres
    command: scheduler

  worker:
    image: apache/airflow:2.5.0
    environment:
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__CORE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres/airflow
      AIRFLOW__CORE__FERNET_KEY: 'YOUR_FERNET_KEY'
    depends_on:
      - postgres
    command: worker

volumes:
  postgres_data:
3. Generate a Fernet Key
Airflow requires a Fernet key for encrypting sensitive data like connections. You can generate it using Python:

bash
Copy code
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
Replace 'YOUR_FERNET_KEY' in the docker-compose.yaml file with the generated key.

4. Initialize Airflow Metadata Database
Before starting Airflow, you need to initialize the metadata database. Run the following command to initialize the database:

bash
Copy code
docker-compose up airflow-init
This will create the necessary tables in the PostgreSQL database for Airflow to store its metadata.

5. Start Airflow Services
Once the database is initialized, you can start the Airflow services using Docker Compose:

bash
Copy code
docker-compose up -d
This will start the Airflow web server, scheduler, and worker, along with the PostgreSQL database.

6. Access the Airflow Web UI
After the services are up and running, you can access the Airflow web UI by navigating to http://localhost:8080 in your browser.

The default login credentials are:

Username: airflow
Password: airflow
