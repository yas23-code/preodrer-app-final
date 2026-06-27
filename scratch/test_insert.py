import urllib.request
import json
import re

with open('.env', 'r') as f:
    env = f.read()

url = re.search(r'SUPABASE_URL=(.*)', env).group(1).strip()
key = re.search(r'SUPABASE_ANON_KEY=(.*)', env).group(1).strip()

# Let's perform a test signup/insert using python to see what error the database returns
# We will insert a dummy registration for an existing user id 'f9ccb486-dab3-4802-97f7-1a41595fc26e'
data = {
    'owner_name': 'Test Owner',
    'canteen_name': 'Test Canteen',
    'email': 'test_omit_user_id@example.com',
    'phone': '1234567890',
    'location': 'Test Location',
    'status': 'pending'
}

req = urllib.request.Request(
    f"{url}/rest/v1/canteen_registrations",
    data=json.dumps(data).encode(),
    headers={
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "Prefer": "return=representation"
    }
)

try:
    with urllib.request.urlopen(req) as response:
        print("Success:", json.loads(response.read().decode()))
except Exception as e:
    if hasattr(e, 'read'):
        print("Database Error detail:", e.read().decode())
    else:
        print("Error:", e)
