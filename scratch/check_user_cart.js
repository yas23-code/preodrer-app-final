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

  // Find profile with phone '9045482200'
  const profilesRes = await fetch(`${url}/rest/v1/profiles?phone=eq.9045482200`, { headers });
  const profiles = await profilesRes.json();
  if (profiles.length === 0) {
    console.log("No profile found with phone 9045482200");
    return;
  }
  
  const user = profiles[0];
  console.log(`Found profile: ID=${user.id}, Name=${user.full_name}, Email=${user.email}`);

  // Query cart items for this user
  const cartRes = await fetch(`${url}/rest/v1/cart_items?user_id=eq.${user.id}`, { headers });
  const cartItems = await cartRes.json();
  console.log(`Cart items count: ${cartItems.length}`);
  
  for (const item of cartItems) {
    // Fetch the menu item
    const menuRes = await fetch(`${url}/rest/v1/menu_items?id=eq.${item.item_id}`, { headers });
    const menuItems = await menuRes.json();
    if (menuItems.length > 0) {
      const mi = menuItems[0];
      console.log(`- Item: "${mi.name}", Quantity: ${item.quantity}`);
      console.log(`  Item ID: ${mi.id}`);
      console.log(`  Canteen ID of Item: ${mi.canteen_id}`);
    } else {
      console.log(`- Item ID ${item.item_id} not found in menu_items`);
    }
  }
}
run();
