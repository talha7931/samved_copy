# रोड NIRMAN — Flutter Mobile App
## Complete Functionality Specification
### Version 1.0 — SAMVED Hackathon 2026

---

## 1. OVERVIEW

**App Name:** रोड NIRMAN  
**Platform:** Android (APK sideload — this milestone)  
**Backend:** Supabase (Auth + PostgreSQL + PostGIS + Storage + Realtime)  
**State Management:** Riverpod  
**Navigation:** go_router  
**Auth:** Supabase Phone OTP (real SMS, no mock)

The app serves **4 mobile roles**. All other roles (AE, DE, EE, Assistant Commissioner, City Engineer, Commissioner, Accounts, Standing Committee) receive a Web Handoff screen directing them to the web dashboard.

---

## 2. ROLE MAP

| Role | Access | Route After Login |
|---|---|---|
| `citizen` | Citizen flow | `/citizen/home` |
| `je` | JE field flow | `/je/home` |
| `mukadam` | Mukadam work orders | `/mukadam/home` |
| `contractor` | Contractor job orders | `/contractor/home` |
| All others | Web handoff screen | `/handoff` |
| No profile row | Account not found dialog | → `/register` |
| `is_active = false` | Blocked screen | `/blocked` |

---

## 3. AUTHENTICATION FLOW

### 3.1 Login Screen (`/login`)

**Phone entry → OTP → Profile gate**

```
Phone input (+91 prefix, 10 digits, starts with 6/7/8/9)
  ↓ signInWithOtp(phone, shouldCreateUser: true)
OTP entry (6 digits, auto-submit on 6th digit)
  ↓ verifyOTP(phone, token, type: sms)
Profile gate:
  profiles.maybeSingle() where id = auth.uid()
  → null         : sign out + show "Account Not Found" dialog → /register
  → is_active=false : sign out → /blocked
  → exists + active : route by role
```

**Post-OTP routing:**
```dart
switch (role) {
  'citizen'    → /citizen/home
  'je'         → /je/home
  'mukadam'    → /mukadam/home
  'contractor' → /contractor/home
  default      → /handoff
}
```

**UI elements:**
- "Register as New Citizen" outlined orange pill below OTP button
- "OR" divider
- Resend OTP countdown (30 seconds)

### 3.2 Registration Screen (`/register`)

**3-step flow in a single StatefulWidget with PageView**

**Step 0 — Phone Entry:**
- +91 prefix + 10-digit field
- Validation: required, exactly 10 digits, starts with 6/7/8/9
- "Send OTP" navy gradient pill
- "Already registered? Sign In →" orange link

**Step 1 — OTP Verification:**
- 6-digit field, auto-submit
- 30-second resend countdown
- After verify: check for existing profile via `maybeSingle()`
  - Profile exists → skip Step 2, route by role
  - No profile → proceed to Step 2

**Step 2 — Personal Details (minimal):**
- Full Name field (required, min 2 chars)
- Terms checkbox (required to enable CTA)
- "Create Account" orange gradient pill

**Profile INSERT on submit:**
```dart
await supabase.from('profiles').insert({
  'id': uid,
  'full_name': fullName,
  'phone': '+91$phone',
  'role': 'citizen',   // ALWAYS hardcoded — never from user input
  'is_active': true,
});
```

**Error handling:**
- PostgrestException code `23505` = phone already registered → sign out + go to `/login`

### 3.3 Blocked Screen (`/blocked`)
- Lock icon, "Account Inactive" message
- Zone office contact info
- "Sign Out" orange button → `supabase.auth.signOut()` → `/login`

### 3.4 Web Handoff Screen (`/handoff`)
- Detected role name + zone name displayed
- "Open Web Dashboard" CTA → `url_launcher`
- "Sign Out" link

---

## 4. CITIZEN FLOW

### 4.1 CitizenHomeScreen (`/citizen/home`)

**Layout:**
- Full-bleed `flutter_map` (OSM tiles) centered on Solapur `LatLng(17.6823, 75.9064)` zoom 13
- Floating pill top bar (navy/85 blur): initials avatar + "नमस्कार" + `profile.full_name` + bell icon
- Severity-colored map pins from open tickets
- Orange gradient FAB pill: "+ Report Road Damage" → `/citizen/report`
- Bottom sheet (45% height, white/80 blur): "Complaints near you" + SOLAPUR DISTRICT label + scrollable ticket cards
- Bottom nav: HOME | REPORT | TRACK | PROFILE (HOME active)

**Supabase queries:**
```dart
// Map pins — all open tickets (minimal columns)
supabase.from('tickets')
  .select('id, latitude, longitude, severity_tier, status, ticket_ref')
  .not('status', 'in', '(resolved,rejected)')
  .not('latitude', 'is', null)

// Bottom sheet — zone-scoped, EPDO sorted
supabase.from('tickets')
  .select('id, ticket_ref, severity_tier, latitude, longitude, address_text, photo_before, epdo_score, status')
  .eq('zone_id', profile.zoneId)
  .not('status', 'in', '(resolved,rejected)')
  .order('epdo_score', ascending: false)
  .limit(20)
```

**Map pin colors:**
- CRITICAL: `#BA1A1A` red, pulsing animation
- HIGH: `#E46500` orange
- MEDIUM: `#455F87` blue-grey
- LOW/resolved: `#22C55E` green

**Realtime:** Subscribe to tickets INSERT/UPDATE → refresh both queries.

**Ticket card content:** thumbnail (`photo_before[0]`), ticket_ref (JetBrains Mono), severity badge, distance from current GPS, address_text.

### 4.2 ReportDamageScreen (`/citizen/report`)

**Camera screen — full screen `CameraPreview`**

