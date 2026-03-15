class Playlist {
  final String id;
  final String childProfileId;
  final String name;
  final String? description;
  final List<String> videoIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.childProfileId,
    required this.name,
    this.description,
    required this.videoIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      childProfileId: json['child_profile_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      videoIds: (json['video_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
