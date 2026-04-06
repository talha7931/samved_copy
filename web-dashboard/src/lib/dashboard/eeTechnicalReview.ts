import type { Ticket } from '@/lib/types/database';

export interface TechnicalReviewTicket {
  id: string;
  ticket_ref: string;
  road_name: string | null;
  zone_id: number | null;
  approval_tier: 'moderate' | 'major';
  estimated_cost: number | null;
  status: Ticket['status'];
  job_order_ref: string | null;
  created_at: string;
  updated_at: string;
}

type SupabaseLike = {
  from: (table: string) => {
    select: (...args: unknown[]) => QueryLike;
  };
};

interface QueryLike extends PromiseLike<unknown> {
  in: (column: string, values: readonly unknown[]) => QueryLike;
  eq: (column: string, value: unknown) => QueryLike;
  is: (column: string, value: unknown) => QueryLike;
  not: (column: string, operator: string, value: unknown) => QueryLike;
  gte: (column: string, value: unknown) => QueryLike;
  lte: (column: string, value: unknown) => QueryLike;
  lt: (column: string, value: unknown) => QueryLike;
  order: (column: string, options: { ascending: boolean }) => QueryLike;
  limit: (value: number) => QueryLike;
}

export interface WarrantyWatchTicket {
  id: string;
  ticket_ref: string;
  road_name: string | null;
  zone_id: number | null;
  warranty_expiry: string | null;
  assigned_contractor: string | null;
}

export function getWarrantyWatchStartIso(now: Date = new Date()) {
  return now.toISOString();
}

export function getWarrantyWatchEndIso(now: Date = new Date()) {
  const future = new Date(now);
  future.setDate(future.getDate() + 30);
  return future.toISOString();
}

export function getRule3CutoffIso(now: Date = new Date()) {
  return new Date(now.getTime() - 120 * 60 * 60 * 1000).toISOString();
}

export async function fetchEETechnicalReviewQueue(
  supabase: SupabaseLike,
  limit = 50
): Promise<TechnicalReviewTicket[]> {
  const technicalQueueFields =
    'id, ticket_ref, road_name, zone_id, approval_tier, estimated_cost, status, job_order_ref, created_at, updated_at';
  const rule3CutoffIso = getRule3CutoffIso();

  const [verifiedResult, escalatedResult] = (await Promise.all([
    supabase
      .from('tickets')
      .select(technicalQueueFields)
      .in('approval_tier', ['moderate', 'major'])
      .eq('status', 'verified')
      .is('job_order_ref', null)
      .lt('updated_at', rule3CutoffIso)
      .order('created_at', { ascending: false })
      .limit(limit),
    supabase
      .from('tickets')
      .select(technicalQueueFields)
      .in('approval_tier', ['moderate', 'major'])
      .eq('status', 'escalated')
      .order('created_at', { ascending: false })
      .limit(limit),
  ])) as Array<{ data: unknown[] | null; error: { message: string } | null }>;

  if (verifiedResult.error) {
    throw new Error(verifiedResult.error.message);
  }

  if (escalatedResult.error) {
    throw new Error(escalatedResult.error.message);
  }

  const merged = new Map<string, TechnicalReviewTicket>();
  for (const row of [...(verifiedResult.data || []), ...(escalatedResult.data || [])]) {
    const ticket = row as TechnicalReviewTicket;
    merged.set(ticket.id, ticket);
  }

  return Array.from(merged.values()).sort(
    (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  );
}

export async function fetchWarrantyWatchTickets(
  supabase: SupabaseLike,
  limit = 20
): Promise<WarrantyWatchTicket[]> {
  const startIso = getWarrantyWatchStartIso();
  const endIso = getWarrantyWatchEndIso();
  const result = (await supabase
    .from('tickets')
    .select('id, ticket_ref, road_name, zone_id, warranty_expiry, assigned_contractor')
    .not('warranty_expiry', 'is', null)
    .gte('warranty_expiry', startIso)
    .lte('warranty_expiry', endIso)
    .order('warranty_expiry', { ascending: true })
    .limit(limit)) as { data: unknown[] | null; error: { message: string } | null };

  if (result.error) {
    throw new Error(result.error.message);
  }

  return (result.data || []) as WarrantyWatchTicket[];
}