**On init:**
1. Request `camera` permission via `permission_handler`
2. Request `location` permission simultaneously
3. Permission denied → `AlertDialog` with explanation + settings button
4. Start `geolocator.getCurrentPosition(accuracy: high)` — runs silently in background
5. GPS timeout 15s → show retry option

**UI:**
- Top overlay: dark blur header, "REPORT DAMAGE" title, back arrow, info icon
- Bottom control panel: dark blur, flash toggle | 88px shutter button | "1×" zoom

**On shutter tap:**
- Capture photo → `Navigator.push` to `/citizen/ai-result` passing `{imageFile, gpsPosition}`
- No AI runs on this screen — photo capture only

### 4.3 AIDetectionResultScreen (`/citizen/ai-result`)

**On screen load — call FastAPI `/detect`:**
```dart
final uri = Uri.parse('${AppConstants.aiServiceUrl}/detect');
final request = http.MultipartRequest('POST', uri);
request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
request.fields['lat'] = gpsPosition.latitude.toString();
request.fields['lng'] = gpsPosition.longitude.toString();
request.headers['Authorization'] = 'Bearer ${supabase.auth.currentSession!.accessToken}';
```

**AI response fields used:**
- `detected` (bool)
- `damage_type` (string)
- `total_potholes` (int)
- `confidence` (float → shown as %)
- `epdo_score` (float)
- `severity_tier` (string)
- `sla_hours` (int)
- `repair_recommendation` (string)

**If AI unreachable:** allow manual submission with `ai_source: 'OFFLINE_ESTIMATE'`, null AI fields.

**Layout:**
- Top 40%: actual captured photo with dashed rectangle guide overlay
- Header: "ROAD SCANNER" + hamburger + avatar (dark blur)
- Bottom sheet (65%, scrollable):
  - "Pothole Detected" / "No Road Detected" + severity pill
  - Stats: POTHOLES | CONFIDENCE | EPDO (3-card grid)
  - SLA: "Response required within Xh"
  - Location captured card: pulsing green dot + coordinates (JetBrains Mono) + accuracy
  - TYPE OF DAMAGE selector: 2×2 grid (Pothole | Crack | Flooding | Surface) — AI pre-selects, user can override
  - QUALITY CHECKLIST: ☀️ Good lighting | 📐 Full damage | 🎯 Steady shot
  - Recommended Treatment card (left-border accent): treatment + approx cost
  - "Submit Report" navy gradient pill
  - "Retake Photo" outlined pill

**On "Submit Report":**
```dart
// 1. Upload photo
final fileName = 'before/${uid}_${timestamp}.jpg';
await supabase.storage.from('ticket-photos').upload(fileName, imageFile);
final photoUrl = supabase.storage.from('ticket-photos').getPublicUrl(fileName);

// 2. Insert ticket — zone/prabhag auto-assigned by DB trigger
await supabase.from('tickets').insert({
  'citizen_id': uid,
  'citizen_phone': profile.phone,
  'source_channel': 'app',
  'latitude': gpsPosition.latitude,
  'longitude': gpsPosition.longitude,
  'location': 'SRID=4326;POINT(${gpsPosition.longitude} ${gpsPosition.latitude})',
  'address_text': addressText,
  'damage_type': selectedDamageType,
  'ai_confidence': aiResult?.confidence,
  'epdo_score': aiResult?.epdoScore,
  'severity_tier': aiResult?.severityTier,
  'total_potholes': aiResult?.totalPotholes,
  'ai_source': aiResult != null ? 'YOLO_REAL' : 'OFFLINE_ESTIMATE',
  'photo_before': [photoUrl],
  'status': 'open',
});
```

**Note:** `zone_id` and `prabhag_id` are NEVER set by the app. The DB trigger `trg_assign_zone` (calls `fn_assign_zone_and_prabhag()`) sets them automatically from GPS.

**Navigate to:** `/citizen/confirmation` passing ticket row

### 4.4 SubmissionConfirmationScreen (`/citizen/confirmation`)

**No back button** — prevents double submit.

**Displays:**
- Shield checkmark icon (navy circle)
- "Report Submitted Successfully!"
- `ticket_ref` in JetBrains Mono (large orange)
- Zone name + Prabhag name (from returned ticket)
- Severity badge + EPDO score
- "Expected response within Xh" (from SLA config)

**Buttons:**
- "Track This Complaint" → `/citizen/tracker?ticketId=xxx`
- "Report Another" → `context.go('/citizen/home')`

### 4.5 MyComplaintsScreen (`/citizen/my-complaints`) — TRACK tab

**Query:**
```dart
supabase.from('tickets')
  .select('id, ticket_ref, status, severity_tier, address_text, created_at, resolved_at, photo_after, epdo_score')
  .eq('citizen_id', supabase.auth.currentUser!.id)
  .order('created_at', ascending: false)
```

**Filter tabs:** All | Pending | Active | Resolved
- Pending: status in `['open', 'verified']`
- Active: status in `['assigned', 'in_progress', 'audit_pending']`
- Resolved: status == `'resolved'`

**Ticket card:**
- "APPLICATION NUMBER" label + ticket_ref (JetBrains Mono)
- Severity badge pill (top right)
- Location text
- Horizontal status stepper (4 nodes): RECEIVED → VERIFIED → FIXING → RESOLVED
- Resolved tickets: "View Repair Proof →" orange link

**Stepper node mapping:**
- `open` → step 0 active
- `verified` → step 1 active
- `assigned` / `in_progress` → step 2 active
- `audit_pending` / `resolved` → step 3 active

**Realtime:** Subscribe to tickets where `citizen_id = uid`.

