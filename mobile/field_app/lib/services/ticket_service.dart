import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_env.dart';
import '../models/ticket.dart';
import '../models/ticket_dimensions.dart';

class MukadamOption {
  const MukadamOption({required this.id, required this.fullName});
  final String id;
  final String fullName;
}

class ContractorOption {
  const ContractorOption({required this.id, required this.companyName});
  final String id;
  final String companyName;
}

class MukadamHomeSnapshot {
  const MukadamHomeSnapshot({
    required this.rows,
    required this.jeNames,
    required this.completedThisWeekCount,
  });

  final List<Map<String, dynamic>> rows;
  final Map<String, String> jeNames;
  final int completedThisWeekCount;

  static MukadamHomeSnapshot empty() => const MukadamHomeSnapshot(
        rows: [],
        jeNames: {},
        completedThisWeekCount: 0,
      );
}

class ContractorHomeSnapshot {
  const ContractorHomeSnapshot({
    required this.rows,
    required this.jeNames,
    required this.pendingAmount,
    required this.pendingCount,
  });

  final List<Map<String, dynamic>> rows;
  final Map<String, String> jeNames;
  final double pendingAmount;
  final int pendingCount;

  static ContractorHomeSnapshot empty() => const ContractorHomeSnapshot(
        rows: [],
        jeNames: {},
        pendingAmount: 0,
        pendingCount: 0,
      );
}

class TicketLookup {
  const TicketLookup({
    this.zoneName,
    this.prabhagName,
    this.assignedJeName,
    this.assignedMukadamName,
    this.assignedContractorName,
  });

  final String? zoneName;
  final String? prabhagName;
  final String? assignedJeName;
  final String? assignedMukadamName;
  final String? assignedContractorName;
}

class CitizenAiPipelineResult {
  const CitizenAiPipelineResult({
    required this.ticket,
    this.detect,
    this.severity,
  });

  final Ticket? ticket;
  final Map<String, dynamic>? detect;
  final Map<String, dynamic>? severity;
}

class RepairVerificationResult {
  const RepairVerificationResult({
    required this.ticket,
    this.verification,
  });

  final Ticket? ticket;
  final Map<String, dynamic>? verification;
}

class TicketService {
  TicketService(this._client);

  final SupabaseClient _client;
  final Map<int, String> _zoneNames = <int, String>{};
  final Map<int, String> _prabhagNames = <int, String>{};
  final Map<String, String> _profileNames = <String, String>{};

  static const _activeStatuses = [
    'open',
    'verified',
    'assigned',
    'in_progress',
    'audit_pending',
    'escalated',
    'cross_assigned',
  ];

  /// Edge Functions JWT gate + [AuthHttpClient] use `putIfAbsent` for
  /// `Authorization`, so a stale Bearer on the functions client headers would
  /// never be replaced by the current session. Always send an explicit,
  /// freshly refreshed user access token.
  Future<String> _freshAccessTokenForFunctions() async {
    final current = _client.auth.currentSession;
    if (current == null) {
      throw Exception('Sign in required for cloud actions (no session).');
    }

    // On web, local cached access tokens can become invalid before `isExpired`
    // flips. Force a refresh before edge-function calls to avoid 401 Invalid JWT.
    final refreshed = await _client.auth.refreshSession();
    final session = refreshed.session ?? _client.auth.currentSession ?? current;
    final token = session.accessToken;
    if (token.isEmpty) {
      throw Exception('Sign in required (empty access token).');
    }
    return token;
  }

  Map<String, dynamic>? _parseJsonBody(String body) {
    if (body.trim().isEmpty) return null;
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw Exception('Unexpected response shape');
  }

