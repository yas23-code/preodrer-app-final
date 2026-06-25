import urllib.request
import json
import re

with open('.env', 'r') as f:
    env = f.read()

url = re.search(r'SUPABASE_URL=(.*)', env).group(1).strip()
key = re.search(r'SUPABASE_ANON_KEY=(.*)', env).group(1).strip()

headers = {
    "apikey": key,
    "Authorization": f"Bearer {key}"
}

tables = ["profiles", "user_roles", "canteens"]
for t in tables:
    req = urllib.request.Request(f"{url}/rest/v1/{t}?limit=1", headers=headers)
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            print(f"Table: {t}")
            print(f"Sample row: {data}")
    except Exception as e:
        print(f"Error {t}: {e}")