### 4.6 ComplaintTrackerScreen (`/citizen/tracker`)

**Queries:**
```dart
// Ticket detail
supabase.from('tickets')
  .select('*, zones!tickets_zone_id_fkey(name), prabhags!tickets_prabhag_id_fkey(name)')
  .eq('id', ticketId)
  .single()

// Latest event
supabase.from('ticket_events')
  .select('event_type, notes, created_at, actor_role')
  .eq('ticket_id', ticketId)
  .order('created_at', ascending: false)
  .limit(1)
```

**Layout:**
- Top bar: "Complaint Status" + back + share
- Reference card: ticket_ref (large mono) + "Updated X mins ago" + severity + address + date + EPDO + SLA
- Latest Update card (orange left border, cream bg): latest ticket_event notes
- "Current Progress" vertical timeline stepper (5 steps):
  - Received → Verified → JE Inspection → Repair Assigned → Resolved
  - Completed: orange filled + checkmark
  - Current: pulsing navy + white dot
  - Future: grey empty
- "Contact Zone Office" navy gradient pill

**Fields NOT shown to citizen:**
- `ai_confidence`, `total_potholes`, `epdo_score` (raw), `ssim_score`, `verification_hash`, `rate_per_unit`, `estimated_cost`

**Realtime:** Subscribe to `tickets` where `id = ticketId`.

### 4.7 ProfileScreen (`/citizen/profile`)

**Data:** from Riverpod `profileProvider` — no re-fetch.

**Sections:**
- Header (navy bg): initials avatar + `full_name` + phone + "Citizen · Zone X — {zone_name}" + Edit button
- Language card: English | मराठी toggle (persisted via `shared_preferences`)
- Notifications card: Status Updates | JE Dispatched | Complaint Resolved toggles (persisted)
- Help card: How to report | Contact Zone Office | Privacy Policy
- Footer: "Sign Out" orange + version string + system code

**Sign out:**
```dart
await supabase.auth.signOut();
context.go('/login');
```

---

## 5. JE (JUNIOR ENGINEER) FLOW

### 5.1 JEHomeScreen (`/je/home`)

**Queries:**
```dart
// Zone-scoped open tickets, EPDO sorted
supabase.from('tickets')
  .select('id, ticket_ref, status, severity_tier, latitude, longitude, address_text, epdo_score, created_at')
  .eq('zone_id', profile.zoneId)
  .not('status', 'in', '(resolved,rejected)')
  .order('epdo_score', ascending: false)
```

**Layout:**
- Top bar (white): JE avatar + "Zone X Tasks" headline + name mono + bell
- Dark flutter_map (42% height): OSM dark tiles, ticket severity pins, JE blue pulsing dot
- Floating white pill badge: "X tickets • Nearest first"
- "CURRENT QUEUE" section + "Zonal Tickets" headline + pending count badge
- Ticket cards with left severity color bar (4px)
- "ROUTE OPTIMIZE" navy gradient FAB (bottom right) — client-side sort by distance
- Bottom nav: TASKS | MAP | ROUTES | PROFILE (TASKS active, navy pill)

**Card content:** ticket_ref (mono) + severity badge + road name + distance + STATUS_LABELS[status]

**Route Optimize FAB:** re-sorts fetched array by `Geolocator.distanceBetween()` from JE current GPS. No API call.

**Realtime:** Subscribe to tickets where `zone_id = profile.zoneId`.

### 5.2 JETicketDetailScreen (`/je/ticket/:ticketId`)

**Query:**
```dart
supabase.from('tickets')
  .select('''
    *, 
    zones!tickets_zone_id_fkey(name),
    prabhags!tickets_prabhag_id_fkey(name),
    departments!tickets_department_id_fkey(name, map_pin_color),
    citizen:profiles!tickets_citizen_id_fkey(full_name),
    assigned_je
  ''')
  .eq('id', ticketId)
  .single()
```

**Layout:**
- Top bar: ticket_ref mono centered + back + share
- Hero 16:9: `photo_before[0]` + severity pill overlay + "Citizen Evidence" blur badge
- "SSR TICKET" label pill
- रोड NIRMAN headline
- Status badge + "JE: {profile.full_name}"
- Location card: zone + prabhag + address + "View on Map →"
- AI Analysis card (blue-tinted): POTHOLES | CONFIDENCE | EPDO (JE sees these, citizen does not)
- Citizen info row: name + "X hours ago via {source_channel}"
- Department row: badge + "Change Department →"
- JE Field Notes (dashed): empty until after check-in
- Sticky bottom: "Begin Site Check-In →" + "Reject Complaint" grey link

**Reject logic:**
```dart
await supabase.from('tickets').update({'status': 'rejected'}).eq('id', ticketId);
await supabase.from('ticket_events').insert({
  'ticket_id': ticketId,
  'actor_id': uid,
  'actor_role': 'je',
  'event_type': 'status_change',
  'old_status': ticket['status'],
  'new_status': 'rejected',
  'notes': 'Rejected by JE after review',
});
```

**Change Department:** bottom sheet with departments fetched from `departments` table → update `ticket.department_id`.

### 5.3 JESiteCheckInScreen (`/je/checkin/:ticketId`)

**Geofence threshold:** 20 metres (hardcoded in `AppConstants.geofenceRadiusM = 20.0`)

**Timer:** `Timer.periodic(Duration(seconds: 2))` — refresh JE GPS every 2 seconds. Cancel in `dispose()`.

**Distance:** `Geolocator.distanceBetween(jeLat, jeLng, ticketLat, ticketLng)`

