# FuelStream-Analytics: Enterprise-Grade Medallion Pipeline with dbt Cloud

## 🎯 Project Goal
The core business objective of this project is to transform a massive, production-scale dataset of over **67 million raw consumer transactions (~8 GB)** and a reference catalog of **2 million customers** into an optimized analytical data warehouse. 

By leveraging **dbt Cloud** and **Google BigQuery**, this pipeline implements a Medallion Architecture (Bronze -> Silver -> Gold) to eliminate data anomalies, ensure customer referential integrity, and deliver analytical models optimized to evaluate customer loyalty, track monthly consumption volume, and segment demographic behavior across the service station network.

Unlike my sister project built on Databricks (which utilized a 1.5% stratified sample due to computational limits on the free tier), **this dbt pipeline processes 100% of the 67 million rows** directly inside BigQuery, capitalizing on modern ELT (Extract-Load-Transform) practices and zero-redundancy storage techniques.

---

## 🏗️ Project Architecture & Medallion Strategy

This pipeline is engineered to ensure data quality and scalability through clear separation of concerns:

- **Bronze Layer (`staging`)**: Acting as our ingestion ledger. It maps raw tables via dbt Sources, applies strict architectural standards (lowercase formatting, explicit aliases in English, and date-time parsing), and enforces governance by dropping PII (Personally Identifiable Information) columns early.
- **Silver Layer (`intermediate`)**: *[In Progress]* Handles heavy data merging, resolves the fragmented customer catalogs, isolates system initialization noise, and treats the critical 2017/2018 volumetric anomalies.
- **Gold Layer (`marts`)**: *[Planned]* Dimensional modeling designed for high-performance consumption in Looker Studio / Power BI.

---

## 🥉 Bronze Layer (Staging) Reference

We have successfully mapped and standardized our raw BigQuery infrastructure into three modular, storage-efficient dbt views:

- `stg_transactions`: Streamlines the core transaction ledger, mapping physical channels (e.g., POS codes) and operational timestamps.
- `stg_clients_01`: Standardizes the primary consumer demographic segment.
- `stg_clients_02`: Standardizes the secondary consumer segment, utilizing explicit null injections to maintain structural symmetry with segment 01.

### 🛡️ Governance & PII Controls
To ensure enterprise-grade compliance and safely present this project in a public portfolio, columns containing sensitive personal data (such as `names`, `last_names`, `emails`, and physical `card_numbers`) are explicitly filtered out at this layer, preserving only the analytical dimensions (`gender`, `birth_date`, `location`).
