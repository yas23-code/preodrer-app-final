const fs = require('fs');

const envFile = fs.readFileSync('.env', 'utf8');
const lines = envFile.split('\n');
let url = '';
let key = '';
for (const line of lines) {
  if (line.startsWith('SUPABASE_URL=')) url = line.split('=')[1].trim();
  if (line.startsWith('SUPABASE_ANON_KEY=')) key = line.split('=')[1].trim();
}

async function run() {
  const res = await fetch(`${url}/rest/v1/`, {
    headers: { apikey: key }
  });
  console.log("Status:", res.status);
  const data = await res.json();
  console.log("Response:", data);
}
run();
