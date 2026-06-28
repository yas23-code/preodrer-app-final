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
  
  if (!loginRes.ok) {
    console.error("Login failed:", await loginRes.text());
    return;
  }
  
  const loginData = await loginRes.json();
  const token = loginData.access_token;
  const headers = { 
    apikey: key,
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json'
  };

  // Fetch all orders
  const orderRes = await fetch(`${url}/rest/v1/orders?select=id,status,created_at`, { headers });
  const orders = await orderRes.json();
  console.log(`Total orders in DB: ${orders.length}`);

  const now = new Date();
  const twelveHoursAgo = new Date(now.getTime() - 12 * 60 * 60 * 1000);

  const staleActiveOrders = orders.filter(o => {
    const isActive = !["completed", "delivered", "declined", "rejected", "cancelled"].includes(o.status);
    const createdTime = new Date(o.created_at);
    return isActive && createdTime < twelveHoursAgo;
  });

  console.log(`Found ${staleActiveOrders.length} stale active orders older than 12 hours.`);

  // Update them in batches or sequentially
  let count = 0;
  for (const o of staleActiveOrders) {
    const updateRes = await fetch(`${url}/rest/v1/orders?id=eq.${o.id}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({
        status: 'completed',
        payment_status: 'paid'
      })
    });
    if (updateRes.ok) {
      count++;
    } else {
      console.error(`Failed to update order ${o.id}:`, await updateRes.text());
    }
  }

  console.log(`Successfully completed ${count} stale orders.`);
}
run();
