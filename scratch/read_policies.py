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

# Call get_policies RPC for user_roles
req = urllib.request.Request(
    f"{url}/rest/v1/rpc/get_policies",
    data=json.dumps({"table_name": "user_roles"}).encode(),
    headers=headers
)

try:
    with urllib.request.urlopen(req) as response:
        print("Policies for canteen_registrations:")
        policies = json.loads(response.read().decode())
        if policies:
            for p in policies:
                print(f"- Policy: {p.get('policyname')}, Cmd: {p.get('cmd')}, Roles: {p.get('roles')}, Qual: {p.get('qual')}, WithCheck: {p.get('with_check')}")
        else:
            print("No policies found.")
except Exception as e:
    if hasattr(e, 'read'):
        print("Error details:", e.read().decode())
    else:
        print("Error:", e)
