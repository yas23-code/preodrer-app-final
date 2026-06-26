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
        
        # 2. Query orders
        query_url = f"{url}/rest/v1/orders?select=id,total_amount,created_at,status,refund_status,rejection_reason,profiles!student_id(*),canteens(name)&status=eq.declined"
        
        query_req = urllib.request.Request(
            query_url,
            headers={
                "apikey": key,
                "Authorization": f"Bearer {access_token}"
            }
        )
        
        with urllib.request.urlopen(query_req) as query_response:
            data = json.loads(query_response.read().decode('utf-8'))
            for order in data:
                print(f"\nID: {order['id']}")
                print(f"Status: {order['status']}, RefundStatus: {order['refund_status']}")
                print(f"Student: {order.get('profiles')}")
                print(f"Canteen: {order.get('canteens')}")
except Exception as e:
    print("Error:", e)
