import type { ContractorMetrics, Ticket, Zone } from '@/lib/types/database';
import { createServerSupabaseClient } from '@/lib/supabase/server';
import { EEDashboardClient } from './EEDashboardClient';
import {
  fetchEETechnicalReviewQueue,
  fetchWarrantyWatchTickets,
} from '@/lib/dashboard/eeTechnicalReview';

export default async function EEDashboardPage() {
  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const [{ data: zones }, { data: rawTickets }, { data: contractors }, initialQueue, initialWarrantyWatch] =
    await Promise.all([
      supabase
        .from('zones')
        .select('id, name, name_marathi, key_areas, annual_road_budget, budget_consumed, centroid_lat, centroid_lng')
        .order('id'),
      supabase
        .from('tickets')
        .select('id, status, zone_id, sla_breach, ssim_pass, severity_tier, assigned_contractor'),
      supabase
        .from('contractor_metrics')
        .select('contractor_id, total_completed, ssim_pass_rate, reopen_rate, quality_index')
        .order('quality_index', { ascending: false }),
      fetchEETechnicalReviewQueue(
        supabase as unknown as Parameters<typeof fetchEETechnicalReviewQueue>[0]
      ),
      fetchWarrantyWatchTickets(
        supabase as unknown as Parameters<typeof fetchWarrantyWatchTickets>[0]
      ),
    ]);

  return (
    <EEDashboardClient
      zones={(zones || []) as Zone[]}
      initialTickets={(rawTickets || []) as Ticket[]}
      contractors={(contractors || []) as ContractorMetrics[]}
      initialQueue={initialQueue}
      initialWarrantyWatch={initialWarrantyWatch}
    />
  );
}
