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

  const headers = { 
    apikey: key,
    Authorization: `Bearer ${token}`
  };

  // Query all canteens
  const canteenRes = await fetch(`${url}/rest/v1/canteens`, { headers });
  const canteens = await canteenRes.json();
  const canteenMap = {};
  canteens.forEach(c => {
    canteenMap[c.id] = { name: c.name, max: c.max_concurrent_orders, active: 0 };
  });

  // Query all active orders
  const orderRes = await fetch(`${url}/rest/v1/orders?select=canteen_id,status`, { headers });
  const orders = await orderRes.json();
  orders.forEach(o => {
    if (!["completed", "delivered", "declined", "rejected", "cancelled"].includes(o.status)) {
      if (canteenMap[o.canteen_id]) {
        canteenMap[o.canteen_id].active++;
      } else {
        console.log(`Unknown canteen ID in order: ${o.canteen_id}`);
      }
    }
  });

  console.log("=== CANTEEN ACTIVE ORDERS ===");
  Object.keys(canteenMap).forEach(id => {
    const c = canteenMap[id];
    console.log(`${c.name} (${id}): Active: ${c.active}, Max Concurrent Allowed: ${c.max}`);
  });
}
run();
