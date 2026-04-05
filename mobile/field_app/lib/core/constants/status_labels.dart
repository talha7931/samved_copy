/// Human labels for ticket status (Flutter Plan — do not invent alternates).
const Map<String, String> kTicketStatusDisplay = {
  'open': 'Received',
  'verified': 'Verified',
  'assigned': 'Repair Assigned',
  'in_progress': 'Fixing',
  'audit_pending': 'Quality Check',
  'resolved': 'Resolved',
  'rejected': 'Rejected',
  'escalated': 'Escalated',
  'cross_assigned': 'Cross-assigned',
};

String ticketStatusLabel(String status) =>
    kTicketStatusDisplay[status] ?? status;

/// Ordered stepper path for citizen-facing tracker (main happy path).
const List<String> kCitizenStatusOrder = [
  'open',
  'verified',
  'assigned',
  'in_progress',
  'audit_pending',
  'resolved',
];
