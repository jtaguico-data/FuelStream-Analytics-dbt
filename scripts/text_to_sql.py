import os
import sys
import time
from google.cloud import bigquery
from google import genai
from google.genai import types

PROJECT_ID = os.getenv("GCP_PROJECT_ID", "jtaguico-websites")
DATASET_ID = os.getenv("DBT_DATASET_ID", "dbt_jdata")

def ask_bigquery(question: str):
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("Missing GEMINI_API_KEY environment variable.")

    bq_client = bigquery.Client(project=PROJECT_ID)
    schema_query = f"""
    SELECT table_name, column_name, data_type
    FROM `{PROJECT_ID}.{DATASET_ID}.INFORMATION_SCHEMA.COLUMNS`
    ORDER BY table_name, ordinal_position
    """
    rows = bq_client.query(schema_query).result()
    schema_text = "\n".join([f"{r.table_name}.{r.column_name} ({r.data_type})" for r in rows])

    ai_client = genai.Client(api_key=api_key)
    prompt = f"""
    You are a Senior Analytics Engineer expert in Google BigQuery (GoogleSQL).
    Translate the business question below into an optimized, read-only GoogleSQL query using ONLY the tables and columns provided in the schema.

    Rules:
    1. Return ONLY raw SQL syntax without markdown formatting.
    2. Always qualify table names with `{PROJECT_ID}.{DATASET_ID}.table_name`.
    3. Prefer 'int_' (intermediate) tables over 'stg_' tables when answering business questions.
    4. Generate ONLY a SELECT statement.
    5. Limit results to 10 rows unless an aggregation is requested.

    BigQuery Schema:
    {schema_text}

    Business Question:
    {question}
    """

    fallback_models = [
        "gemini-3.1-flash-lite",
        "gemini-3.6-flash",
        "gemini-3.7-flash",
        "gemini-3.8-flash",
        "gemini-3.5-flash"
    ]

    sql_generated = None
    for model_id in fallback_models:
        try:
            response = ai_client.models.generate_content(
                model=model_id,
                contents=prompt,
                config=types.GenerateContentConfig(temperature=0.0),
            )
            sql_generated = response.text.strip()
            break
        except Exception:
            time.sleep(1)

    if not sql_generated:
        raise RuntimeError("All fallback Gemini models are currently unavailable.")

    clean_start = sql_generated.lstrip().upper()
    if not (clean_start.startswith("SELECT") or clean_start.startswith("WITH")):
        raise ValueError("Security block: Only read-only SELECT queries are permitted.")

    print(f"Generated SQL:\n{sql_generated}\n")
    df = bq_client.query(sql_generated).to_dataframe()
    print(df.to_string(index=False))

if __name__ == "__main__":
    user_question = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "How many unique clients exist by member_status?"
    ask_bigquery(user_question)
