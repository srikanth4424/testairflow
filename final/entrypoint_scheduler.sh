
#!/bin/bash
# Initialize the Airflow database
airflow db init

# Start Airflow scheduler
exec airflow scheduler
