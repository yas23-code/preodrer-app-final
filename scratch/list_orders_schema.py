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

req = urllib.request.Request(f"{url}/rest/v1/orders?limit=1", headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
        print("orders row:", data)
except Exception as e:
    print(f"Error orders: {e}")
