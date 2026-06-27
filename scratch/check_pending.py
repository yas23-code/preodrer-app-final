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

# Fetch all pending canteen registrations
req = urllib.request.Request(f"{url}/rest/v1/canteen_registrations?status=eq.pending", headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        regs = json.loads(response.read().decode())
        print("Pending registrations:")
        for r in regs:
            print(f"- ID: {r['id']}, User ID: {r['user_id']}, Canteen: {r['canteen_name']}, Location: {r['location']}")
except Exception as e:
    print(f"Error fetching: {e}")
