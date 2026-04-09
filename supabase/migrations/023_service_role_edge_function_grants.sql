-- ============================================================
-- SSR SYSTEM — MIGRATION 023: SERVICE ROLE EDGE FUNCTION GRANTS
-- ============================================================
-- Edge Functions that use the service-role client still need base
-- table privileges before PostgREST will allow reads/updates.
-- Without these grants, trusted server-side bridges fail with:
--   permission denied for table tickets
-- even though service_role bypasses RLS.
-- ============================================================

GRANT SELECT, INSERT, UPDATE ON public.tickets TO service_role;
GRANT SELECT, INSERT ON public.ticket_events TO service_role;
GRANT SELECT ON public.profiles TO service_role;
GRANT SELECT ON public.sla_config TO service_role;
GRANT SELECT ON public.departments TO service_role;
GRANT SELECT ON public.zones TO service_role;
GRANT SELECT ON public.prabhags TO service_role;
GRANT SELECT ON public.rate_cards TO service_role;
