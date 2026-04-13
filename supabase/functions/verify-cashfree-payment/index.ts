// supabase/functions/verify-cashfree-payment/index.ts
//
// Verifies a Cashfree payment server-side by calling the Cashfree Get Order API.
// If the order is PAID, updates public.orders to payment_status='paid'.
//
// Expects JSON body:
//   { app_order_id, cf_order_id }
//
// Returns JSON:
//   { success: true/false, order_status: string }
//
// Required Supabase secrets:
//   CASHFREE_APP_ID
//   CASHFREE_SECRET_KEY
//   CASHFREE_ENV
//   SUPABASE_URL (auto-injected)
//   SUPABASE_SERVICE_ROLE_KEY (auto-injected)

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
    const { app_order_id, cf_order_id } = await req.json();

    if (!app_order_id || !cf_order_id) {
      return new Response(
        JSON.stringify({ error: "app_order_id and cf_order_id are required" }),
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

    // ── Fetch order status from Cashfree ──
    const cfResponse = await fetch(`${baseUrl}/orders/${cf_order_id}`, {
      method: "GET",
      headers: {
        "x-api-version": "2023-08-01",
        "x-client-id": appId,
        "x-client-secret": secretKey,
      },
    });

    const cfData = await cfResponse.json();

    if (!cfResponse.ok) {
      console.error("Cashfree verify error:", JSON.stringify(cfData));
      return new Response(
        JSON.stringify({ error: "Failed to fetch Cashfree order", details: cfData }),
        { status: 502, headers: { "Content-Type": "application/json" } },
      );
    }

    const orderStatus = cfData.order_status; // "PAID", "ACTIVE", "EXPIRED", etc.
    const isPaid = orderStatus === "PAID";

    // ── Update our DB ──
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    if (isPaid) {
      await supabase
        .from("orders")
        .update({
          payment_status: "paid",
          status: "confirmed",
          paid_at: new Date().toISOString(),
        })
        .eq("id", app_order_id);
    } else {
      await supabase
        .from("orders")
        .update({
          payment_status: "failed",
        })
        .eq("id", app_order_id);
    }

    return new Response(
      JSON.stringify({
        success: isPaid,
        order_status: orderStatus,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("verify-cashfree-payment error:", err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
