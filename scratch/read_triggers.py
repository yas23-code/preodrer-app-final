import urllib.request
import json
import re

with open('.env', 'r') as f:
    env = f.read()

url = re.search(r'SUPABASE_URL=(.*)', env).group(1).strip()
key = re.search(r'SUPABASE_ANON_KEY=(.*)', env).group(1).strip()

headers = {
    "apikey": key,
    "Authorization": f"Bearer {key}",
    "Content-Type": "application/json"
}

# Call get_triggers RPC for canteen_registrations
req = urllib.request.Request(
    f"{url}/rest/v1/rpc/get_triggers",
    data=json.dumps({"table_name": "canteen_registrations"}).encode(),
    headers=headers
)

try:
    with urllib.request.urlopen(req) as response:
        print("Triggers for canteen_registrations:")
        triggers = json.loads(response.read().decode())
        if triggers:
            for t in triggers:
                print(f"- Trigger: {t.get('tgname')}, Type: {t.get('tgtype')}")
        else:
            print("No triggers found.")
except Exception as e:
    if hasattr(e, 'read'):
        print("Error details:", e.read().decode())
    else:
        print("Error:", e)
