import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { JWT } from "npm:google-auth-library@9";

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
    const { order_id } = await req.json();

    if (!order_id) {
      return new Response(
        JSON.stringify({ error: "order_id is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get order to find student_id
    const { data: orderData, error: orderError } = await supabase
      .from("orders")
      .select("student_id")
      .eq("id", order_id)
      .single();

    if (orderError || !orderData?.student_id) {
      throw new Error("Order not found or missing student_id");
    }

    // Get FCM tokens for the student
    const { data: tokensData, error: tokensError } = await supabase
      .from("user_device_tokens")
      .select("fcm_token")
      .eq("user_id", orderData.student_id);

    if (tokensError || !tokensData || tokensData.length === 0) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: "No FCM tokens found for customer", 
          debug: { student_id: orderData.student_id, tokensError, tokensData }
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    const serviceAccountStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_B64");
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID");

    if (!serviceAccountStr || !projectId) {
      return new Response(JSON.stringify({ error: "Missing FIREBASE secrets" }), { status: 500 });
    }

    // Clean the base64 string to avoid InvalidCharacterError from atob
    const cleanB64 = serviceAccountStr.replace(/[^A-Za-z0-9+/=]/g, "");
    
    let serviceAccount;
    try {
      serviceAccount = JSON.parse(atob(cleanB64));
    } catch (parseErr: any) {
      return new Response(JSON.stringify({ 
        error: "Failed to parse service account JSON", 
        details: parseErr.message,
        cleanB64_length: cleanB64.length,
        original_length: serviceAccountStr.length
      }), { status: 500 });
    }

    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });

    const authTokens = await jwtClient.authorize();
    const accessToken = authTokens.access_token;

    let sentCount = 0;
    for (const t of tokensData) {
      const fcmResponse = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${accessToken}`,
          },
          body: JSON.stringify({
            message: {
              token: t.fcm_token,
              notification: {
                title: "Your Order is Ready! 🎉",
                body: "Your order is ready for pickup. Please show your QR code or 4-digit PIN to collect it.",
              },
              data: {
                route: "/orders",
              },
            },
          }),
        }
      );
      if (!fcmResponse.ok) {
        console.error("FCM Send Error:", await fcmResponse.text());
      } else {
        console.log("FCM Notification sent to", t.fcm_token);
        sentCount++;
      }
    }

    return new Response(
      JSON.stringify({ success: true, sent_count: sentCount }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err: any) {
    console.error("notify-order-ready error:", err);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
