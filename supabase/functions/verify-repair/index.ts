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

type VerifyResponse = {
  success: boolean;
  ssim_score: number | null;
  ssim_pass: boolean;
  verdict: string;
  verification_hash: string | null;
  audit_reason: string;
  processing_ms: number;
  errors?: string[];
};

type VerifyPayload = {
  ticket_id?: string;
  before_image_url?: string;
  after_image_url?: string;
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

  let payload: VerifyPayload;
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
      "id, ticket_ref, photo_before, photo_after",
    );

    if (!visibleTicket) {
      return forbidden("You are not allowed to verify this ticket.");
    }

    const beforeImageUrl =
      payload.before_image_url ??
      ((visibleTicket.photo_before as string[] | null)?.[0] ?? null);
    const afterImageUrl =
      payload.after_image_url ??
      ((visibleTicket.photo_after as string | null) ?? null);

    if (!beforeImageUrl) {
      return notFound("No before-photo found for this ticket.");
    }

    if (!afterImageUrl) {
      return notFound("No after-photo found for this ticket.");
    }

    const ai = await callAiService<VerifyResponse>("/verify-repair", {
      before_image_url: beforeImageUrl,
      after_image_url: afterImageUrl,
      ticket_id: payload.ticket_id,
    });

    if (!ai.success) {
      return upstreamFailure("AI repair verification failed.", ai);
    }

    const adminClient = createAdminClient();
    const { data: updatedTicket, error: updateError } = await adminClient
      .from("tickets")
      .update({
        ssim_score: ai.ssim_score,
        ssim_pass: ai.ssim_pass,
        verification_hash: ai.verification_hash,
        verified_at: new Date().toISOString(),
      })
      .eq("id", payload.ticket_id)
      .select(
        "id, ticket_ref, ssim_score, ssim_pass, verification_hash, verified_at, updated_at",
      )
      .single();

    if (updateError) {
      throw updateError;
    }

    await logAuditEvent(
      adminClient,
      payload.ticket_id,
      "ssim_result",
      ai.audit_reason || "Repair verification completed.",
      {
        ssim_score: ai.ssim_score,
        ssim_pass: ai.ssim_pass,
        verdict: ai.verdict,
        verification_hash: ai.verification_hash,
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
      "verify-repair bridge failed.",
      error instanceof Error ? error.message : error,
      500,
    );
  }
});

