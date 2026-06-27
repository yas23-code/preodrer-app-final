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

# Fetch last 5 canteen registrations
req = urllib.request.Request(f"{url}/rest/v1/canteen_registrations?order=created_at.desc&limit=5", headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        print("canteen_registrations:", json.loads(response.read().decode()))
except Exception as e:
    print(f"Error canteen_registrations: {e}")

# Fetch last 5 user_roles
req = urllib.request.Request(f"{url}/rest/v1/user_roles?limit=5", headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        print("user_roles:", json.loads(response.read().decode()))
except Exception as e:
    print(f"Error user_roles: {e}")

# Fetch last 5 profiles
req = urllib.request.Request(f"{url}/rest/v1/profiles?order=created_at.desc&limit=5", headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        print("profiles:", json.loads(response.read().decode()))
except Exception as e:
    print(f"Error profiles: {e}")
