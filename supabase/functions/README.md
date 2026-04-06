# Supabase Edge Functions

These functions are the missing bridge between the live Supabase project and the
deployed AI service at [https://road-nirman-ai.onrender.com](https://road-nirman-ai.onrender.com).

They do **not** replace normal app CRUD. Mobile/web should keep using Supabase
directly for auth, storage, and ticket data. These functions exist only for the
trusted AI steps.

## Functions

- `detect-road-damage`
  - Reads the caller-visible ticket
  - Pulls the first `photo_before`
  - Calls FastAPI `POST /detect-road-damage`
  - Updates AI detection fields on `public.tickets`

- `score-severity`
  - Reads ticket AI and location context
  - Calls FastAPI `POST /score-severity`
  - Updates `epdo_score` and `severity_tier`

- `verify-repair`
  - Reads ticket `photo_before[0]` and `photo_after`
  - Calls FastAPI `POST /verify-repair`
  - Updates `ssim_score`, `ssim_pass`, `verification_hash`, `verified_at`

## Required Secrets

Set these in Supabase before deploying:

```bash
supabase secrets set \
  AI_SERVICE_URL=https://road-nirman-ai.onrender.com \
  AI_SERVICE_SECRET=your-strong-shared-secret \
  SUPABASE_SERVICE_ROLE_KEY=your-service-role-key \
  SUPABASE_ANON_KEY=your-anon-key
```

`SUPABASE_URL` is usually available automatically in Supabase Functions. If your
project does not expose it automatically, set it explicitly as a secret too.

## Deploy

From the repo root:

```bash
supabase functions deploy detect-road-damage
supabase functions deploy score-severity
supabase functions deploy verify-repair
```

## Example Invocations

Use a normal authenticated Supabase session or JWT to invoke these, so the
function can verify the caller has row access to the target ticket before using
the service-role client for updates.

### Detect

```json
{ "ticket_id": "your-ticket-uuid" }
```

### Score Severity

```json
{ "ticket_id": "your-ticket-uuid" }
```

### Verify Repair

```json
{ "ticket_id": "your-ticket-uuid" }
```

Optional overrides are supported:
- `detect-road-damage`: `image_url`, `source_channel`, `captured_at`
- `score-severity`: `road_class`, `proximity_score`, `rainfall_risk`
- `verify-repair`: `before_image_url`, `after_image_url`
