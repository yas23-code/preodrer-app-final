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
    Authorization: `Bearer ${token}`
  };

  // Query all cart items
  const cartRes = await fetch(`${url}/rest/v1/cart_items`, { headers });
  const cartItems = await cartRes.json();
  console.log(`Total cart items in database: ${cartItems.length}`);
  
  for (const item of cartItems) {
    const userRes = await fetch(`${url}/rest/v1/profiles?id=eq.${item.user_id}`, { headers });
    const users = await userRes.json();
    const user = users[0];
    
    const menuRes = await fetch(`${url}/rest/v1/menu_items?id=eq.${item.item_id}`, { headers });
    const menuItems = await menuRes.json();
    const mi = menuItems[0];
    
    console.log(`User: ${user ? user.email : item.user_id} (Phone: ${user ? user.phone : 'N/A'})`);
    console.log(`- Item: "${mi ? mi.name : item.item_id}" x ${item.quantity}`);
  }
}
run();
