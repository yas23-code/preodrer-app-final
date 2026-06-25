import urllib.request
import json
import re

with open('.env', 'r') as f:
    env = f.read()

url = re.search(r'SUPABASE_URL=(.*)', env).group(1).strip()
key = re.search(r'SUPABASE_ANON_KEY=(.*)', env).group(1).strip()

# Query swagger or do a select of 0 rows to inspect columns from headers
req = urllib.request.Request(
    f"{url}/rest/v1/orders?limit=0",
    headers={
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Prefer": "count=exact"
    }
)
try:
    with urllib.request.urlopen(req) as response:
        print("Headers:")
        for k, v in response.info().items():
            print(f"{k}: {v}")
except Exception as e:
    print(f"Error: {e}")
