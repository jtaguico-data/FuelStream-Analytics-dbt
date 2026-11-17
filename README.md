# FuelStream-Analytics: Enterprise-Grade Medallion Pipeline with dbt Cloud

## 🎯 Project Goal
The core business objective of this project is to transform a massive, production-scale dataset of over **67 million raw consumer transactions (~8 GB)** and a reference catalog of **2 million customers** into an optimized analytical data warehouse. 

By leveraging **dbt Cloud** and **Google BigQuery**, I implemented a Medallion Architecture (Bronze -> Silver -> Gold) to eliminate data anomalies, ensure customer referential integrity, and deliver analytical models optimized to evaluate customer loyalty, track monthly consumption volume, and segment demographic behavior across the service station network.

Unlike my sister project built on Databricks (which utilized a 1.5% stratified sample due to computational limits on the free tier), **this dbt pipeline processes 100% of the 67 million rows** directly inside BigQuery, capitalizing on modern ELT (Extract-Load-Transform) practices and zero-redundancy storage techniques.

---

## 🏗️ Project Architecture & Medallion Strategy

This pipeline is engineered to ensure data quality and scalability through clear separation of concerns:

- **Bronze Layer (`staging`)**: *[Completed]* Acting as the ingestion ledger. I mapped raw tables via dbt Sources, applied strict architectural standards (lowercase formatting, explicit aliases in English, and date-time parsing), and enforced governance by dropping PII (Personally Identifiable Information) columns early.
- **Silver Layer (`intermediate`)**: *[Completed]* Handles entity resolution across fragmented customer catalogs, enforces strict referential integrity across 67M+ transactions, and filters out unmapped records.
- **Gold Layer (`marts`)**: *[In Progress]* Dimensional modeling designed for high-performance consumption in Looker Studio / Power BI.

---

## 🥉 Bronze Layer (Staging) Reference

I mapped and standardized the raw BigQuery infrastructure into three modular, storage-efficient dbt views:

- `stg_transactions`: Streamlines the core transaction ledger, mapping physical channels (e.g., POS codes), operational timestamps, and excluding sensitive card identifiers.
- `stg_clients_01`: Standardizes the primary consumer demographic segment.
- `stg_clients_02`: Standardizes the secondary consumer segment, parsing string dates into native `DATE` types and utilizing explicit null injections to maintain structural symmetry with segment 01.

### 🛡️ Governance & PII Controls
To ensure enterprise-grade compliance and safely present this project in a public portfolio, columns containing sensitive personal data (such as `names`, `last_names`, `emails`, and physical `card_numbers`) are explicitly filtered out at this layer, preserving only the analytical attributes (`gender`, `birth_date`, `member_status`, `account_type`).

---

## 🥈 Silver Layer (Intermediate) Reference

I consolidated the staging views into two authoritative business entities:

- `int_clients`: Unified master catalog of unique customers, deduplicated and enriched via source prioritization.
- `int_transactions`: Referentially validated transaction ledger ready for dimensional aggregation.

## 🔍 Data Quality Audit & Business Rules

Before building the analytical marts, I performed a rigorous data profiling and referential integrity audit across the 67M+ transactions and the fragmented customer tables to establish clear business rules for the Silver layer (`intermediate`):

### 1. Customer Entity Resolution (`int_clients`)
- **Cross-Source Overlap:** Profiling revealed that `clients_01` and `clients_02` share **2,105,435 overlapping customer IDs** (roughly 99% of the secondary table), alongside **3 exact duplicate records** within `clients_02`.
- **Resolution Rule:** I implemented a deduplication strategy using `SELECT DISTINCT` on the secondary source followed by a window function (`ROW_NUMBER()`) over a unified ledger, strictly prioritizing records from `clients_01` due to its richer attribute schema (`updated_at`, `email_status`, `is_domain_valid`) to guarantee a single, authoritative record per `person_id`.

### 2. Referential Integrity & Orphan Filtering (`int_transactions`)
- **Orphan Audit:** Cross-referencing the 67M+ transaction ledger against the unified `int_clients` master table identified **5,489 orphaned transactions** belonging to **368 unmapped `person_id` keys** (<0.01% of total volume).
- **Resolution Rule:** Orphaned transactions are explicitly filtered out in the Silver layer via an `INNER JOIN` validation against `int_clients`. Preserving only mapped records ensures strict referential integrity and prevents demographic distortion when evaluating customer loyalty and segmentation in the Gold layer.

---

## 🤖 AI-Augmented Data Governance & Self-Service Analytics (`scripts/`)

To accelerate metadata governance and enable natural-language exploration over the 67M+ row warehouse without exposing raw PII or incurring unnecessary compute costs, I integrated **Google Gemini AI** (`google-genai` SDK) with **BigQuery** through two standalone Python automation tools:

### 1. Automated dbt Documentation & Test Generator (`scripts/generate_dbt_docs.py`)
- **Metadata-Driven Synthesis:** Dynamically queries BigQuery's `INFORMATION_SCHEMA.COLUMNS` across all staging and intermediate models (58 columns) to extract exact column names and data types without reading row-level data.
- **Automated YAML & Quality Rules:** Uses Gemini with automatic model fallback (`gemini-3.1-flash-lite` / `gemini-3.6-flash`) to generate standardized `_stg_models.yml` and `_int_models.yml` files, drafting business descriptions and primary-key tests (`unique`, `not_null`) later validated via `dbt test` and `dbt docs generate`.

### 2. Natural Language to GoogleSQL Agent (`scripts/text_to_sql.py`)
- **Schema-Grounded Text-to-SQL:** Injects live BigQuery metadata into Gemini to translate plain-English or Spanish business questions into dialect-accurate, table-qualified **GoogleSQL**.
- **Architectural Guardrails:** Instructs the LLM to prioritize curated Silver (`int_`) models over raw Bronze (`stg_`) views and enforces a strict read-only validation check (`SELECT` / `WITH` only) prior to query execution.

#### Quickstart (`scripts/`)
```bash
# Install dependencies
pip install google-genai google-cloud-bigquery pandas db-dtypes

# Set environment variables
export GEMINI_API_KEY="your_api_key"
export GCP_PROJECT_ID="jtaguico-websites"
export DBT_DATASET_ID="dbt_jdata"

# 1. Regenerate dbt schema.yml definitions from BigQuery metadata
python scripts/generate_dbt_docs.py

# 2. Query the warehouse in natural language
python scripts/text_to_sql.py "How many unique clients exist by member_status and account_type?"
```
