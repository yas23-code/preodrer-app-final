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

  const categoriesToDelete = [
    'f45c9cd8-3c8b-4586-9f69-176f1f4db38e', // euue
    '33766605-885c-4dd1-a880-03d6e9a54aba'  // fuck
  ];

  for (const catId of categoriesToDelete) {
    // 1. Unlink items from this category
    const unlinkRes = await fetch(`${url}/rest/v1/menu_items?category_id=eq.${catId}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ category_id: null })
    });
    console.log(`Unlinked items for category ${catId}: Status ${unlinkRes.status}`);

    // 2. Delete the category
    const deleteRes = await fetch(`${url}/rest/v1/categories?id=eq.${catId}`, {
      method: 'DELETE',
      headers
    });
    console.log(`Deleted category ${catId}: Status ${deleteRes.status}`);
  }
}
run();
