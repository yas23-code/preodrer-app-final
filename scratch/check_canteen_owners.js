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

  // Canteens
  const canteenRes = await fetch(`${url}/rest/v1/canteens`, { headers });
  const canteens = await canteenRes.json();

  // User roles
  const rolesRes = await fetch(`${url}/rest/v1/user_roles`, { headers });
  const roles = await rolesRes.json();

  // Profiles
  const profilesRes = await fetch(`${url}/rest/v1/profiles`, { headers });
  const profiles = await profilesRes.json();
  
  console.log("=== CANTEENS ===");
  canteens.forEach(c => {
    const owner = profiles.find(p => p.id === c.vendor_id);
    const ownerRole = roles.find(r => r.user_id === c.vendor_id);
    console.log(`Canteen: ${c.name} (${c.id})`);
    console.log(`  Vendor ID: ${c.vendor_id}`);
    console.log(`  Vendor Name: ${owner ? (owner.full_name || owner.email) : 'Unknown'}`);
    console.log(`  Vendor Email: ${owner ? owner.email : 'Unknown'}`);
    console.log(`  Vendor Role: ${ownerRole ? ownerRole.role : 'None'}`);
  });
}
run();
