import urllib.request
import json

url = "https://erlsfpqmtzbcpcjhroop.supabase.co/rest/v1/profiles?limit=1"
headers = {
    "apikey": "sb_publishable_aYYrWybtiEWvIXD-XyJrWQ_lv065Uu6",
    "Authorization": "Bearer sb_publishable_aYYrWybtiEWvIXD-XyJrWQ_lv065Uu6"
}

req = urllib.request.Request(url, headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        print(json.loads(response.read().decode()))
except Exception as e:
    print(f"Error: {e}")
