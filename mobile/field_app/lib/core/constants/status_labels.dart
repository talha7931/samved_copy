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

const Map<String, String> kMukadamStatusDisplay = {
  'assigned': 'Assigned',
  'in_progress': 'Gang Deployed',
  'audit_pending': 'Pending Verification',
  'resolved': 'Completed',
  'rejected': 'Rejected',
};

const Map<String, String> kContractorStatusDisplay = {
  'open': 'Received',
  'verified': 'Verified',
  'assigned': 'Assigned',
  'in_progress': 'In Progress',
  'audit_pending': 'Proof Submitted',
  'resolved': 'Completed',
  'rejected': 'Rejected',
  'escalated': 'Escalated',
};

String ticketStatusLabel(String status) =>
    kTicketStatusDisplay[status] ?? status;

String ticketStatusLabelForRole(String status, String role) {
  switch (role) {
    case 'mukadam':
      return kMukadamStatusDisplay[status] ?? ticketStatusLabel(status);
    case 'contractor':
      return kContractorStatusDisplay[status] ?? ticketStatusLabel(status);
    default:
      return ticketStatusLabel(status);
  }
}

/// Ordered stepper path for citizen-facing tracker (main happy path).
const List<String> kCitizenStatusOrder = [
  'open',
  'verified',
  'assigned',
  'in_progress',
  'audit_pending',
  'resolved',
];
