class ChildProfile {
  final String id;
  final String guardianId;
  final String name;
  final int age;
  final DateTime? birthdate;
  final String? avatarUrl;
  final List<String> preferences;
  final List<String> customRules;
  final DateTime createdAt;

  ChildProfile({
    required this.id,
    required this.guardianId,
    required this.name,
    required this.age,
    this.birthdate,
    this.avatarUrl,
    this.preferences = const [],
    this.customRules = const [],
    required this.createdAt,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as String,
      guardianId: json['guardian_id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'] as String)
          : null,
      avatarUrl: json['avatar_url'] as String?,
      preferences:
          (json['preferences'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      customRules:
          (json['custom_rules'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guardian_id': guardianId,
      'name': name,
      'age': age,
      'birthdate': birthdate?.toIso8601String().split(
        'T',
      )[0], // Store as date only
      'avatar_url': avatarUrl,
      'preferences': preferences,
      'custom_rules': customRules,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
