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
        
        # 2. Get Swagger OpenAPI schema
        req = urllib.request.Request(
            f"{url}/rest/v1/",
            headers={
                "apikey": key,
                "Authorization": f"Bearer {access_token}"
            }
        )
        with urllib.request.urlopen(req) as res_schema:
            swagger = json.loads(res_schema.read().decode())
            print("Available tables:", list(swagger.get('definitions', {}).keys()))
            for table, definition in swagger.get('definitions', {}).items():
                print(f"\nTable: {table}")
                print("Properties:", list(definition.get('properties', {}).keys()))
except Exception as e:
    print("Error:", e)