**Layout:**
- Top bar: "Site Check-In" centered + back
- Ticket context card: ticket_ref + severity + address
- Circular arc gauge (`CustomPainter`): fills as JE approaches. Center shows distance + "m" + "of 20m threshold"
- Status pill: green "Within range — ready to verify" OR grey "Move closer (Xm away)"
- GPS comparison card (2 columns): Reported spot | JE current (both JetBrains Mono)
- "Accuracy Confirmed" card (shown only when ≤ 20m)
- "Verify Site ✓✓" navy pill — **programmatically disabled** when distance > 20m
- "YOUR GPS CHECK-IN WILL BE RECORDED WITH TIMESTAMP" caption

**On "Verify Site" (only if distance ≤ 20m):**
```dart
final position = await Geolocator.getCurrentPosition();
await supabase.from('tickets').update({
  'je_checkin_lat': position.latitude,
  'je_checkin_lng': position.longitude,
  'je_checkin_time': DateTime.now().toIso8601String(),
  'je_checkin_distance_m': distance,
  'status': 'verified',
}).eq('id', ticketId);

await supabase.from('ticket_events').insert({
  'ticket_id': ticketId,
  'actor_id': uid,
  'actor_role': 'je',
  'event_type': 'je_checkin',
  'old_status': 'open',
  'new_status': 'verified',
  'notes': 'JE checked in at site. Distance: ${distance.toStringAsFixed(1)}m',
  'metadata': {'checkin_lat': lat, 'checkin_lng': lng, 'distance_m': distance},
});
```

Navigate to: `/je/measure/$ticketId`

### 5.4 JEMeasureEstimateScreen (`/je/measure/:ticketId`)

**Top bar:** navy #022448 + "Measurement & Estimation" white + back + more_vert

**Inputs:**
- Length (metres) | Width (metres) | Depth (centimetres) — 3 input cards
- Area auto-calculated live: `area_sqm = length_m * width_m`
- Area pill: "Area: X.XX sqm" (secondary container style)

**Work Type dropdown:** fetched from `rate_cards`:
```dart
supabase.from('rate_cards')
  .select('id, work_type, work_type_marathi, unit, rate_per_unit')
  .eq('is_active', true)
  .or('zone_id.is.null,zone_id.eq.${profile.zoneId}')
  .eq('fiscal_year', '2025-26')
```

**Rate Card display (READ ONLY):**
- TertiaryFixed warm cream card
- Lock icon + "RATE CARD FY 2025-26"
- `₹{rate_per_unit}` / unit — JE cannot type a rate
- "Approved by City Engineer • Cannot be modified"

**Primary Cause selector:** Roads | Water Supply | Drainage | MSEDCL (colored dots)
Maps to `damage_cause` enum: `poor_construction` | `utility_water` | `utility_drainage` | `utility_electricity`

**Estimated Cost (READ ONLY, locked):**
```dart
estimatedCost = area_sqm * selectedRateCard.ratePerUnit
```
Lock icon shown. JetBrains Mono. Formula pill: "X sqm × ₹Y = ₹Z"

**Validation before submit:** length > 0, width > 0, work_type selected, damage_cause selected.

**On "Approve & Assign Executor":**
```dart
await supabase.from('tickets').update({
  'dimensions': {
    'length_m': lengthM,
    'width_m': widthM,
    'depth_m': depthCm / 100,
    'area_sqm': areaSqm,
  },
  'work_type': selectedRateCard.workType,
  'rate_card_id': selectedRateCard.id,
  'rate_per_unit': selectedRateCard.ratePerUnit,
  'estimated_cost': estimatedCost,
  'damage_cause': selectedDamageCause,
}).eq('id', ticketId);

await supabase.from('ticket_events').insert({...}); // measurement_recorded event
```

Navigate to: `/je/assign/$ticketId`

### 5.5 JEExecutorAssignmentScreen (`/je/assign/:ticketId`)

**XOR Selector:** "Department Gang" | "Private Contractor" — selecting one deselects the other. Both start unselected. CTA disabled until one is selected AND a specific person is chosen.

**If Department Gang selected:**
```dart
supabase.from('profiles')
  .select('id, full_name, phone')
  .eq('role', 'mukadam')
  .eq('zone_id', profile.zoneId)
  .eq('is_active', true)
```
Shows Mukadam picker with initials avatar + name + "Zone X Gang Leader" + "AVAILABLE" pill.

**If Private Contractor selected:**
```dart
supabase.from('contractors')
  .select('id, company_name, profiles!contractors_id_fkey(full_name)')
  .contains('zone_ids', [profile.zoneId])
  .eq('is_blacklisted', false)
```

**Locked Summary card (top):** ticket_ref, address, work_type, `₹estimated_cost` — all READ ONLY.

**Draft Job Order card:** shown after executor selected — navy gradient dark card with job order ref.

**Warning card:** "Once assigned, executor cannot be changed without Executive Engineer approval."

**Job order ref format:** `'JO-${ticket_ref.replaceFirst('SSR-', '')}'`

**On "Generate Job Order & Assign":**
```dart
// XOR enforcement — always set the other to null
if (selectedMukadamId != null) {
  updateData['assigned_mukadam'] = selectedMukadamId;
  updateData['assigned_contractor'] = null;
} else {
  updateData['assigned_contractor'] = selectedContractorId;
  updateData['assigned_mukadam'] = null;
}
updateData['status'] = 'assigned';
updateData['job_order_ref'] = jobOrderRef;

await supabase.from('tickets').update(updateData).eq('id', ticketId);
await supabase.from('ticket_events').insert({...}); // assignment event
```

Navigate to: `/je/home`

---

## 6. MUKADAM FLOW

### 6.1 MukadamHomeScreen (`/mukadam/home`)

