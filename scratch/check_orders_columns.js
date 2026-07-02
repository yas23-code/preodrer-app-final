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
  const loginRes = await fetch(`${url}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: {
      'apikey': key,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      email: 'preorderfood2026@gmail.com',
      password: 'Admin@123'
    })
  });
  
  const loginData = await loginRes.json();
  const token = loginData.access_token;
  const headers = { 
    apikey: key,
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json'
  };

  const ordersRes = await fetch(`${url}/rest/v1/orders?limit=1`, {
    headers
  });
  
  const orders = await ordersRes.json();
  if (orders && orders.length > 0) {
    console.log("Orders columns:", Object.keys(orders[0]));
    console.log("Sample order:", orders[0]);
  } else {
    console.log("No orders found to inspect.");
  }
}
run();
