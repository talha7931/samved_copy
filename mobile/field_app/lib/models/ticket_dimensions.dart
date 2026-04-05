class TicketDimensions {
  const TicketDimensions({
    required this.lengthM,
    required this.widthM,
    required this.depthM,
    required this.areaSqm,
  });

  final double lengthM;
  final double widthM;
  final double depthM;
  final double areaSqm;

  Map<String, dynamic> toJson() => {
        'length_m': lengthM,
        'width_m': widthM,
        'depth_m': depthM,
        'area_sqm': areaSqm,
      };

  static TicketDimensions? fromJson(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) return null;
    return TicketDimensions(
      lengthM: (json['length_m'] as num?)?.toDouble() ?? 0,
      widthM: (json['width_m'] as num?)?.toDouble() ?? 0,
      depthM: (json['depth_m'] as num?)?.toDouble() ?? 0,
      areaSqm: (json['area_sqm'] as num?)?.toDouble() ?? 0,
    );
  }
}
