import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/rate_card.dart';

class RateCardService {
  RateCardService(this._client);

  final SupabaseClient _client;

  Future<List<RateCard>> activeForZone(int? zoneId) async {
    final rows =
        await _client.from('rate_cards').select().eq('is_active', true).order('work_type');
    final list = (rows as List<dynamic>)
        .map((e) => RateCard.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (zoneId == null) return list;
    return list
        .where((r) => r.zoneId == null || r.zoneId == zoneId)
        .toList();
  }
}
