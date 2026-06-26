import urllib.request
import json

url = "https://erlsfpqmtzbcpcjhroop.supabase.co/rest/v1/user_roles?limit=1"
headers = {
    "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVybHNmcHFtdHpiY3Bjamhyb29wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNTEyNTYsImV4cCI6MjA3OTYyNzI1Nn0.vCoonRoUWtXiLgc8ZaJwpVVbXsCShVZnYmy0iGkqfOg",
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVybHNmcHFtdHpiY3Bjamhyb29wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNTEyNTYsImV4cCI6MjA3OTYyNzI1Nn0.vCoonRoUWtXiLgc8ZaJwpVVbXsCShVZnYmy0iGkqfOg"
}

req = urllib.request.Request(url, headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        print("user_roles:", json.loads(response.read().decode()))
except Exception as e:
    print(f"Error user_roles: {e}")

# Also check canteens
url = "https://erlsfpqmtzbcpcjhroop.supabase.co/rest/v1/canteens?limit=1"
req = urllib.request.Request(url, headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        print("canteens:", json.loads(response.read().decode()))
except Exception as e:
    print(f"Error canteens: {e}")
