import urllib.request
import json
import re

with open('.env', 'r') as f:
    env = f.read()

url = re.search(r'SUPABASE_URL=(.*)', env).group(1).strip()
key = re.search(r'SUPABASE_ANON_KEY=(.*)', env).group(1).strip()

# Try with apikey in query param and NO Authorization header
req_url = f"{url}/rest/v1/?apikey={key}"
print("Fetching from:", req_url)
try:
    req = urllib.request.Request(req_url)
    with urllib.request.urlopen(req) as response:
        swagger = json.loads(response.read().decode())
        print("Success! Available tables:")
        print(list(swagger.get('definitions', {}).keys()))
        for t in ['profiles', 'canteens', 'orders']:
            if t in swagger.get('definitions', {}):
                print(f"\nTable {t} columns:")
                print(list(swagger['definitions'][t].get('properties', {}).keys()))
except Exception as e:
    print("Error:", e)
