export interface CommissionerKpis {
  totalOpen: number;
  criticalOpen: number;
  chronicCount: number;
  resolvedToday: number;
  slaBreach: number;
}

type SupabaseLike = {
  from: (table: string) => {
    select: (...args: unknown[]) => QueryLike;
  };
};

interface QueryLike extends PromiseLike<unknown> {
  eq: (column: string, value: unknown) => QueryLike;
  neq: (column: string, value: unknown) => QueryLike;
  gte: (column: string, value: unknown) => QueryLike;
}

export function getIndiaTodayStartIso(now: Date = new Date()) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Kolkata',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(now);

  const year = parts.find((part) => part.type === 'year')?.value;
  const month = parts.find((part) => part.type === 'month')?.value;
  const day = parts.find((part) => part.type === 'day')?.value;

  if (!year || !month || !day) {
    const fallback = new Date(now);
    fallback.setHours(0, 0, 0, 0);
    return fallback.toISOString();
  }

  return new Date(`${year}-${month}-${day}T00:00:00+05:30`).toISOString();
}

export async function fetchCommissionerKpis(supabase: SupabaseLike): Promise<CommissionerKpis> {
  const todayStartIso = getIndiaTodayStartIso();
  const [
    openResult,
    criticalResult,
    chronicResult,
    resolvedTodayResult,
    slaResult,
  ] = (await Promise.all([
    supabase
      .from('tickets')
      .select('id', { count: 'exact', head: true })
      .neq('status', 'resolved')
      .neq('status', 'rejected'),
    supabase
      .from('tickets')
      .select('id', { count: 'exact', head: true })
      .eq('severity_tier', 'CRITICAL')
      .neq('status', 'resolved')
      .neq('status', 'rejected'),
    supabase.from('tickets').select('id', { count: 'exact', head: true }).eq('is_chronic_location', true),
    supabase
      .from('tickets')
      .select('id', { count: 'exact', head: true })
      .eq('status', 'resolved')
      .gte('resolved_at', todayStartIso),
    supabase.from('tickets').select('id', { count: 'exact', head: true }).eq('sla_breach', true),
  ])) as Array<{ count: number | null; error: { message: string } | null }>;

  const firstError =
    openResult.error ||
    criticalResult.error ||
    chronicResult.error ||
    resolvedTodayResult.error ||
    slaResult.error;

  if (firstError) {
    throw new Error(firstError.message);
  }

  return {
    totalOpen: openResult.count ?? 0,
    criticalOpen: criticalResult.count ?? 0,
    chronicCount: chronicResult.count ?? 0,
    resolvedToday: resolvedTodayResult.count ?? 0,
    slaBreach: slaResult.count ?? 0,
  };
}