**Fields Mukadam NEVER sees:** rate_per_unit, estimated_cost, billing, payment, job_order_ref, SHA-256 hash, SSIM percentage score.

**Query:**
```dart
supabase.from('tickets')
  .select('''
    id, ticket_ref, status, severity_tier,
    address_text, work_type, dimensions,
    created_at, updated_at,
    zones!tickets_zone_id_fkey(name),
    prabhags!tickets_prabhag_id_fkey(name),
    profiles!tickets_assigned_je_fkey(full_name)
  ''')
  .eq('assigned_mukadam', supabase.auth.currentUser!.id)
  .inFilter('status', ['assigned', 'in_progress', 'audit_pending'])
  .order('created_at', ascending: false)
```

**Summary bar (computed from fetched array):**
- Orange dot: count where status == `'assigned'`
- Navy dot: count where status == `'in_progress'`
- Green dot: count where status == `'audit_pending'`

**Filter tabs:** All | Assigned | In Progress | Completed (audit_pending maps to Completed tab)

**Card content:** WORK ORDER label (not JO), ticket_ref mono, severity, address headline, work_type + area_sqm, "Assigned by JE {name}", SLA due time, progress bar for in_progress cards, "View Instructions →" navy link.

**Bottom nav:** ORDERS | MAP | HISTORY | PROFILE (ORDERS active)

**Realtime:** subscribe to tickets where `assigned_mukadam = uid`.

### 6.2 MukadamWorkOrderDetailScreen (`/mukadam/detail/:ticketId`)

**Query:**
```dart
supabase.from('tickets')
  .select('''
    *, 
    zones!tickets_zone_id_fkey(name),
    prabhags!tickets_prabhag_id_fkey(name),
    departments!tickets_department_id_fkey(name),
    citizen:profiles!tickets_citizen_id_fkey(full_name),
    je:profiles!tickets_assigned_je_fkey(full_name, phone)
  ''')
  .eq('id', ticketId)
  .single()
```

**JE Field Notes:** fetch from `ticket_events` where `event_type = 'je_checkin'` → show `notes` field.

**Status stepper labels (Mukadam-specific):**
- Step 0: Assigned
- Step 1: Gang Deployed
- Step 2: Work Completed
- Step 3: Verified by JE

**Step mapping:**
- `assigned` → step 0
- `in_progress` → step 1
- `audit_pending` → step 2
- `resolved` → step 3 complete

**Departmental Notice card** (always visible):
"Executed by SMC Department Work Gang" + "THIS IS NOT CONTRACTOR WORK. NO BILLING APPLIES."

**Contact JE row:** `url_launcher` phone call to JE phone.

**Sticky CTA:**
- `assigned` → "START GANG DEPLOYMENT" orange gradient
- `in_progress` → "Submit Completion Proof →" navy gradient
- `audit_pending` → grey disabled pill

**Start Gang Deployment:**
```dart
await supabase.from('tickets').update({
  'status': 'in_progress',
}).eq('id', ticketId);

await supabase.from('ticket_events').insert({
  'ticket_id': ticketId, 'actor_id': uid, 'actor_role': 'mukadam',
  'event_type': 'status_change',
  'old_status': 'assigned', 'new_status': 'in_progress',
  'notes': 'Gang deployment started by Mukadam ${profile.fullName}',
  'metadata': {'started_at': DateTime.now().toIso8601String()},
});
```

Navigate to: `/mukadam/inprogress/$ticketId`

### 6.3 MukadamInProgressScreen (`/mukadam/inprogress/:ticketId`)

**Live timer:** `Timer.periodic(Duration(seconds: 1))` — compute `DateTime.now().difference(ticket.updatedAt)`. Cancel in `dispose()`.

**SLA deadline:** fetch from `sla_config` where `severity = ticket.severity_tier` → `resolution_hours`.

**Work Scope card:** work_type | area_sqm | depth (cm) — 3 stat tiles.

**Site Checklist (local state, 4 items):**
1. Base layer cleared and prepared
2. Repair material applied to surface
3. Surface compacted and levelled
4. Site cleaned and debris removed

State: `List<bool> checked = [false, false, false, false]`
Progress chip: "X of 4 complete" orange pill.

**Field Notes:** optional text area, stored in local state, submitted with proof.

**Flag Blocker row:** → `/mukadam/issue/$ticketId`

**Contact JE row:** initials avatar + JE name + phone call icon.

**Submit CTA:** disabled until all 4 checked. On tap → `/mukadam/camera/$ticketId` passing `fieldNotes`.

**Warning below CTA:** "Submitting proof is final. Ensure all repairs are complete before proceeding."

### 6.4 MukadamProofCameraScreen (`/mukadam/camera/:ticketId`)

**Full screen dark camera. No bottom nav.**

**Ghost overlay:** `Image.network(ticket.photo_before[0])` at 40% opacity over `CameraPreview`.

**Dashed rectangle guide:** 72% width, 55% height, 16px rounded, white dashed, L-bracket corner guides.

**Simple status strip:** green pulsing dot + "Surface Change: Detected ✓" (UI affordance — always green when camera is active).

**No SSIM percentage. No SHA-256 hash shown.**

**On shutter tap:**
```dart
// 1. Capture
final imageFile = await _cameraController.takePicture();

// 2. Upload to after-photos bucket
final fileName = 'after/${uid}_${timestamp}.jpg';
await supabase.storage.from('after-photos').upload(fileName, File(imageFile.path));
final photoUrl = supabase.storage.from('after-photos').getPublicUrl(fileName);

// 3. Update ticket
await supabase.from('tickets').update({
  'photo_after': photoUrl,
  'status': 'audit_pending',
}).eq('id', ticketId);

// 4. Insert audit event
await supabase.from('ticket_events').insert({
  'ticket_id': ticketId, 'actor_id': uid, 'actor_role': 'mukadam',
  'event_type': 'photo_upload',
  'old_status': 'in_progress', 'new_status': 'audit_pending',
  'notes': fieldNotes ?? 'Completion proof submitted by Mukadam',
});
```

