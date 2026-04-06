import { corsHeaders } from "./cors.ts";

export function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

export function ok(body: unknown): Response {
  return jsonResponse(200, body);
}

export function badRequest(message: string, details?: unknown): Response {
  return jsonResponse(400, {
    success: false,
    error: message,
    details,
  });
}

export function unauthorized(message = "Unauthorized"): Response {
  return jsonResponse(401, {
    success: false,
    error: message,
  });
}

export function forbidden(message = "Forbidden"): Response {
  return jsonResponse(403, {
    success: false,
    error: message,
  });
}

export function notFound(message: string): Response {
  return jsonResponse(404, {
    success: false,
    error: message,
  });
}

export function methodNotAllowed(allowed = "POST, OPTIONS"): Response {
  return new Response("Method Not Allowed", {
    status: 405,
    headers: {
      ...corsHeaders,
      Allow: allowed,
    },
  });
}

export function upstreamFailure(
  message: string,
  details?: unknown,
  status = 502,
): Response {
  return jsonResponse(status, {
    success: false,
    error: message,
    details,
  });
}

