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

# Fetch all canteens
req = urllib.request.Request(f"{url}/rest/v1/canteens", headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        canteens = json.loads(response.read().decode())
        print("Canteens in database:")
        for c in canteens:
            print(f"- ID: {c.get('id')}, Name: {c.get('name')}, Vendor ID: {c.get('vendor_id')}")
except Exception as e:
    print(f"Error fetching canteens: {e}")
