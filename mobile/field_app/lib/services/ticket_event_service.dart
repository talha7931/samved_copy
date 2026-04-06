import 'package:supabase_flutter/supabase_flutter.dart';

class TicketEventService {
  TicketEventService(this._client);

  final SupabaseClient _client;

  Future<void> insertEvent({
    required String ticketId,
    required String actorRole,
    required String eventType,
    String? oldStatus,
    String? newStatus,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client.from('ticket_events').insert({
        'ticket_id': ticketId,
        'actor_id': uid,
        'actor_role': actorRole,
        'event_type': eventType,
        'old_status': oldStatus,
        'new_status': newStatus,
        'notes': notes,
        if (metadata != null) 'metadata': metadata,
      });
    } on PostgrestException {
      // The backend owns audit integrity. Status changes are already recorded
      // by triggers, and note-only client events remain best-effort until a
      // dedicated server-side audit bridge is added.
      return;
    }
  }
}
