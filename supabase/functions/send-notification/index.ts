import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// ─── Helpers ────────────────────────────────────────────────────────────────

/** Base64-url encode a Uint8Array */
function base64url(data: Uint8Array): string {
  const base64 = btoa(String.fromCharCode(...data));
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/** Sign a string with an RSA-SHA256 private key in PEM format */
async function signRS256(input: string, pemKey: string): Promise<string> {
  // Strip PEM headers/footers and decode
  const stripped = pemKey
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const binaryDer = Uint8Array.from(atob(stripped), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const encoder = new TextEncoder();
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(input)
  );

  return base64url(new Uint8Array(signature));
}

/** Build a signed JWT and exchange it for a Google OAuth2 access token */
async function getAccessToken(serviceAccount: Record<string, string>): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const encoder = new TextEncoder();
  const encode = (obj: object) =>
    base64url(encoder.encode(JSON.stringify(obj)));

  const signingInput = `${encode(header)}.${encode(payload)}`;
  const signature = await signRS256(signingInput, serviceAccount.private_key);
  const jwt = `${signingInput}.${signature}`;

  const tokenResp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenResp.ok) {
    const body = await tokenResp.text();
    throw new Error(`Failed to get access token: ${body}`);
  }

  const { access_token } = await tokenResp.json();
  return access_token as string;
}

// ─── Main handler ───────────────────────────────────────────────────────────

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    // 1. Parse request body
    const { deviceToken, title, body, data } = await req.json();

    if (!deviceToken || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: deviceToken, title, body" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // 2. Load Firebase service account from Supabase secret
    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      return new Response(
        JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT secret not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const serviceAccount = JSON.parse(serviceAccountJson) as Record<string, string>;

    // 3. Get a short-lived OAuth2 token
    const accessToken = await getAccessToken(serviceAccount);

    // 4. Build the FCM v1 message payload
    const projectId = serviceAccount.project_id;
    const message: Record<string, unknown> = {
      message: {
        token: deviceToken,
        notification: { title, body },
        data: data ?? {},
        android: {
          priority: "high",
        },
      },
    };

    // 5. Send the notification via FCM HTTP v1
    const fcmResp = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(message),
      }
    );

    const fcmBody = await fcmResp.json();

    if (!fcmResp.ok) {
      console.error("FCM error:", JSON.stringify(fcmBody));
      return new Response(
        JSON.stringify({ error: "FCM request failed", details: fcmBody }),
        { status: fcmResp.status, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, fcmResponse: fcmBody }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
