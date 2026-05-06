import { createClient } from '@supabase/supabase-js';

const supabaseUrl = "https://erlsfpqmtzbcpcjhroop.supabase.co";
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVybHNmcHFtdHpiY3Bjamhyb29wIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczODc0MDM4MSwiZXhwIjoyMDU0MzE2MzgxfQ.oXl4fH9Pq8Bf4PzXkVd6N4JvQXq5c2Bw1gR8kF8X8Lw"; 
const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
  const { data: orders, error: orderError } = await supabase
    .from('orders')
    .select('id, student_id, status, created_at')
    .order('created_at', { ascending: false })
    .limit(5);

  if (orderError) {
    console.error("Order fetch error:", orderError);
    return;
  }

  console.log("Latest orders:");
  console.log(orders);

  if (orders && orders.length > 0) {
    for (const order of orders) {
      if (order.student_id) {
        const { data: tokens } = await supabase
          .from('user_device_tokens')
          .select('fcm_token')
          .eq('user_id', order.student_id);
        
        console.log(`Tokens for student ${order.student_id}:`, tokens);
      } else {
        console.log(`Order ${order.id} has no student_id`);
      }
    }
  }
}

check();
