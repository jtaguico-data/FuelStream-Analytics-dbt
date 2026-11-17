import os
import time
from google.cloud import bigquery
from google import genai
from google.genai import types

PROJECT_ID = os.getenv("GCP_PROJECT_ID", "jtaguico-websites")
DATASET_ID = os.getenv("DBT_DATASET_ID", "dbt_jdata")

def generate_full_dbt_docs() -> str:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("Missing GEMINI_API_KEY environment variable.")

    # 1. Read exact tables and columns from BigQuery INFORMATION_SCHEMA
    bq_client = bigquery.Client(project=PROJECT_ID)
    schema_query = f"""
    SELECT table_name, column_name, data_type
    FROM `{PROJECT_ID}.{DATASET_ID}.INFORMATION_SCHEMA.COLUMNS`
    ORDER BY table_name, ordinal_position
    """
    rows = bq_client.query(schema_query).result()
    schema_lines = [f"{r.table_name} | {r.column_name} ({r.data_type})" for r in rows]
    schema_text = "\n".join(schema_lines)

    # 2. Generate dbt schema.yml via Gemini with automatic model fallback
    ai_client = genai.Client(api_key=api_key)
    prompt = f"""
    You are a Senior Analytics Engineer expert in dbt and Google BigQuery.
    Using the exact BigQuery schema below (table_name | column_name (data_type)), generate a complete, valid dbt 'schema.yml' file covering ALL models listed.

    Rules:
    1. Return ONLY raw YAML syntax without markdown code blocks.
    2. Start with 'version: 2' and the 'models:' key.
    3. Include every table and column exactly as spelled below.
    4. Write concise, business-oriented descriptions for each model and column.
    5. Add 'unique' and 'not_null' tests on primary keys in 'int_' models, and 'not_null' in 'stg_' models.

    BigQuery Schema:
    {schema_text}
    """

    fallback_models = [
        "gemini-3.1-flash-lite",
        "gemini-3.6-flash",
        "gemini-3.7-flash",
        "gemini-3.8-flash",
        "gemini-3.5-flash"
    ]

    for model_id in fallback_models:
        try:
            response = ai_client.models.generate_content(
                model=model_id,
                contents=prompt,
                config=types.GenerateContentConfig(temperature=0.1),
            )
            return response.text.strip()
        except Exception:
            time.sleep(1)

    raise RuntimeError("All fallback Gemini models are currently unavailable.")

if __name__ == "__main__":
    print(generate_full_dbt_docs())
