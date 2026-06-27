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

# Fetch all profiles where role matches admin or superadmin, or just list all profiles
req = urllib.request.Request(f"{url}/rest/v1/profiles", headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        profiles = json.loads(response.read().decode())
        print("Profiles count:", len(profiles))
        for p in profiles:
            print(f"- Profile ID: {p['id']}, Email: {p['email']}, Role: {p['role']}, Name: {p['name']}")
except Exception as e:
    print(f"Error: {e}")
