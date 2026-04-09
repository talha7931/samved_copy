import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { callAiService } from "../_shared/ai.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { env } from "../_shared/env.ts";
import {
  badRequest,
  forbidden,
  methodNotAllowed,
  ok,
  unauthorized,
  upstreamFailure,
} from "../_shared/http.ts";
import { createAdminClient } from "../_shared/supabase.ts";
import { logAuditEvent } from "../_shared/tickets.ts";

type DetectResponse = {
  success: boolean;
  detected: boolean;
  damage_type: string;
  ai_confidence: number;
  total_potholes: number;
  bounding_boxes: unknown[];
  ai_severity_index: number;
  ai_source: string;
  model_version: string;
  processing_ms: number;
  errors?: string[];
};

type SeverityResponse = {
  success: boolean;
  epdo_score: number;
  severity_tier: string;
  sla_hours: number;
  decision_trace: Record<string, unknown>;
  ruleset_version: string;
  processing_ms: number;
  errors?: string[];
};

type Payload = {
  citizen_id?: string;
  citizen_phone?: string;
  citizen_name?: string | null;
  image_url?: string;
  lat?: number;
  lng?: number;
  address_text?: string | null;
  nearest_landmark?: string | null;
  damage_type?: string | null;
  source_channel?: string | null;
  department_id?: number | null;
};

function isTrustedCaller(req: Request): boolean {
  const auth = req.headers.get("Authorization") ?? "";
  const apikey = req.headers.get("apikey") ?? "";
  const sharedSecret = req.headers.get("X-SSR-Secret") ?? "";
  const serviceBearer = `Bearer ${env.supabaseServiceRoleKey}`;
  return auth === serviceBearer ||
    apikey === env.supabaseServiceRoleKey ||
    sharedSecret === env.aiServiceSecret;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return methodNotAllowed();
  }

  if (!req.headers.get("Authorization")) {
    return unauthorized("Missing Authorization header.");
  }

  if (!isTrustedCaller(req)) {
    return forbidden("seed-test-ticket is restricted to trusted callers.");
  }

  let payload: Payload;
  try {
    payload = await req.json();
  } catch {
    return badRequest("Request body must be valid JSON.");
  }

  if (!payload.citizen_id) {
    return badRequest("citizen_id is required.");
  }
  if (!payload.citizen_phone) {
    return badRequest("citizen_phone is required.");
  }
  if (!payload.image_url) {
    return badRequest("image_url is required.");
  }

  const lat = Number(payload.lat ?? 17.6720);
  const lng = Number(payload.lng ?? 75.9300);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    return badRequest("lat and lng must be valid numbers.");
  }

  try {
    const adminClient = createAdminClient();
    const { data: seedRows, error: seedError } = await adminClient.rpc(
      "fn_seed_test_ticket",
      {
        p_citizen_id: payload.citizen_id,
        p_citizen_phone: payload.citizen_phone,
        p_citizen_name: payload.citizen_name ?? null,
        p_source_channel: payload.source_channel ?? "app",
        p_lat: lat,
        p_lng: lng,
        p_image_url: payload.image_url,
        p_address_text:
          payload.address_text ??
          "Majrewadi corridor near Solapur-Bijapur Road (citizen live test)",
        p_nearest_landmark: payload.nearest_landmark ?? "Majrewadi Naka",
        p_damage_type: payload.damage_type ?? "pothole",
        p_department_id: payload.department_id ?? 1,
      },
    );

    if (seedError) {
      throw seedError;
    }
    const insertedTicket = Array.isArray(seedRows) ? seedRows[0] : null;
    if (!insertedTicket) {
      throw new Error("fn_seed_test_ticket returned no rows.");
    }

    const ticketId = insertedTicket.id as string;
    const sourceChannel =
      (insertedTicket.source_channel as string | null) ?? "app";

    const detect = await callAiService<DetectResponse>("/detect-road-damage", {
      image_url: payload.image_url,
      ticket_id: ticketId,
      source_channel: sourceChannel,
    });

    if (!detect.success) {
      return upstreamFailure("AI damage detection failed.", detect);
    }

    const { error: detectUpdateError } = await adminClient
      .from("tickets")
      .update({
        damage_type: detect.damage_type,
        ai_confidence: detect.ai_confidence,
        total_potholes: detect.total_potholes,
        ai_bounding_boxes: detect.bounding_boxes,
        ai_severity_index: detect.ai_severity_index,
        ai_source: detect.ai_source,
      })
      .eq("id", ticketId);

    if (detectUpdateError) {
      throw detectUpdateError;
    }

    await logAuditEvent(
      adminClient,
      ticketId,
      "ai_detection",
      "AI damage detection completed from seed-test-ticket.",
      {
        detected: detect.detected,
        damage_type: detect.damage_type,
        ai_confidence: detect.ai_confidence,
        total_potholes: detect.total_potholes,
        ai_severity_index: detect.ai_severity_index,
        ai_source: detect.ai_source,
        model_version: detect.model_version,
        processing_ms: detect.processing_ms,
      },
    );

    const severity = await callAiService<SeverityResponse>("/score-severity", {
      damage_type: detect.damage_type,
      ai_confidence: detect.ai_confidence,
      total_potholes: detect.total_potholes,
      ai_severity_index: detect.ai_severity_index,
      road_class: "local",
      proximity_score: 0.5,
      rainfall_risk: null,
      lat,
      lng,
      dimensions: null,
    });

    if (!severity.success) {
      return upstreamFailure("AI severity scoring failed.", severity);
    }

    const { data: finalTicket, error: finalUpdateError } = await adminClient
      .from("tickets")
      .update({
        epdo_score: severity.epdo_score,
        severity_tier: severity.severity_tier,
      })
      .eq("id", ticketId)
      .select(
        "id, ticket_ref, status, zone_id, prabhag_id, assigned_je, citizen_id, citizen_phone, damage_type, ai_confidence, total_potholes, ai_bounding_boxes, ai_severity_index, ai_source, epdo_score, severity_tier, photo_before, created_at, updated_at, address_text",
      )
      .single();

    if (finalUpdateError) {
      throw finalUpdateError;
    }

    await logAuditEvent(
      adminClient,
      ticketId,
      "ai_severity",
      "EPDO severity score computed from seed-test-ticket.",
      {
        epdo_score: severity.epdo_score,
        severity_tier: severity.severity_tier,
        sla_hours: severity.sla_hours,
        ruleset_version: severity.ruleset_version,
        decision_trace: severity.decision_trace,
        processing_ms: severity.processing_ms,
      },
    );

    return ok({
      success: true,
      ticket: finalTicket,
      detect,
      severity,
    });
  } catch (error) {
    return upstreamFailure(
      "seed-test-ticket failed.",
      error instanceof Error ? error.message : error,
      500,
    );
  }
});