**Result overlay (green wash):**
- Shield checkmark
- "Work Completion Recorded"
- Ticket ref + timestamp
- "Return to Work Orders" → `context.go('/mukadam/home')`

**Error:** upload failure → red SnackBar + retry. Do not navigate away.

### 6.5 MukadamIssueScreen (`/mukadam/issue/:ticketId`)

**Issue types (6 tiles):** Access Blocked | Rain/Weather | Material Delay | Site Mismatch | Safety Issue | Other

**Urgency:** Low | Medium (default) | Critical

**Notes:** required, min 10 chars.

**JE notification preview card:** fetch JE profile (`profiles where id = ticket.assigned_je`), show initials avatar + name + zone.

**CTA disabled if:** no issue type selected OR notes < 10 chars.

**On submit:**
```dart
await supabase.from('ticket_events').insert({
  'ticket_id': ticketId, 'actor_id': uid, 'actor_role': 'mukadam',
  'event_type': 'escalation',
  'notes': '$selectedIssueType: ${notes}',
  'metadata': {'issue_type': selectedIssueType, 'urgency': urgencyLevel},
});
```

**Does NOT change ticket status.** Shows success SnackBar → pop back to detail screen.

### 6.6 MukadamSubmissionCompleteScreen (`/mukadam/submitted`)

**Back button goes to `/mukadam/home` (not camera).**

**Receipt card:** work_ref, submitted_at, submitted_by (profile.full_name + " · Gang Leader"), zone, "PENDING JE REVIEW" badge.

**What Happens Next card (3 steps):**
1. JE Site Verification (within 24h)
2. Quality Assessment
3. Work Order Closed in SMC system

**No payment step. No billing step.**

### 6.7 MukadamProfileScreen (`/mukadam/profile`)

**Gang Info card:**
- Zone: from `zones` table
- Gang Size: "8 Workers" (static for now)
- Department: "Roads Dept"
- This Week: count from `tickets where assigned_mukadam = uid AND status IN ('audit_pending','resolved') AND updated_at > 7 days ago`

**Language:** English | मराठी (shared_preferences)

**Notifications:** 3 toggles (shared_preferences)

**Sign Out:** `supabase.auth.signOut()` → `/login`

---

## 7. CONTRACTOR FLOW

### 7.1 ContractorHomeScreen (`/contractor/home`)

**Query:**
```dart
supabase.from('tickets')
  .select('''
    id, ticket_ref, status, severity_tier,
    address_text, work_type, dimensions,
    estimated_cost, rate_per_unit, job_order_ref,
    created_at, updated_at,
    zones!tickets_zone_id_fkey(name),
    prabhags!tickets_prabhag_id_fkey(name),
    profiles!tickets_assigned_je_fkey(full_name)
  ''')
  .eq('assigned_contractor', supabase.auth.currentUser!.id)
  .is_('assigned_mukadam', null)
  .inFilter('status', ['assigned', 'in_progress', 'audit_pending', 'resolved'])
  .order('created_at', ascending: false)
```

**Stats bar (computed):**
- "X Active" (assigned + in_progress count)
- "₹X,XXX Pending" (sum of estimated_cost for audit_pending tickets)
- "X Completed" (resolved count)

**Filter tabs:** All | Active | Pending Payment | Completed

**Card content:** JO ref (JetBrains Mono) + severity badge + address headline + zone/prabhag + work_type + **cost row** (rate/sqm · area · = ₹total in orange) + SLA row + "View Details →" orange link

**Bottom nav:** ORDERS | MAP | BILLING | PROFILE (ORDERS active, BILLING has orange dot if audit_pending count > 0)

### 7.2 ContractorJobDetailScreen (`/contractor/detail/:ticketId`)

**Same query structure as Mukadam detail + joins.**

**Billing Card (Contractor ONLY — does not exist in Mukadam flow):**
- TertiaryFixed warm cream background
- Lock icon + "BILLING SUMMARY"
- `₹rate_per_unit / sqm` large + lock icon
- Area: `dimensions.area_sqm sqm`
- Total: `₹estimated_cost` extra large orange JetBrains Mono
- "PENDING APPROVAL" badge
- "Payment processed after SMC Accounts verification"

**Status stepper (Contractor labels):**
- Assigned → In Progress → Proof Submitted → Payment Pending

**Sticky CTA:**
- `assigned` → "Start Work" orange gradient + timestamp disclaimer
- `in_progress` → "Submit Proof of Repair →" navy gradient
- `audit_pending` → grey disabled "Proof Submitted — Awaiting SMC Verification"

### 7.3 ContractorInProgressScreen (`/contractor/inprogress/:ticketId`)

**Same timer logic as Mukadam.**

**Additional contractor-specific card — Evidence Readiness:**
- Before photo loaded: READY ✓
- GPS location locked: READY ✓
- Timestamp recording: ACTIVE

**Quality checklist labels (slightly different from Mukadam):**
1. Road surface thoroughly cleaned before patching
2. Hot mix applied at correct depth
3. Surface compacted with roller or plate
4. Debris removed and site cleared

**Payment urgency line:** "₹{estimated_cost} at stake — complete on time" (orange, contractor-specific)

**Submit CTA leads to:** `/contractor/camera/$ticketId`

### 7.4 ContractorGhostCameraScreen (`/contractor/camera/:ticketId`)

