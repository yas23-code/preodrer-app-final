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

req = urllib.request.Request(f"{url}/rest/v1/profiles?role=eq.customer&limit=5", headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
        print("Customer profiles:")
        for r in data:
            print(r)
except Exception as e:
    print("Error customer profiles:", e)
    
req_student = urllib.request.Request(f"{url}/rest/v1/profiles?role=eq.student&limit=5", headers=headers)
try:
    with urllib.request.urlopen(req_student) as response:
        data = json.loads(response.read().decode())
        print("Student profiles:")
        for r in data:
            print(r)
except Exception as e:
    print("Error student profiles:", e)
