import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { callAiService } from "../_shared/ai.ts";
import { corsHeaders } from "../_shared/cors.ts";
import {
  badRequest,
  forbidden,
  methodNotAllowed,
  notFound,
  ok,
  unauthorized,
  upstreamFailure,
} from "../_shared/http.ts";
import { createAdminClient, createUserClient } from "../_shared/supabase.ts";
import { getVisibleTicket, logAuditEvent } from "../_shared/tickets.ts";

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

type DetectPayload = {
  ticket_id?: string;
  image_url?: string;
  source_channel?: string;
  captured_at?: string;
};

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

  let payload: DetectPayload;
  try {
    payload = await req.json();
  } catch {
    return badRequest("Request body must be valid JSON.");
  }

  if (!payload.ticket_id) {
    return badRequest("ticket_id is required.");
  }

  try {
    const userClient = createUserClient(req);
    const visibleTicket = await getVisibleTicket(
      userClient,
      payload.ticket_id,
      "id, ticket_ref, source_channel, photo_before",
    );

    if (!visibleTicket) {
      return forbidden("You are not allowed to run detection for this ticket.");
    }

    const imageUrl =
      payload.image_url ??
      ((visibleTicket.photo_before as string[] | null)?.[0] ?? null);

    if (!imageUrl) {
      return notFound("No before-photo found for this ticket.");
    }

    const ai = await callAiService<DetectResponse>("/detect-road-damage", {
      image_url: imageUrl,
      ticket_id: payload.ticket_id,
      captured_at: payload.captured_at ?? null,
      source_channel:
        payload.source_channel ??
        (visibleTicket.source_channel as string | null) ??
        "app",
    });

    if (!ai.success) {
      return upstreamFailure("AI damage detection failed.", ai);
    }

    const adminClient = createAdminClient();
    const patch = {
      damage_type: ai.damage_type,
      ai_confidence: ai.ai_confidence,
      total_potholes: ai.total_potholes,
      ai_bounding_boxes: ai.bounding_boxes,
      ai_severity_index: ai.ai_severity_index,
      ai_source: ai.ai_source,
    };

    const { data: updatedTicket, error: updateError } = await adminClient
      .from("tickets")
      .update(patch)
      .eq("id", payload.ticket_id)
      .select(
        "id, ticket_ref, damage_type, ai_confidence, total_potholes, ai_bounding_boxes, ai_severity_index, ai_source, updated_at",
      )
      .single();

    if (updateError) {
      throw updateError;
    }

    await logAuditEvent(
      adminClient,
      payload.ticket_id,
      "ai_detection",
      "AI damage detection completed.",
      {
        detected: ai.detected,
        damage_type: ai.damage_type,
        ai_confidence: ai.ai_confidence,
        total_potholes: ai.total_potholes,
        ai_severity_index: ai.ai_severity_index,
        ai_source: ai.ai_source,
        model_version: ai.model_version,
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
      "detect-road-damage bridge failed.",
      error instanceof Error ? error.message : error,
      500,
    );
  }
});

