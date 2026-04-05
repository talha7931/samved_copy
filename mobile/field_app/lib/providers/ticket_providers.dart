import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ticket.dart';
import 'providers.dart';

/// Citizen's own tickets (home + map).
final citizenTicketsProvider =
    FutureProvider.autoDispose<List<Ticket>>((ref) {
  return ref.watch(ticketServiceProvider).fetchCitizenTickets();
});

final ticketDetailProvider =
    FutureProvider.family.autoDispose<Ticket?, String>((ref, id) {
  return ref.watch(ticketServiceProvider).fetchTicket(id);
});

final jeInboxProvider = FutureProvider.autoDispose<List<Ticket>>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final z = profile?.zoneId;
  if (z == null) return [];
  return ref.watch(ticketServiceProvider).fetchJeZoneTickets(z);
});

final mukadamInboxProvider = FutureProvider.autoDispose<List<Ticket>>((ref) {
  return ref.watch(ticketServiceProvider).fetchMukadamTickets();
});

final contractorInboxProvider = FutureProvider.autoDispose<List<Ticket>>((ref) {
  return ref.watch(ticketServiceProvider).fetchContractorTickets();
});