**Same camera flow as Mukadam BUT shows:**
- SSIM live strip: "Surface Change Detection" progress bar + percentage
- SHA-256 preview: "SHA-256: Calculating..." JetBrains Mono tiny
- After capture: SHA-256 hash displayed on success overlay
- Rejection: SSIM score shown ("SSIM Score: 0.82 — threshold is 0.75")

**Upload path:** `after/${uid}_${timestamp}.jpg` in `after-photos` bucket.

**Result overlay (VERIFIED):**
- "REPAIR VERIFIED ✓"
- SHA-256 hash truncated
- "Return to Work Orders"

**Result overlay (REJECTED):**
- "SURFACE UNCHANGED"
- SSIM score shown
- "Retake Photo"

### 7.5 ContractorIssueScreen (`/contractor/issue/:ticketId`)

**Same as Mukadam issue screen BUT:**
- 6th tile: "Contract Dispute" instead of "Other"
- Job Impact card (contractor-only): "₹{estimated_cost} at risk" + "SLA: Xh remaining"
- Disclaimer: "This issue will be permanently recorded in the job audit trail."
- All events logged against job_order_ref for audit trail.

### 7.6 ContractorSubmissionCompleteScreen (`/contractor/submitted`)

**Additional fields vs Mukadam:**
- SSIM Score: "0.42 — VERIFIED" green
- SHA-256: first 12 chars + "..."
- Amount Claimed: `₹estimated_cost` orange bold

**Billing Pipeline card (Contractor ONLY):**
4-step vertical pipeline:
1. ✓ Proof Submitted (done)
2. ◉ JE Quality Verification (current)
3. ○ Accounts Review
4. ○ Payment Released

**Buttons:** "Download Receipt PDF" + "Return to Work Orders"

### 7.7 ContractorProfileScreen (`/contractor/profile`)

**Contract Details card (Contractor ONLY):**
- Zone assignment + Contract #
- GST number + PAN (from `contractors` table)
- Valid Until + "ACTIVE" badge

**Billing Summary card (Contractor ONLY):**
- Total Billed: sum of all bill amounts FY
- Pending Approval: audit_pending sum
- Paid to Date: resolved sum
- "View Full Billing History →" link

**Notifications toggles (contractor-specific):**
- New Job Assignments
- Payment Status Updates
- SLA Breach Alerts

---

## 8. STATUS LABEL MAP

| DB Status | Citizen label | Mukadam label | Contractor/JE label |
|---|---|---|---|
| `open` | Received | — | Received |
| `verified` | Verified | — | Verified |
| `assigned` | Repair Assigned | Assigned | Assigned |
| `in_progress` | Fixing | In Progress | In Progress |
| `audit_pending` | Quality Check | Pending Verification | Proof Submitted |
| `resolved` | Resolved | Completed | Completed |
| `rejected` | Rejected | — | Rejected |
| `escalated` | Escalated | — | Escalated |

---

## 9. SUPABASE SCHEMA — KEY TABLES REFERENCE

### profiles
| Column | Type | Notes |
|---|---|---|
| id | UUID | = auth.uid() |
| full_name | TEXT | Required |
| phone | VARCHAR(15) | Unique |
| role | user_role enum | citizen/je/mukadam/contractor/... |
| zone_id | INT → zones | Null for citizen |
| employee_id | VARCHAR(20) | SMC code |
| is_active | BOOLEAN | false = blocked |

### tickets (key columns for mobile)
| Column | Type | Who writes |
|---|---|---|
| latitude/longitude | FLOAT | Citizen (on insert) |
| location | GEOGRAPHY | Citizen (on insert) |
| zone_id/prabhag_id | INT | **DB trigger only** — never app |
| photo_before | TEXT[] | Citizen |
| photo_after | TEXT | Mukadam/Contractor |
| status | ticket_status | State machine (see below) |
| assigned_je | UUID | **DB trigger only** |
| assigned_contractor | UUID | JE only |
| assigned_mukadam | UUID | JE only (XOR with contractor) |
| dimensions | JSONB | JE only |
| rate_per_unit | NUMERIC | JE only (from rate_cards) |
| estimated_cost | NUMERIC | JE only (area × rate) |
| job_order_ref | TEXT | JE only |
| je_checkin_* | FLOAT/TIMESTAMPTZ | JE only |
| ssim_score/ssim_pass | FLOAT/BOOL | AI service only |
| verification_hash | VARCHAR(64) | AI service only |

### State machine (enforced by DB trigger `trg_ticket_state_machine`):
```
open → verified (JE + dimensions + rate required)
verified → assigned (JE + exactly one executor required)
assigned → in_progress (Mukadam or Contractor)
in_progress → audit_pending (photo_after required)
audit_pending → resolved (ssim_pass OR citizen_confirmed required)
```

**No state can be skipped. The DB enforces this.**

---

## 10. STORAGE BUCKETS

| Bucket | Public | Who Writes | Path Format |
|---|---|---|---|
| `ticket-photos` | Yes | Citizen | `before/{uid}_{timestamp}.jpg` |
| `after-photos` | Yes | Mukadam, Contractor | `after/{uid}_{timestamp}.jpg` |
| `je-inspection` | No | JE only | `inspection/{uid}_{timestamp}.jpg` |

**RLS on storage:** paths must start with `{uid}_` prefix. Enforced by migration 017.

---

## 11. CONSTANTS

```dart
class AppConstants {
  static const String aiServiceUrl = String.fromEnvironment(
    'AI_SERVICE_URL',
    defaultValue: 'https://ssr-ai.railway.app',
  );
  static const double geofenceRadiusM = 20.0;      // JE check-in gate
  static const double ssimPassThreshold = 0.75;    // Inverse: < 0.75 = PASS
  static const double duplicateRadiusM = 50.0;     // Spatial dedup
}
```

