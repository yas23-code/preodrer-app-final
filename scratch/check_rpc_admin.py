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

# Call public.is_superadmin RPC
data = {
    "user_id": "5e78302a-98b0-4dc8-98ae-ba287d86078b"
}
req = urllib.request.Request(
    f"{url}/rest/v1/rpc/is_superadmin",
    data=json.dumps(data).encode(),
    headers=headers
)
try:
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode())
        print("is_superadmin result for 5e78302a-98b0-4dc8-98ae-ba287d86078b:", result)
except Exception as e:
    if hasattr(e, 'read'):
        print("Error calling RPC:", e.read().decode())
    else:
        print("Error calling RPC:", e)
