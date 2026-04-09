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
import { createAdminClient, createUserClient } from "../_shared/supabase.ts";
import { getVisibleTicket, logAuditEvent } from "../_shared/tickets.ts";

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

type SeverityPayload = {
  ticket_id?: string;
  road_class?: string;
  proximity_score?: number;
  rainfall_risk?: number;
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

  let payload: SeverityPayload;
  try {
    payload = await req.json();
  } catch {
    return badRequest("Request body must be valid JSON.");
  }

  if (!payload.ticket_id) {
    return badRequest("ticket_id is required.");
  }

  try {
    const adminClient = createAdminClient();
    const visibleTicket = isTrustedCaller(req)
      ? await getVisibleTicket(
        adminClient,
        payload.ticket_id,
        "id, ticket_ref, damage_type, ai_confidence, total_potholes, ai_severity_index, road_class, proximity_score, rainfall_risk, latitude, longitude, dimensions",
      )
      : await getVisibleTicket(
        createUserClient(req),
        payload.ticket_id,
        "id, ticket_ref, damage_type, ai_confidence, total_potholes, ai_severity_index, road_class, proximity_score, rainfall_risk, latitude, longitude, dimensions",
      );

    if (!visibleTicket) {
      return forbidden("You are not allowed to score severity for this ticket.");
    }

    const aiSeverityIndex = Number(visibleTicket.ai_severity_index ?? 0);
    if (!Number.isFinite(aiSeverityIndex)) {
      return badRequest("Ticket does not have a valid ai_severity_index yet.");
    }

    const ai = await callAiService<SeverityResponse>("/score-severity", {
      damage_type: (visibleTicket.damage_type as string | null) ?? "pothole",
      ai_confidence: Number(visibleTicket.ai_confidence ?? 0),
      total_potholes: Number(visibleTicket.total_potholes ?? 0),
      ai_severity_index: aiSeverityIndex,
      road_class:
        payload.road_class ??
        (visibleTicket.road_class as string | null) ??
        "local",
      proximity_score:
        payload.proximity_score ??
        Number(visibleTicket.proximity_score ?? 0.5),
      rainfall_risk:
        payload.rainfall_risk ??
        (visibleTicket.rainfall_risk as number | null) ??
        null,
      lat: Number(visibleTicket.latitude),
      lng: Number(visibleTicket.longitude),
      dimensions: (visibleTicket.dimensions as Record<string, unknown> | null) ??
        null,
    });

    if (!ai.success) {
      return upstreamFailure("AI severity scoring failed.", ai);
    }

    const { data: updatedTicket, error: updateError } = await adminClient
      .from("tickets")
      .update({
        epdo_score: ai.epdo_score,
        severity_tier: ai.severity_tier,
      })
      .eq("id", payload.ticket_id)
      .select("id, ticket_ref, epdo_score, severity_tier, updated_at")
      .single();

    if (updateError) {
      throw updateError;
    }

    await logAuditEvent(
      adminClient,
      payload.ticket_id,
      "ai_severity",
      "EPDO severity score computed from AI output.",
      {
        epdo_score: ai.epdo_score,
        severity_tier: ai.severity_tier,
        sla_hours: ai.sla_hours,
        ruleset_version: ai.ruleset_version,
        decision_trace: ai.decision_trace,
        processing_ms: ai.processing_ms,
      },
    );

    return ok({
      success: true,
      ticket: updatedTicket,
      ai,
    });
  } catch (error) {
    return upstreamFailure(
      "score-severity bridge failed.",
      error instanceof Error ? error.message : error,
      500,
    );
  }
});