  Future<Map<String, dynamic>?> _invokeFunction(
    String name,
    Map<String, dynamic> body,
  ) async {
    Future<Map<String, dynamic>?> invokeWithToken(String token) async {
      final uri = Uri.parse('${AppEnv.supabaseUrl}/functions/v1/$name');
      final response = await http.post(
        uri,
        headers: {
          'apikey': AppEnv.supabaseAnonKey,
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 401) {
        throw FunctionException(
          status: 401,
          details: response.body,
          reasonPhrase: response.reasonPhrase,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Function $name failed (${response.statusCode}): ${response.body}',
        );
      }

      return _parseJsonBody(response.body);
    }

    var token = await _freshAccessTokenForFunctions();
    try {
      return await invokeWithToken(token);
    } on FunctionException catch (e) {
      if (e.status != 401) rethrow;
      final refreshed = await _client.auth.refreshSession();
      final next = refreshed.session?.accessToken ?? _client.auth.currentSession?.accessToken;
      if (next == null || next.isEmpty || next == token) rethrow;
      token = next;
      return await invokeWithToken(token);
    }
  }

  Future<List<Ticket>> fetchCitizenTickets() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('tickets')
        .select()
        .eq('citizen_id', uid)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((e) => Ticket.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Ticket>> fetchJeZoneTickets(int zoneId) async {
    final rows = await _client
        .from('tickets')
        .select()
        .eq('zone_id', zoneId)
        .order('updated_at', ascending: false);
    final all = (rows as List<dynamic>)
        .map((e) => Ticket.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return all.where((t) => _activeStatuses.contains(t.status)).toList();
  }

  /// JE dashboard full list (including resolved/rejected) for counts/history.
  Future<List<Ticket>> fetchJeZoneTicketsAll(int zoneId) async {
    final rows = await _client
        .from('tickets')
        .select()
        .eq('zone_id', zoneId)
        .order('updated_at', ascending: false);
    return (rows as List<dynamic>)
        .map((e) => Ticket.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Ticket>> fetchMukadamTickets() async {
    final snap = await fetchMukadamHomeSnapshot();
    return snap.rows
        .map((e) => Ticket.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Ticket>> fetchContractorTickets() async {
    final snap = await fetchContractorHomeSnapshot();
    return snap.rows
        .map((e) => Ticket.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Mukadam work-order snapshot with JE names and weekly completion summary.
  Future<MukadamHomeSnapshot> fetchMukadamHomeSnapshot() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return MukadamHomeSnapshot.empty();

    final raw = await _client
        .from('tickets')
        .select(
          'id, ticket_ref, status, severity_tier, address_text, work_type, dimensions, '
          'created_at, updated_at, assigned_je, assigned_contractor, photo_before, '
          'je_checkin_time, zone_id, prabhag_id, latitude, longitude, department_id, source_channel',
        )
        .eq('assigned_mukadam', uid)
        .inFilter('status', ['assigned', 'in_progress', 'audit_pending'])
        .order('created_at', ascending: false);

    final list = (raw as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((m) => m['assigned_contractor'] == null)
        .toList();

    final jeIds = list
        .map((m) => m['assigned_je'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final jeNames = <String, String>{};
    if (jeIds.isNotEmpty) {
      final pr = await _client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', jeIds);
      for (final p in pr as List<dynamic>) {
        final m = Map<String, dynamic>.from(p as Map);
        final id = m['id'] as String?;
        if (id != null) {
          jeNames[id] = m['full_name'] as String? ?? '';
        }
      }
    }

    final weekAgo =
        DateTime.now().toUtc().subtract(const Duration(days: 7)).toIso8601String();
    final weekRows = await _client
        .from('tickets')
        .select('id, assigned_contractor')
        .eq('assigned_mukadam', uid)
        .inFilter('status', ['audit_pending', 'resolved'])
        .gte('updated_at', weekAgo);
    final weekFiltered = (weekRows as List<dynamic>)
        .where((e) => (e as Map<String, dynamic>)['assigned_contractor'] == null)
        .length;

    return MukadamHomeSnapshot(
      rows: list,
      jeNames: jeNames,
      completedThisWeekCount: weekFiltered,
    );
  }

  Future<int> countMukadamJobsThisWeek() async {
    final snap = await fetchMukadamHomeSnapshot();
    return snap.completedThisWeekCount;
  }

  /// Contractor snapshot with JE names and pending payment insight.
  Future<ContractorHomeSnapshot> fetchContractorHomeSnapshot() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return ContractorHomeSnapshot.empty();

    final raw = await _client
        .from('tickets')
        .select(
          'id, ticket_ref, status, severity_tier, address_text, road_name, work_type, dimensions, '
          'estimated_cost, rate_per_unit, job_order_ref, created_at, updated_at, assigned_je, '
          'assigned_mukadam, assigned_contractor, zone_id, prabhag_id',
        )
        .eq('assigned_contractor', uid)
        .inFilter('status', ['assigned', 'in_progress', 'audit_pending', 'resolved'])
        .order('created_at', ascending: false);

    final rows = (raw as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((m) => m['assigned_mukadam'] == null)
        .toList();

    final jeIds = rows
        .map((m) => m['assigned_je'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final jeNames = <String, String>{};
    if (jeIds.isNotEmpty) {
      final prs = await _client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', jeIds);
      for (final p in prs as List<dynamic>) {
        final m = Map<String, dynamic>.from(p as Map);
        final id = m['id'] as String?;
        if (id != null) {
          jeNames[id] = m['full_name'] as String? ?? '';
        }
      }
    }

    double pendingAmount = 0;
    int pendingCount = 0;
    for (final row in rows) {
      if (row['status'] == 'audit_pending') {
        pendingCount += 1;
        pendingAmount += (row['estimated_cost'] as num?)?.toDouble() ?? 0;
      }
    }

    return ContractorHomeSnapshot(
      rows: rows,
      jeNames: jeNames,
      pendingAmount: pendingAmount,
      pendingCount: pendingCount,
    );
  }

  Future<Ticket?> fetchTicket(String id) async {
    final row = await _client.from('tickets').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Ticket.fromJson(Map<String, dynamic>.from(row));
  }

  Future<String?> fetchZoneName(int zoneId) async {
    if (_zoneNames.containsKey(zoneId)) return _zoneNames[zoneId];
    final row = await _client
        .from('zones')
        .select('name')
        .eq('id', zoneId)
        .maybeSingle();
    final name = row == null ? null : (row['name'] as String?);
    if (name != null) _zoneNames[zoneId] = name;
    return name;
  }

  Future<String?> fetchPrabhagName(int prabhagId) async {
    if (_prabhagNames.containsKey(prabhagId)) return _prabhagNames[prabhagId];
    final row = await _client
        .from('prabhags')
        .select('name')
        .eq('id', prabhagId)
        .maybeSingle();
    final name = row == null ? null : (row['name'] as String?);
    if (name != null) _prabhagNames[prabhagId] = name;
    return name;
  }

  Future<String?> fetchProfileName(String userId) async {
    if (_profileNames.containsKey(userId)) return _profileNames[userId];
    final row = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();
    final name = row == null ? null : (row['full_name'] as String?);
    if (name != null) _profileNames[userId] = name;
    return name;
  }

  Future<TicketLookup> fetchLookupForTicket(Ticket ticket) async {
    String? zoneName;
    String? prabhagName;
    String? assignedJeName;
    String? assignedMukadamName;
    String? assignedContractorName;
    if (ticket.zoneId != null) {
      zoneName = await fetchZoneName(ticket.zoneId!);
    }
    if (ticket.prabhagId != null) {
      prabhagName = await fetchPrabhagName(ticket.prabhagId!);
    }
    if (ticket.assignedJe != null) {
      assignedJeName = await fetchProfileName(ticket.assignedJe!);
    }
    if (ticket.assignedMukadam != null) {
      assignedMukadamName = await fetchProfileName(ticket.assignedMukadam!);
    }
    if (ticket.assignedContractor != null) {
      assignedContractorName = await fetchProfileName(ticket.assignedContractor!);
    }
    return TicketLookup(
      zoneName: zoneName,
      prabhagName: prabhagName,
      assignedJeName: assignedJeName,
      assignedMukadamName: assignedMukadamName,
      assignedContractorName: assignedContractorName,
    );
  }

  double distanceMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
  }

  /// Citizen creates a ticket. `location` must be EWKT — PostgREST casts text
  /// to `geography`; a GeoJSON map is parsed as WKT and fails with "invalid geometry".
  Future<String> createCitizenTicket({
    required String citizenPhone,
    String? citizenName,
    required double lat,
    required double lng,
    required List<String> photoBeforeUrls,
    String? addressText,
    String? nearestLandmark,
    String? damageType,
    double? aiConfidence,
    double? epdoScore,
    String? severityTier,
    int? totalPotholes,
    String? aiSource,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final locationEwkt =
        'SRID=4326;POINT(${lng.toStringAsFixed(7)} ${lat.toStringAsFixed(7)})';
    final payload = <String, dynamic>{
      'citizen_id': uid,
      'citizen_phone': citizenPhone,
      'citizen_name': citizenName,
      'source_channel': 'app',
      'latitude': lat,
      'longitude': lng,
      'location': locationEwkt,
      'photo_before': photoBeforeUrls,
      'address_text': addressText,
      'nearest_landmark': nearestLandmark,
      'damage_type': damageType,
      'ai_confidence': aiConfidence,
      'epdo_score': epdoScore,
      'severity_tier': severityTier,
      'total_potholes': totalPotholes,
      if (aiSource != null) 'ai_source': aiSource,
      'department_id': 1,
    };
    final inserted =
        await _client.from('tickets').insert(payload).select('id').single();
    return inserted['id'] as String;
  }

  Future<CitizenAiPipelineResult> runCitizenAiPipeline(String ticketId) async {
    Map<String, dynamic>? detect;
    Map<String, dynamic>? severity;

    detect = await _invokeFunction('detect-road-damage', {
      'ticket_id': ticketId,
    });
    if (detect?['success'] != true) {
      throw Exception(
        detect?['error']?.toString() ?? 'Damage detection failed.',
      );
    }

    severity = await _invokeFunction('score-severity', {
      'ticket_id': ticketId,
    });
    if (severity?['success'] != true) {
      throw Exception(
        severity?['error']?.toString() ?? 'Severity scoring failed.',
      );
    }

    final ticket = await fetchTicket(ticketId);
    return CitizenAiPipelineResult(
      ticket: ticket,
      detect: detect == null ? null : Map<String, dynamic>.from(detect),
      severity: severity == null ? null : Map<String, dynamic>.from(severity),
    );
  }

  Future<void> updateJeCheckIn({
    required String ticketId,
    required double lat,
    required double lng,
    required double distanceM,
  }) async {
    await _client.from('tickets').update({
      'je_checkin_lat': lat,
      'je_checkin_lng': lng,
      'je_checkin_time': DateTime.now().toUtc().toIso8601String(),
      'je_checkin_distance_m': distanceM,
      'status': 'verified',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', ticketId);
  }

  Future<void> updateJeMeasure({
    required String ticketId,
    required TicketDimensions dimensions,
    required String workType,
    required String damageCause,
    required String rateCardId,
    required double ratePerUnit,
    required double estimatedCost,
  }) async {
    await _client.from('tickets').update({
      'dimensions': dimensions.toJson(),
      'work_type': workType,
      'damage_cause': damageCause,
      'rate_card_id': rateCardId,
      'rate_per_unit': ratePerUnit,
      'estimated_cost': estimatedCost,
      'status': 'verified',
    }).eq('id', ticketId);
  }

  Future<void> assignExecutor({
    required String ticketId,
    required String ticketRef,
    String? assignedMukadam,
    String? assignedContractor,
  }) async {
    assert(
      (assignedMukadam != null) ^ (assignedContractor != null),
      'XOR executor',
    );
    final jobRef = 'JO-${ticketRef.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '-')}-${ticketId.substring(0, 8)}';
    await _client.from('tickets').update({
      'assigned_mukadam': assignedMukadam,
      'assigned_contractor': assignedContractor,
      'status': 'assigned',
      'job_order_ref': jobRef,
    }).eq('id', ticketId);
  }

  Future<void> startWork(String ticketId) async {
    await _client.from('tickets').update({
      'status': 'in_progress',
    }).eq('id', ticketId);
  }

  Future<void> submitExecutionProof({
    required String ticketId,
    required String afterPhotoUrl,
  }) async {
    await _client.from('tickets').update({
      'photo_after': afterPhotoUrl,
      'status': 'audit_pending',
    }).eq('id', ticketId);
  }

  Future<RepairVerificationResult> runRepairVerification(String ticketId) async {
    final verification = await _invokeFunction('verify-repair', {
      'ticket_id': ticketId,
    });

    if (verification?['success'] != true) {
      throw Exception(
        verification?['error']?.toString() ?? 'Repair verification failed.',
      );
    }

    final ticket = await fetchTicket(ticketId);
    return RepairVerificationResult(
      ticket: ticket,
      verification: verification == null
          ? null
          : Map<String, dynamic>.from(verification),
    );
  }

  Future<void> rejectTicket({
    required String ticketId,
    required String reason,
  }) async {
    await _client.from('tickets').update({
      'status': 'rejected',
      'department_note': reason,
    }).eq('id', ticketId);
  }

  /// Supabase: only `audit_pending` → `resolved` with SSIM pass or citizen confirmation.
  Future<void> jeMarkResolvedAfterAudit(String ticketId) async {
    await _client.from('tickets').update({'status': 'resolved'}).eq('id', ticketId);
  }

  /// Supabase: `audit_pending` → `in_progress` when repair proof is insufficient.
  Future<void> jeSendBackForRework(String ticketId) async {
    await _client.from('tickets').update({'status': 'in_progress'}).eq('id', ticketId);
  }

  Future<List<MukadamOption>> listMukadamsInZone(int zoneId) async {
    final rows = await _client
        .from('profiles')
        .select('id, full_name')
        .eq('role', 'mukadam')
        .eq('zone_id', zoneId)
        .eq('is_active', true)
        .order('full_name');
    return (rows as List<dynamic>)
        .map(
          (e) => MukadamOption(
            id: (e as Map)['id'] as String,
            fullName: (e)['full_name'] as String? ?? 'Mukadam',
          ),
        )
        .toList();
  }

  Future<List<ContractorOption>> listContractorsInZone(int zoneId) async {
    final rows = await _client
        .from('contractors')
        .select('id, company_name, zone_ids, is_blacklisted')
        .eq('is_blacklisted', false);
    final list = rows as List<dynamic>;
    final out = <ContractorOption>[];
    for (final raw in list) {
      final m = Map<String, dynamic>.from(raw as Map);
      final ids = m['zone_ids'];
      if (ids is! List) continue;
      final z = ids.map((e) => (e as num).toInt()).toList();
      if (!z.contains(zoneId)) continue;
      out.add(ContractorOption(
        id: m['id'] as String,
        companyName: m['company_name'] as String? ?? 'Contractor',
      ));
    }
    out.sort((a, b) => a.companyName.compareTo(b.companyName));
    return out;
  }
}
