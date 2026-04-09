-- Mobile assign flow sets job_order_ref together with assigned_* and status.
-- Exclude it from the JE catch-all row diff (same pattern as 024 check-in fields).

CREATE OR REPLACE FUNCTION public.fn_guard_ticket_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role user_role;
  v_old_rest tickets%ROWTYPE;
  v_new_rest tickets%ROWTYPE;
BEGIN
  SELECT role INTO v_caller_role FROM profiles WHERE id = auth.uid();

  IF v_caller_role IN ('city_engineer', 'commissioner', 'super_admin') THEN
    RETURN NEW;
  END IF;

  IF OLD.ticket_ref IS DISTINCT FROM NEW.ticket_ref THEN
    RAISE EXCEPTION 'ticket_ref is system-generated and immutable';
  END IF;
  IF OLD.zone_id IS DISTINCT FROM NEW.zone_id THEN
    RAISE EXCEPTION 'zone_id is system-routed and immutable';
  END IF;
  IF OLD.prabhag_id IS DISTINCT FROM NEW.prabhag_id THEN
    RAISE EXCEPTION 'prabhag_id is system-routed and immutable';
  END IF;
  IF OLD.assigned_je IS DISTINCT FROM NEW.assigned_je THEN
    RAISE EXCEPTION 'assigned_je is system-assigned and immutable';
  END IF;
  IF OLD.location IS DISTINCT FROM NEW.location
     OR OLD.latitude IS DISTINCT FROM NEW.latitude
     OR OLD.longitude IS DISTINCT FROM NEW.longitude THEN
    RAISE EXCEPTION 'Ticket location data is immutable after creation';
  END IF;

  v_old_rest := OLD;
  v_new_rest := NEW;
  v_old_rest.updated_at := NULL;
  v_new_rest.updated_at := NULL;

  IF v_caller_role = 'citizen' THEN
    v_old_rest.citizen_confirmed := NULL;
    v_new_rest.citizen_confirmed := NULL;
    v_old_rest.citizen_rating := NULL;
    v_new_rest.citizen_rating := NULL;
    v_old_rest.citizen_confirm_at := NULL;
    v_new_rest.citizen_confirm_at := NULL;
    IF v_old_rest IS DISTINCT FROM v_new_rest THEN
      RAISE EXCEPTION 'Citizens can only update feedback fields (citizen_confirmed, citizen_rating)';
    END IF;
    RETURN NEW;
  END IF;

  IF v_caller_role IN ('contractor', 'mukadam') THEN
    v_old_rest.photo_after := NULL;
    v_new_rest.photo_after := NULL;
    v_old_rest.status := NULL;
    v_new_rest.status := NULL;
    IF v_old_rest IS DISTINCT FROM v_new_rest THEN
      RAISE EXCEPTION 'Field executors (Contractor/Mukadam) can only update photo_after and status (to audit_pending)';
    END IF;
    RETURN NEW;
  END IF;

  IF v_caller_role = 'je' THEN
    v_old_rest.status := NULL;
    v_new_rest.status := NULL;
    v_old_rest.photo_je_inspection := NULL;
    v_new_rest.photo_je_inspection := NULL;
    v_old_rest.department_note := NULL;
    v_new_rest.department_note := NULL;
    v_old_rest.damage_cause := NULL;
    v_new_rest.damage_cause := NULL;

    IF OLD.status NOT IN ('open', 'verified') AND (
         OLD.work_type IS DISTINCT FROM NEW.work_type OR
         OLD.dimensions IS DISTINCT FROM NEW.dimensions OR
         OLD.rate_per_unit IS DISTINCT FROM NEW.rate_per_unit OR
         OLD.estimated_cost IS DISTINCT FROM NEW.estimated_cost OR
         OLD.rate_card_id IS DISTINCT FROM NEW.rate_card_id OR
         OLD.assigned_contractor IS DISTINCT FROM NEW.assigned_contractor OR
         OLD.assigned_mukadam IS DISTINCT FROM NEW.assigned_mukadam
       ) THEN
      RAISE EXCEPTION 'Economic details and assignments are locked after the ticket leaves the verification phase';
    END IF;

    v_old_rest.work_type := NULL;
    v_new_rest.work_type := NULL;
    v_old_rest.dimensions := NULL;
    v_new_rest.dimensions := NULL;
    v_old_rest.rate_per_unit := NULL;
    v_new_rest.rate_per_unit := NULL;
    v_old_rest.estimated_cost := NULL;
    v_new_rest.estimated_cost := NULL;
    v_old_rest.assigned_contractor := NULL;
    v_new_rest.assigned_contractor := NULL;
    v_old_rest.assigned_mukadam := NULL;
    v_new_rest.assigned_mukadam := NULL;
    v_old_rest.rate_card_id := NULL;
    v_new_rest.rate_card_id := NULL;
    v_old_rest.department_id := NULL;
    v_new_rest.department_id := NULL;

    v_old_rest.je_checkin_lat := NULL;
    v_new_rest.je_checkin_lat := NULL;
    v_old_rest.je_checkin_lng := NULL;
    v_new_rest.je_checkin_lng := NULL;
    v_old_rest.je_checkin_time := NULL;
    v_new_rest.je_checkin_time := NULL;
    v_old_rest.je_checkin_distance_m := NULL;
    v_new_rest.je_checkin_distance_m := NULL;

    v_old_rest.job_order_ref := NULL;
    v_new_rest.job_order_ref := NULL;

    IF v_old_rest IS DISTINCT FROM v_new_rest THEN
      RAISE EXCEPTION 'JE can only update workflow state, verify dimensions/cost, assign executors, and cross-assign department';
    END IF;
    RETURN NEW;
  END IF;

  IF v_caller_role IN ('ae', 'de', 'ee', 'assistant_commissioner') THEN
    v_old_rest.status := NULL;
    v_new_rest.status := NULL;
    IF v_old_rest IS DISTINCT FROM v_new_rest THEN
      RAISE EXCEPTION 'Zone officers can only update ticket status';
    END IF;
    RETURN NEW;
  END IF;

  IF v_caller_role = 'accounts' THEN
    v_old_rest.bill_id := NULL;
    v_new_rest.bill_id := NULL;
    v_old_rest.status := NULL;
    v_new_rest.status := NULL;
    IF v_old_rest IS DISTINCT FROM v_new_rest THEN
      RAISE EXCEPTION 'Accounts can only update bill_id and billing status';
    END IF;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;
