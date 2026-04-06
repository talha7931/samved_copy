import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/rate_card_service.dart';
import '../services/storage_service.dart';
import '../services/ticket_event_service.dart';
import '../services/ticket_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(supabaseClientProvider)),
);

final ticketServiceProvider = Provider<TicketService>(
  (ref) => TicketService(ref.watch(supabaseClientProvider)),
);

final ticketEventServiceProvider = Provider<TicketEventService>(
  (ref) => TicketEventService(ref.watch(supabaseClientProvider)),
);

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(supabaseClientProvider)),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final rateCardServiceProvider = Provider<RateCardService>(
  (ref) => RateCardService(ref.watch(supabaseClientProvider)),
);

final profileProvider = FutureProvider<Profile?>((ref) async {
  final auth = ref.watch(authServiceProvider);
  if (auth.currentSession == null) return null;
  return auth.fetchProfile();
});
