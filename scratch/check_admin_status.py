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

# Fetch user_roles and profiles for preorderfood2026@gmail.com
req = urllib.request.Request(f"{url}/rest/v1/profiles?email=eq.preorderfood2026@gmail.com", headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        profiles = json.loads(response.read().decode())
        if profiles:
            p = profiles[0]
            print(f"Profile: ID: {p['id']}, Email: {p['email']}, Role: {p['role']}, Name: {p['name']}")
            
            # Now fetch user_roles
            req_role = urllib.request.Request(f"{url}/rest/v1/user_roles?user_id=eq.{p['id']}", headers=headers)
            with urllib.request.urlopen(req_role) as res_role:
                roles = json.loads(res_role.read().decode())
                print("User Roles in database:", roles)
        else:
            print("No profile found for preorderfood2026@gmail.com")
except Exception as e:
    print(f"Error: {e}")
