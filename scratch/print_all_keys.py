import urllib.request
import json
import re

with open('.env', 'r') as f:
    env = f.read()

url = re.search(r'SUPABASE_URL=(.*)', env).group(1).strip()
key = re.search(r'SUPABASE_ANON_KEY=(.*)', env).group(1).strip()

# 1. Login to get token
login_url = f"{url}/auth/v1/token?grant_type=password"
login_data = json.dumps({
    "email": "preorderfood2026@gmail.com",
    "password": "Admin@123"
}).encode('utf-8')

login_req = urllib.request.Request(
    login_url,
    data=login_data,
    headers={
        "apikey": key,
        "Content-Type": "application/json"
    }
)

try:
    with urllib.request.urlopen(login_req) as response:
        login_res = json.loads(response.read().decode('utf-8'))
        access_token = login_res['access_token']
        print("Login successful! Got access token.")
        
        headers = {
            "apikey": key,
            "Authorization": f"Bearer {access_token}"
        }

        for table in ["profiles", "canteens", "orders", "order_items", "user_roles"]:
            req = urllib.request.Request(f"{url}/rest/v1/{table}?limit=1", headers=headers)
            try:
                with urllib.request.urlopen(req) as response:
                    data = json.loads(response.read().decode())
                    print(f"\nTable: {table}")
                    if data:
                        print("Keys:", list(data[0].keys()))
                        print("Row:", data[0])
                    else:
                        print("No rows found.")
            except Exception as e:
                print(f"Error {table}: {e}")
except Exception as e:
    print("Login error:", e)
