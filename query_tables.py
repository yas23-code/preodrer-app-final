import urllib.request
import json
import re

with open('.env', 'r') as f:
    env = f.read()

url = re.search(r'SUPABASE_URL=(.*)', env).group(1).strip()
key = re.search(r'SUPABASE_ANON_KEY=(.*)', env).group(1).strip()

# Check user_roles structure by selecting 1 row
req = urllib.request.Request(
    f"{url}/rest/v1/user_roles?limit=1",
    headers={
        "apikey": key,
        "Authorization": f"Bearer {key}"
    }
)
try:
    with urllib.request.urlopen(req) as response:
        print("user_roles headers:", response.info().items())
        data = json.loads(response.read().decode())
        print("user_roles rows:", data)
except Exception as e:
    print(f"Error user_roles: {e}")

# Check profiles structure
req = urllib.request.Request(
    f"{url}/rest/v1/profiles?limit=1",
    headers={
        "apikey": key,
        "Authorization": f"Bearer {key}"
    }
)
try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
        print("profiles row:", data)
except Exception as e:
    print(f"Error profiles: {e}")
