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
  // Login
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
  console.log("Logged in successfully. Got access token.");

  const headers = { 
    apikey: key,
    Authorization: `Bearer ${token}`
  };

  // Query all canteens
  const canteenRes = await fetch(`${url}/rest/v1/canteens`, { headers });
  const canteens = await canteenRes.json();
  console.log("=== CANTEENS ===");
  canteens.forEach(c => {
    console.log(`ID: ${c.id}`);
    console.log(`Name: ${c.name}`);
    console.log(`max_concurrent_orders: ${c.max_concurrent_orders}`);
    console.log(`is_open: ${c.is_open}`);
    console.log("----------------");
  });

  // Query all orders that are not completed/delivered/declined/rejected/cancelled
  const orderRes = await fetch(`${url}/rest/v1/orders?select=id,canteen_id,status,created_at`, { headers });
  const orders = await orderRes.json();
  console.log("=== ORDERS ===");
  console.log(`Total orders in DB: ${orders.length}`);
  const activeOrders = orders.filter(o => !["completed", "delivered", "declined", "rejected", "cancelled"].includes(o.status));
  console.log(`Active orders count: ${activeOrders.length}`);
  activeOrders.forEach(o => {
    console.log(`Order ID: ${o.id}, Canteen ID: ${o.canteen_id}, Status: ${o.status}, Created: ${o.created_at}`);
  });
}
run();
