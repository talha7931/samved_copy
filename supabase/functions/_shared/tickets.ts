import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

type MaybeTicket = Record<string, unknown> | null;

export async function getVisibleTicket(
  userClient: SupabaseClient,
  ticketId: string,
  selectClause: string,
): Promise<MaybeTicket> {
  const { data, error } = await userClient
    .from("tickets")
    .select(selectClause)
    .eq("id", ticketId)
    .maybeSingle();

  if (error) {
    if (error.code === "PGRST116") {
      return null;
    }
    throw error;
  }

  return data as MaybeTicket;
}

export async function logAuditEvent(
  adminClient: SupabaseClient,
  ticketId: string,
  eventType: string,
  notes: string,
  metadata: Record<string, unknown>,
): Promise<void> {
  const { error } = await adminClient.rpc("fn_log_audit_event", {
    p_ticket_id: ticketId,
    p_event_type: eventType,
    p_notes: notes,
    p_metadata: metadata,
  });

  if (error) {
    console.warn("Audit event logging failed", {
      ticketId,
      eventType,
      error,
    });
  }
}

