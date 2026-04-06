-- ============================================================
-- Citizen ticket INSERT runs triggers as authenticated. Without
-- SECURITY DEFINER, fn_generate_ticket_ref touches ticket_ref_counters
-- and fails with: permission denied for table ticket_ref_counters (42501).
-- Align with fn_assign_zone_and_prabhag / fn_assign_je.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_generate_ticket_ref()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_zone_num INT;
  v_prabhag_num INT;
  v_year INT;
  v_seq INT;
BEGIN
  v_zone_num := COALESCE(NEW.zone_id, 0);
  v_prabhag_num := COALESCE(NEW.prabhag_id, 0);
  v_year := EXTRACT(YEAR FROM NOW())::INT;

  INSERT INTO ticket_ref_counters (zone_id, ref_year, next_seq)
  VALUES (v_zone_num, v_year, 1)
  ON CONFLICT (zone_id, ref_year)
  DO UPDATE SET next_seq = ticket_ref_counters.next_seq + 1
  RETURNING next_seq INTO v_seq;

  NEW.ticket_ref := FORMAT(
    'SSR-Z%s-P%s-%s-%s',
    v_zone_num::TEXT,
    LPAD(v_prabhag_num::TEXT, 2, '0'),
    v_year::TEXT,
    LPAD(v_seq::TEXT, 4, '0')
  );

  RETURN NEW;
END;
$$;
