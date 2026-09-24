# IoT Telemetry Data Platform - Medallion Lakehouse

End-to-end IoT data pipeline simulating a fleet of connected trucks. Built with PySpark, Delta Lake and Databricks following the Medallion Architecture (Bronze / Silver / Gold).

> Faceless project - no real truck data, 100% synthetic but production-ready.

### Architecture

`Generator (Python) -> GitHub Raw (CSV) -> Databricks Lakehouse`

*   **Bronze:** Raw ingestion via pandas bridge (Serverless pattern) + audit columns (`ingest_timestamp`, `_source`)
*   **Silver:** Deduplication (Window by `event_id`) + Safe Cast + Quality filters
*   **Gold:** Daily business aggregation per device

### Tech Stack

*   Databricks Serverless (Shared Access)
*   PySpark + Delta Lake (Time Travel, Managed Tables)
*   Python (Data Generator)
*   Git + Git Folder integration

### Project Structure

├── generator/
│ └── generator.py # Generates dirty telemetry (10k rows with nulls, dups, out-of-range)
├── databricks/
│ └── pipelines/
│ ├── 01_Bronze_Ingestion.ipynb # DEV: GitHub Raw | PROD: S3 + Auto Loader (commented)
│ ├── 02_Silver_Cleaning.ipynb # Window dedup + safe cast so it doesn't break
│ └── 03_Gold_Aggregation.ipynb # Daily summary ready for BI
└── data/raw/ # (gitignored) dirty csv


### Data Quality Rules (Silver)

*   `event_id`, `device_id` IS NOT NULL
*   `speed_kmh`: 0 - 200
*   `engine_temp_c`: -50 - 150
*   `battery_pct`: 0 - 100 (with safe cast: 'hola' -> null -> filtered, so it doesn't break prod)
*   Deduplication by `event_id` keeping latest `ingest_timestamp`

### Gold Metrics

`gold_device_daily_summary` - one row per `device_id` per day:

*   `total_events`, `avg_speed_kmh`, `avg_battery_pct`, `max/min_engine_temp_c`, `gold_processed_at`

### Results

*   **Bronze:** 10,000 rows raw -> Delta Table with `DESCRIBE HISTORY`
*   **Silver:** ~9,200+ rows retained (quality report in notebook)
*   **Gold:** Aggregated, ready for dashboard

### How to Run

1.  Clone this repo as a Git Folder in Databricks
2.  Run `01 -> 02 -> 03`
3.  Check `SELECT * FROM gold_device_daily_summary`

I'll use this Gold table for the Power BI dashboard.

### Next Steps

*   Move raw source to Unity Catalog Volume `/Volumes/...` + Terraform infra (`/infra`) - ready for prod
*   Add Auto Loader for streaming ingestion from `s3://lynxion-iot-raw-prod/`
*   Add Great Expectations for data quality
*   Connect Gold to Power BI / Grafana

Built as a learning path to Data Engineering.
