class Zone {
  const Zone({
    required this.id,
    required this.name,
    this.nameMarathi,
  });

  final int id;
  final String name;
  final String? nameMarathi;

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Zone ${json['id']}',
      nameMarathi: json['name_marathi'] as String?,
    );
  }
}
