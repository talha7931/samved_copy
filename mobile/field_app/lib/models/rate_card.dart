class RateCard {
  const RateCard({
    required this.id,
    required this.workType,
    this.workTypeMarathi,
    required this.unit,
    required this.ratePerUnit,
    this.zoneId,
    required this.isActive,
  });

  final String id;
  final String workType;
  final String? workTypeMarathi;
  final String unit;
  final double ratePerUnit;
  final int? zoneId;
  final bool isActive;

  factory RateCard.fromJson(Map<String, dynamic> json) {
    return RateCard(
      id: json['id'] as String,
      workType: json['work_type'] as String? ?? '',
      workTypeMarathi: json['work_type_marathi'] as String?,
      unit: json['unit'] as String? ?? 'sqm',
      ratePerUnit: (json['rate_per_unit'] as num?)?.toDouble() ?? 0,
      zoneId: json['zone_id'] as int?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