---

## 12. RIVERPOD PROVIDERS

```dart
// Auth state
final supabaseAuthProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Current profile
final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  final data = await Supabase.instance.client
    .from('profiles')
    .select('*, zones(name)')
    .eq('id', user.id)
    .maybeSingle();
  return data != null ? Profile.fromJson(data) : null;
});

// Citizen tickets (realtime)
final citizenTicketsProvider = StreamProvider<List<Ticket>>((ref) { ... });

// JE zone tickets (realtime)
final jeTicketsProvider = StreamProvider<List<Ticket>>((ref) { ... });
```

---

## 13. GO_ROUTER ROUTES

```dart
/login            → LoginScreen
/register         → RegistrationScreen
/blocked          → BlockedScreen
/handoff          → WebHandoffScreen

/citizen/home     → CitizenHomeScreen
/citizen/report   → ReportDamageScreen
/citizen/ai-result → AIDetectionResultScreen
/citizen/confirmation → SubmissionConfirmationScreen
/citizen/my-complaints → MyComplaintsScreen
/citizen/tracker  → ComplaintTrackerScreen (?ticketId=)
/citizen/profile  → ProfileScreen

/je/home          → JEHomeScreen
/je/ticket/:id    → JETicketDetailScreen
/je/checkin/:id   → JESiteCheckInScreen
/je/measure/:id   → JEMeasureEstimateScreen
/je/assign/:id    → JEExecutorAssignmentScreen
/je/profile       → JEProfileScreen

/mukadam/home     → MukadamHomeScreen
/mukadam/detail/:id → MukadamWorkOrderDetailScreen
/mukadam/inprogress/:id → MukadamInProgressScreen
/mukadam/camera/:id → MukadamProofCameraScreen
/mukadam/issue/:id → MukadamIssueScreen
/mukadam/submitted → MukadamSubmissionCompleteScreen
/mukadam/profile  → MukadamProfileScreen

/contractor/home  → ContractorHomeScreen
/contractor/detail/:id → ContractorJobDetailScreen
/contractor/inprogress/:id → ContractorInProgressScreen
/contractor/camera/:id → ContractorGhostCameraScreen
/contractor/issue/:id → ContractorIssueScreen
/contractor/submitted → ContractorSubmissionCompleteScreen
/contractor/profile → ContractorProfileScreen
```

**Router redirect guard:**
- `auth.currentUser == null` → allow `/login`, `/register`, `/blocked` only
- `auth.currentUser != null` BUT no profile → `/register`
- `is_active = false` → `/blocked`
- Role routing handled post-OTP only — router does not auto-assume citizen

---

## 14. AUDIT TRAIL RULE

**Every status change must insert a `ticket_events` row.** No exceptions.

The DB trigger `trg_audit_status` auto-logs status changes. But the app must also insert explicit events for:
- `je_checkin` — on site check-in
- `measurement_recorded` — on dimension submit
- `assignment` — on executor assignment
- `photo_upload` — on after-photo submit
- `escalation` — on issue flagging
- `status_change` — on gang start / reject

The `fn_guard_ticket_columns` DB trigger enforces that each role can only write their allowed columns. Attempting to write restricted columns throws a PostgrestException that the app must catch and display.

---

## 15. DEMO CREDENTIALS

| Account | Role | Zone | Password |
|---|---|---|---|
| citizen@ssr.demo | citizen | — | Demo@SSR2025 |
| je.zone4@ssr.demo | je | Zone 4 | Demo@SSR2025 |
| mukadam.z4@ssr.demo | mukadam | Zone 4 | Demo@SSR2025 |
| contractor.z4@ssr.demo | contractor | Zone 4 | Demo@SSR2025 |
| ae.zone4@ssr.demo | ae | Zone 4 | Demo@SSR2025 |
| commissioner@ssr.demo | commissioner | — | Demo@SSR2025 |
| accounts@ssr.demo | accounts | — | Demo@SSR2025 |
| superadmin@ssr.demo | super_admin | — | Demo@SSR2025 |

---

## 16. BUILD COMMAND

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://[project-ref].supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=AI_SERVICE_URL=https://ssr-ai.railway.app \
  --dart-define=WEB_DASHBOARD_URL=https://ssr-dashboard.vercel.app
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 17. PHYSICAL DEVICE ACCEPTANCE GATE

The APK milestone is complete when all pass on a real Android device:

- [ ] Release APK installs successfully
- [ ] **Citizen:** OTP → report damage (camera + GPS) → ticket appears in Supabase with correct zone_id
- [ ] **Citizen:** Complaint tracker shows correct stepper state
- [ ] **JE:** OTP → zone-scoped ticket list → geofence check-in blocks at >20m → succeeds at ≤20m
- [ ] **JE:** Measure & estimate → rate locked → executor assigned with XOR enforcement
- [ ] **Mukadam:** OTP → assigned tickets only → start gang → proof camera → submission complete
- [ ] **Contractor:** OTP → job orders with billing visible → ghost camera → submission with hash
- [ ] **Non-mobile role (e.g. AE):** OTP → lands on Web Handoff, cannot access any mobile flow
- [ ] Camera permission denied → graceful message, not crash
- [ ] GPS permission denied → graceful message, not crash
- [ ] Upload fails → retry SnackBar, no crash, no navigation away
- [ ] AI service unreachable → offline estimate path works, ticket still submits

---

*रोड NIRMAN Flutter App Spec v1.0 — MIT Academy of Engineering, Pune — SAMVED Hackathon 2026*
