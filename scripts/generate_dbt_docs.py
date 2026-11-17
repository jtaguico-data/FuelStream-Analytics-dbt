import os
import sys
import time
from pathlib import Path
from google import genai
from google.genai import types

def generate_dbt_schema(sql_file_path: str) -> str:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("Missing GEMINI_API_KEY environment variable.")

    path = Path(sql_file_path)
    model_name = path.stem
    sql_content = path.read_text(encoding="utf-8")

    client = genai.Client(api_key=api_key)

    prompt = f"""
    You are a Senior Analytics Engineer expert in dbt and Google BigQuery.
    Analyze the following dbt SQL model named '{model_name}' and generate a valid dbt 'schema.yml' configuration block.

    Rules:
    1. Return ONLY raw YAML syntax without markdown code blocks.
    2. Start with 'version: 2' and the 'models:' key.
    3. Write a concise, business-oriented description for the model and each output column.
    4. Suggest appropriate dbt data quality tests ('unique', 'not_null') for primary keys.

    SQL Model Code:
    {sql_content}
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
            response = client.models.generate_content(
                model=model_id,
                contents=prompt,
                config=types.GenerateContentConfig(temperature=0.1),
            )
            return response.text.strip()
        except Exception:
            time.sleep(1)

    raise RuntimeError("All fallback Gemini models are currently unavailable.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scripts/generate_dbt_docs.py path/to/model.sql")
        sys.exit(1)

    print(generate_dbt_schema(sys.argv))
