import 'package:supabase_flutter/supabase_flutter.dart';

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

class TicketService {
  TicketService(this._client);

  final SupabaseClient _client;

  static const _activeStatuses = [
    'open',
    'verified',
    'assigned',
    'in_progress',
    'audit_pending',
    'escalated',
    'cross_assigned',
  ];

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

  Future<List<Ticket>> fetchMukadamTickets() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('tickets')
        .select()
        .eq('assigned_mukadam', uid)
        .inFilter('status', ['assigned', 'in_progress'])
        .order('updated_at', ascending: false);
    return (rows as List<dynamic>)
        .map((e) => Ticket.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Ticket>> fetchContractorTickets() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('tickets')
        .select()
        .eq('assigned_contractor', uid)
        .inFilter('status', ['assigned', 'in_progress'])
        .order('updated_at', ascending: false);
    return (rows as List<dynamic>)
        .map((e) => Ticket.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Ticket?> fetchTicket(String id) async {
    final row = await _client.from('tickets').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Ticket.fromJson(Map<String, dynamic>.from(row));
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
      'department_id': 1,
    };
    final inserted =
        await _client.from('tickets').insert(payload).select('id').single();
    return inserted['id'] as String;
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
    }).eq('id', ticketId);
  }

  Future<void> updateJeMeasure({
    required String ticketId,
    required TicketDimensions dimensions,
    required String workType,
    required String rateCardId,
    required double ratePerUnit,
    required double estimatedCost,
  }) async {
    await _client.from('tickets').update({
      'dimensions': dimensions.toJson(),
      'work_type': workType,
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
    final rows = await _client.from('contractors').select('id, company_name, zone_ids');
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
