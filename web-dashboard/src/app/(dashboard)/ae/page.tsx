import { AEDashboardClient } from './AEDashboardClient';
import type { Profile, Ticket } from '@/lib/types/database';
import { createServerSupabaseClient } from '@/lib/supabase/server';

export default async function AEDashboardPage() {
  const supabase = await createServerSupabaseClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: profile } = await supabase
    .from('profiles')
    .select('zone_id')
    .eq('id', user.id)
    .single();

  if (!profile?.zone_id) return null;

  const { data: jes } = await supabase
    .from('profiles')
    .select('id, full_name, email, employee_id, role, zone_id, opi_score, opi_zone')
    .eq('role', 'je')
    .eq('zone_id', profile.zone_id);

  const { data: rules } = await supabase
    .from('escalation_rules')
    .select('rule_number, trigger_hours')
    .eq('rule_number', 1);
  const rule1Hours = rules?.[0]?.trigger_hours ?? 4;
  const rule1CutoffIso = new Date(Date.now() - rule1Hours * 60 * 60 * 1000).toISOString();

  const [{ data: metricsTickets }, { data: queueTickets }, rule1BreachResult] = await Promise.all([
    supabase
      .from('tickets')
      .select('id, ticket_ref, road_name, address_text, status, assigned_je, zone_id, created_at, updated_at, sla_breach')
      .eq('zone_id', profile.zone_id),
    supabase
      .from('tickets')
      .select('id, ticket_ref, road_name, address_text, status, assigned_je, zone_id, created_at, updated_at, sla_breach')
      .eq('zone_id', profile.zone_id)
      .order('updated_at', { ascending: false })
      .limit(20),
    supabase
      .from('tickets')
      .select('id', { count: 'exact', head: true })
      .eq('zone_id', profile.zone_id)
      .eq('status', 'open')
      .lt('created_at', rule1CutoffIso),
  ]);

  return (
    <AEDashboardClient
      jes={(jes || []) as Profile[]}
      initialMetricsTickets={(metricsTickets || []) as Ticket[]}
      initialQueueTickets={(queueTickets || []) as Ticket[]}
      zoneId={profile.zone_id}
      rule1Hours={rule1Hours}
      initialRule1BreachCount={rule1BreachResult.count ?? 0}
    />
  );
}
