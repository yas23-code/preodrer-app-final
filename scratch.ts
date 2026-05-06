import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = "https://erlsfpqmtzbcpcjhroop.supabase.co";
const supabaseKey = "sb_publishable_aYYrWybtiEWvIXD-XyJrWQ_lv065Uu6"; // Anon key is fine for edge function invocation

const supabase = createClient(supabaseUrl, supabaseKey);

async function main() {
  // Get latest order
  const { data: orders, error: orderError } = await supabase
    .from('orders')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(1);

  if (orderError || !orders || orders.length === 0) {
    console.error("No orders found", orderError);
    return;
  }

  const orderId = orders[0].id;
  console.log('Testing with order_id:', orderId);

  // Invoke edge function
  const { data, error } = await supabase.functions.invoke('notify-order-ready', {
    body: { order_id: orderId },
  });

  console.log('Response:', data);
  if (error) {
    console.error('Error:', error);
  }
}
main();
