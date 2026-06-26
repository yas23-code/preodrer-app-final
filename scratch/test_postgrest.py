import urllib.request
import json
import re

with open('.env', 'r') as f:
    env = f.read()

url = re.search(r'SUPABASE_URL=(.*)', env).group(1).strip()
key = re.search(r'SUPABASE_ANON_KEY=(.*)', env).group(1).strip()

# Query orders with status = declined or rejected
query_url = f"{url}/rest/v1/orders?select=id,status,refund_status,rejection_reason,canteen_id,canteens(name)&status=in.(declined,rejected)"

req = urllib.request.Request(query_url, headers={
    "apikey": key,
    "Authorization": f"Bearer {key}"
})

try:
    with urllib.request.urlopen(req) as response:
        res_data = response.read().decode('utf-8')
        parsed = json.loads(res_data)
        print(json.dumps(parsed, indent=2))
except Exception as e:
    print("Error:", e)
