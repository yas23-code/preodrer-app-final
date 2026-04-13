// supabase/functions/create-cashfree-order/index.ts
//
// Creates a Cashfree order server-side (secret key never leaves the backend).
// Called by the Flutter app after inserting an order row with payment_status='pending'.
//
// Expects JSON body:
//   { app_order_id, amount, customer_id, customer_email, customer_phone, customer_name }
//
// Returns JSON:
//   { cf_order_id, payment_session_id }
//
// Required Supabase secrets (set via `supabase secrets set`):
//   CASHFREE_APP_ID
//   CASHFREE_SECRET_KEY
//   CASHFREE_ENV         — "SANDBOX" or "PRODUCTION" (defaults to SANDBOX)
//   SUPABASE_URL         — auto-injected by Supabase
//   SUPABASE_SERVICE_ROLE_KEY — auto-injected by Supabase

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  // ── CORS preflight ──
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const {
      app_order_id,
      amount,
      customer_id,
      customer_email,
      customer_phone,
      customer_name,
    } = await req.json();

    // ── Validate input ──
    if (!app_order_id || !amount) {
      return new Response(
        JSON.stringify({ error: "app_order_id and amount are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    // ── Cashfree credentials ──
    const appId = Deno.env.get("CASHFREE_APP_ID")!;
    const secretKey = Deno.env.get("CASHFREE_SECRET_KEY")!;
    const cfEnv = Deno.env.get("CASHFREE_ENV") || "SANDBOX";

    const baseUrl =
      cfEnv === "PRODUCTION"
        ? "https://api.cashfree.com/pg"
        : "https://sandbox.cashfree.com/pg";

    // Debug logging
    console.log(`[create-cashfree-order] ENV=${cfEnv}, baseUrl=${baseUrl}`);
    console.log(`[create-cashfree-order] appId=${appId?.substring(0, 8)}..., secretKey=${secretKey ? secretKey.substring(0, 8) + '...' : 'NOT SET'}`);
    console.log(`[create-cashfree-order] order_id=${app_order_id}, amount=${amount}`);

    // ── Create Cashfree order ──
    const cfResponse = await fetch(`${baseUrl}/orders`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-version": "2023-08-01",
        "x-client-id": appId,
        "x-client-secret": secretKey,
      },
      body: JSON.stringify({
        order_id: app_order_id,
        order_amount: Number(amount),
        order_currency: "INR",
        customer_details: {
          customer_id: customer_id || "guest",
          customer_email: customer_email || "customer@preorder.app",
          customer_phone: customer_phone || "9999999999",
          customer_name: customer_name || "Customer",
        },
      }),
    });

    const cfData = await cfResponse.json();
    
    console.log(`[create-cashfree-order] Cashfree HTTP status=${cfResponse.status}`);
    console.log(`[create-cashfree-order] Cashfree full response: ${JSON.stringify(cfData)}`);

    if (!cfResponse.ok) {
      console.error("Cashfree error:", JSON.stringify(cfData));
      return new Response(
        JSON.stringify({ error: "Cashfree order creation failed", details: cfData }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }

    const cfOrderId = cfData.cf_order_id?.toString() || cfData.order_id;
    const paymentSessionId = cfData.payment_session_id;
    
    console.log(`[create-cashfree-order] cf_order_id=${cfOrderId}`);
    console.log(`[create-cashfree-order] payment_session_id type=${typeof paymentSessionId}, length=${paymentSessionId?.length}`);

    // ── Update our orders table with Cashfree references ──
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    await supabase
      .from("orders")
      .update({
        cashfree_order_id: cfOrderId,
        payment_session_id: paymentSessionId,
      })
      .eq("id", app_order_id);

    // ── Return to Flutter ──
    return new Response(
      JSON.stringify({
        cf_order_id: cfOrderId,
        payment_session_id: paymentSessionId,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("create-cashfree-order error:", err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
