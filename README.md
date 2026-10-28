# IoT Telemetry Data Platform

End-to-end **IoT telemetry lakehouse** on Azure.  
Simulates a fleet of connected trucks, ingests data via **batch + streaming**, and processes it through a full **Medallion Architecture** (Bronze → Silver → Gold) using Databricks + Delta Lake.

> 100% synthetic data · Production-oriented patterns · Faceless project

---

## Architecture

```
┌─────────────────────┐     ┌──────────────────────┐
│  Generator (CSV)    │     │  Generator (IoT Hub) │
│  Batch historical   │     │  Continuous messages │
└─────────┬───────────┘     └──────────┬───────────┘
          │                            │
          ▼                            ▼
     ADLS Gen2 (raw)  ◄──── IoT Hub endpoint + route
          │
          ▼
┌─────────────────────────────────────────────────┐
│                 Databricks                      │
│  Bronze (batch)  +  Bronze Streaming (Auto Loader) │
│                     ↓                           │
│              Silver (union + quality)           │
│                     ↓                           │
│         Gold (daily aggregations, partitioned)  │
└─────────────────────────────────────────────────┘
```

**Key components:**
- **Azure IoT Hub** → routes device messages to ADLS `raw` container
- **Azure Data Lake Storage Gen2** (Hierarchical Namespace)
- **Databricks** with Delta Lake (managed tables + time travel)
- **Terraform** for infrastructure as code

---

## Tech Stack

| Layer              | Technology                          |
|--------------------|-------------------------------------|
| Infrastructure     | Terraform + Azure (IoT Hub, ADLS Gen2, Resource Group) |
| Ingestion          | IoT Hub + Auto Loader (`cloudFiles`) |
| Processing         | Databricks + PySpark + Delta Lake   |
| Architecture       | Medallion (Bronze / Silver / Gold)  |
| Orchestration      | Databricks Jobs                     |
| Language           | Python / PySpark                    |

---

## Project Structure

```
├── generator/
│   ├── generate_iot_data_with_issues.py   # Batch CSV generator (dirty data)
│   └── (iot hub sender)                   # Continuous sender to IoT Hub
├── databricks/
│   └── pipelines/
│       ├── 01_Bronze_telemetry.ipynb      # Batch ingestion from ADLS
│       ├── bronze_streaming.ipynb         # Streaming via Auto Loader
│       ├── 02_Silver_Cleansing.ipynb      # Union batch+stream + quality rules
│       └── 03_Gold_Aggregations.ipynb     # Daily business metrics (partitioned)
├── terraform/
│   └── main.tf                            # Full Azure infrastructure
└── README.md
```

---

## Data Flow & Layers

### Bronze
- **Batch**: Reads historical dirty CSV from ADLS
- **Streaming**: Auto Loader from IoT Hub messages (base64 Body → JSON parsing)
- Adds audit columns (`ingest_timestamp`, `_source`)

### Silver
- Unions batch + streaming data
- Deduplication by `event_id` (keeps latest)
- Safe casts for numeric fields
- Quality filters:
  - `event_id` / `device_id` not null
  - `speed_kmh` between 0–200
  - `engine_temp_c` between -50–150
  - `battery_pct` between 0–100

### Gold
- Daily aggregations per `device_id`
- Metrics: `total_events`, `avg_speed_kmh`, `avg_battery_pct`, `max/min_engine_temp_c`
- Partitioned by `report_date` for efficient querying

---

## How to Run

### 1. Infrastructure
```bash
cd terraform
terraform init
terraform apply
```

### 2. Data Generation
- **Batch**: Run the CSV generator and upload to the `raw` container
- **Streaming**: Run the IoT Hub sender script (leave it running to generate live messages)

### 3. Databricks Pipelines
Run the notebooks in order (or use the Databricks Job):

1. `01_Bronze_telemetry.ipynb` (batch)
2. `bronze_streaming.ipynb` (streaming)
3. `02_Silver_Cleansing.ipynb`
4. `03_Gold_Aggregations.ipynb`

**Databricks Job** (all tasks successful):

<!-- Subí tu captura a una carpeta docs/ o a la raíz y actualizá la ruta de abajo -->
<!-- ![Databricks Job Success](./docs/databricks-job-success.png) -->

---

## Key Design Decisions

- **Medallion Architecture** for clear separation of concerns and data quality progression
- **Batch + Streaming union** in Silver so both historical and live data share the same cleaning logic
- **Safe casts** to prevent pipeline failures on dirty data
- **Delta Lake** for ACID transactions, time travel and schema enforcement
- **Terraform** for reproducible infrastructure
- **Partitioning** in Gold for dashboard performance

---

## Results

- Bronze: Raw telemetry (batch + stream) landed as Delta tables
- Silver: Cleaned & deduplicated dataset ready for analytics
- Gold: Business-ready daily summary per device (`gold_device_daily_summary`)

---

## Future Improvements

- Continuous streaming trigger (instead of `availableNow`)
- Watermarking + late-arriving data handling
- Data quality framework (Great Expectations / dbt tests)
- CI/CD for Terraform + notebooks
- Power BI / Grafana dashboard on Gold layer

---

**Built as a hands-on Data Engineering project focused on real Azure IoT + Lakehouse patterns.**
