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

  // Fetch all categories
  const categoriesRes = await fetch(`${url}/rest/v1/categories`, { headers });
  const categories = await categoriesRes.json();
  console.log("=== CATEGORIES ===");
  categories.forEach(c => {
    console.log(`ID: ${c.id}, Name: ${c.name}, Image: ${c.image_url}, Canteen: ${c.canteen_id}`);
  });

  // Fetch all menu items
  const menuRes = await fetch(`${url}/rest/v1/menu_items`, { headers });
  const menuItems = await menuRes.json();
  console.log("\n=== MENU ITEMS ===");
  menuItems.forEach(item => {
    console.log(`ID: ${item.id}, Name: ${item.name}, Category ID: ${item.category_id}, Canteen ID: ${item.canteen_id}`);
  });
}
run();
