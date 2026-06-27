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

# We will test the three actions performed during approveCanteen:
# 1. Upsert role in user_roles
# 2. Update profiles role column
# 3. Insert canteen

user_id = '3ee803dd-d325-424e-98e0-9c4a3a5302cf' # The registering vendor ID

print("--- Testing user_roles upsert ---")
data = {
    'user_id': user_id,
    'role': 'vendor'
}
req = urllib.request.Request(
    f"{url}/rest/v1/user_roles",
    data=json.dumps(data).encode(),
    headers={**headers, "Prefer": "resolution=merge-duplicates"}
)
try:
    with urllib.request.urlopen(req) as response:
        print("user_roles upsert: SUCCESS")
except Exception as e:
    if hasattr(e, 'read'):
        print("user_roles upsert FAIL:", e.read().decode())
    else:
        print("user_roles upsert FAIL:", e)

print("--- Testing profiles update ---")
data = {
    'role': 'vendor'
}
# We use PATCH for update
req = urllib.request.Request(
    f"{url}/rest/v1/profiles?id=eq.{user_id}",
    data=json.dumps(data).encode(),
    headers=headers,
    method='PATCH'
)
try:
    with urllib.request.urlopen(req) as response:
        print("profiles update: SUCCESS")
except Exception as e:
    if hasattr(e, 'read'):
        print("profiles update FAIL:", e.read().decode())
    else:
        print("profiles update FAIL:", e)

print("--- Testing canteens insert ---")
data = {
    'name': 'Test Canteen',
    'location': 'Test Location',
    'vendor_id': user_id,
    'is_open': True
}
req = urllib.request.Request(
    f"{url}/rest/v1/canteens",
    data=json.dumps(data).encode(),
    headers=headers
)
try:
    with urllib.request.urlopen(req) as response:
        print("canteens insert: SUCCESS")
except Exception as e:
    if hasattr(e, 'read'):
        print("canteens insert FAIL:", e.read().decode())
    else:
        print("canteens insert FAIL:", e)
