import 'ticket_dimensions.dart';

class Ticket {
  const Ticket({
    required this.id,
    required this.ticketRef,
    required this.createdAt,
    required this.updatedAt,
    this.citizenId,
    this.citizenPhone,
    this.citizenName,
    required this.sourceChannel,
    required this.latitude,
    required this.longitude,
    this.addressText,
    this.nearestLandmark,
    this.roadName,
    this.prabhagId,
    this.zoneId,
    this.damageType,
    this.damageCause,
    required this.departmentId,
    this.departmentNote,
    this.aiConfidence,
    this.epdoScore,
    this.totalPotholes,
    this.severityTier,
    required this.photoBefore,
    this.photoAfter,
    this.photoJeInspection,
    required this.status,
    this.assignedJe,
    this.assignedContractor,
    this.assignedMukadam,
    this.jeCheckinLat,
    this.jeCheckinLng,
    this.jeCheckinTime,
    this.jeCheckinDistanceM,
    this.dimensions,
    this.workType,
    this.rateCardId,
    this.ratePerUnit,
    this.estimatedCost,
    this.jobOrderRef,
    this.billId,
    this.ssimScore,
    this.ssimPass,
    this.citizenConfirmed,
  });

  final String id;
  final String ticketRef;
  final String createdAt;
  final String updatedAt;
  final String? citizenId;
  final String? citizenPhone;
  final String? citizenName;
  final String sourceChannel;
  final double latitude;
  final double longitude;
  final String? addressText;
  final String? nearestLandmark;
  final String? roadName;
  final int? prabhagId;
  final int? zoneId;
  final String? damageType;
  final String? damageCause;
  final int departmentId;
  final String? departmentNote;
  final double? aiConfidence;
  final double? epdoScore;
  final int? totalPotholes;
  final String? severityTier;
  final List<String> photoBefore;
  final String? photoAfter;
  final String? photoJeInspection;
  final String status;
  final String? assignedJe;
  final String? assignedContractor;
  final String? assignedMukadam;
  final double? jeCheckinLat;
  final double? jeCheckinLng;
  final String? jeCheckinTime;
  final double? jeCheckinDistanceM;
  final TicketDimensions? dimensions;
  final String? workType;
  final String? rateCardId;
  final double? ratePerUnit;
  final double? estimatedCost;
  final String? jobOrderRef;
  final String? billId;
  /// SSIM 0–1; schema uses inverse rule (lower often means pass after repair).
  final double? ssimScore;
  final bool? ssimPass;
  final bool? citizenConfirmed;

  String? get primaryBeforePhoto =>
      photoBefore.isNotEmpty ? photoBefore.first : null;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final before = json['photo_before'];
    List<String> photos = [];
    if (before is List) {
      photos = before.map((e) => e.toString()).toList();
    }

    return Ticket(
      id: json['id'] as String,
      ticketRef: json['ticket_ref'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      citizenId: json['citizen_id'] as String?,
      citizenPhone: json['citizen_phone'] as String?,
      citizenName: json['citizen_name'] as String?,
      sourceChannel: json['source_channel'] as String? ?? 'app',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      addressText: json['address_text'] as String?,
      nearestLandmark: json['nearest_landmark'] as String?,
      roadName: json['road_name'] as String?,
      prabhagId: json['prabhag_id'] as int?,
      zoneId: json['zone_id'] as int?,
      damageType: json['damage_type'] as String?,
      damageCause: json['damage_cause'] as String?,
      departmentId: json['department_id'] as int? ?? 1,
      departmentNote: json['department_note'] as String?,
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      epdoScore: (json['epdo_score'] as num?)?.toDouble(),
      totalPotholes: json['total_potholes'] as int?,
      severityTier: json['severity_tier'] as String?,
      photoBefore: photos,
      photoAfter: json['photo_after'] as String?,
      photoJeInspection: json['photo_je_inspection'] as String?,
      status: json['status'] as String? ?? 'open',
      assignedJe: json['assigned_je'] as String?,
      assignedContractor: json['assigned_contractor'] as String?,
      assignedMukadam: json['assigned_mukadam'] as String?,
      jeCheckinLat: (json['je_checkin_lat'] as num?)?.toDouble(),
      jeCheckinLng: (json['je_checkin_lng'] as num?)?.toDouble(),
      jeCheckinTime: json['je_checkin_time'] as String?,
      jeCheckinDistanceM: (json['je_checkin_distance_m'] as num?)?.toDouble(),
      dimensions: TicketDimensions.fromJson(json['dimensions']),
      workType: json['work_type'] as String?,
      rateCardId: json['rate_card_id'] as String?,
      ratePerUnit: (json['rate_per_unit'] as num?)?.toDouble(),
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      jobOrderRef: json['job_order_ref'] as String?,
      billId: json['bill_id'] as String?,
      ssimScore: (json['ssim_score'] as num?)?.toDouble(),
      ssimPass: json['ssim_pass'] as bool?,
      citizenConfirmed: json['citizen_confirmed'] as bool?,
    );
  }
}
