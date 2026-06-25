import urllib.request
import json

url = "https://erlsfpqmtzbcpcjhroop.supabase.co/rest/v1/?apikey=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVybHNmcHFtdHpiY3Bjamhyb29wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNTEyNTYsImV4cCI6MjA3OTYyNzI1Nn0.vCoonRoUWtXiLgc8ZaJwpVVbXsCShVZnYmy0iGkqfOg"
headers = {
    "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVybHNmcHFtdHpiY3Bjamhyb29wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNTEyNTYsImV4cCI6MjA3OTYyNzI1Nn0.vCoonRoUWtXiLgc8ZaJwpVVbXsCShVZnYmy0iGkqfOg",
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVybHNmcHFtdHpiY3Bjamhyb29wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwNTEyNTYsImV4cCI6MjA3OTYyNzI1Nn0.vCoonRoUWtXiLgc8ZaJwpVVbXsCShVZnYmy0iGkqfOg"
}

req = urllib.request.Request(url, headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        swagger = json.loads(response.read().decode())
        print("Available tables:", list(swagger.get('definitions', {}).keys()))
        for table, definition in swagger.get('definitions', {}).items():
            print(f"\nTable: {table}")
            print("Properties:", list(definition.get('properties', {}).keys()))
except Exception as e:
    print(f"Error swagger: {e}")
