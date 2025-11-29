class YouTubeVideo {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final String channelId;
  final DateTime publishedAt;
  final String duration;
  final int? viewCount;
  final int? likeCount;

  YouTubeVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.channelId,
    required this.publishedAt,
    this.duration = '0:00',
    this.viewCount,
    this.likeCount,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>;
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>;

    // Get the best quality thumbnail available
    String thumbnailUrl = '';
    if (thumbnails.containsKey('high')) {
      thumbnailUrl = thumbnails['high']['url'];
    } else if (thumbnails.containsKey('medium')) {
      thumbnailUrl = thumbnails['medium']['url'];
    } else if (thumbnails.containsKey('default')) {
      thumbnailUrl = thumbnails['default']['url'];
    }

    // Get video ID from different response types
    String videoId = '';
    if (json['id'] is String) {
      videoId = json['id'];
    } else if (json['id'] is Map) {
      videoId = json['id']['videoId'] ?? '';
    }

    return YouTubeVideo(
      id: videoId,
      title: snippet['title'] ?? '',
      description: snippet['description'] ?? '',
      thumbnailUrl: thumbnailUrl,
      channelTitle: snippet['channelTitle'] ?? '',
      channelId: snippet['channelId'] ?? '',
      publishedAt: snippet['publishedAt'] != null
          ? DateTime.parse(snippet['publishedAt'])
          : DateTime.now(),
      duration: json['contentDetails']?['duration'] ?? '0:00',
      viewCount: int.tryParse(json['statistics']?['viewCount'] ?? '0'),
      likeCount: int.tryParse(json['statistics']?['likeCount'] ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'channelTitle': channelTitle,
      'channelId': channelId,
      'publishedAt': publishedAt.toIso8601String(),
      'duration': duration,
      'viewCount': viewCount,
      'likeCount': likeCount,
    };
  }

  // Convert ISO 8601 duration to readable format
  String get formattedDuration {
    final regex = RegExp(r'PT(\d+H)?(\d+M)?(\d+S)?');
    final match = regex.firstMatch(duration);

    if (match == null) return '0:00';

    final hours = match.group(1)?.replaceAll('H', '') ?? '';
    final minutes = match.group(2)?.replaceAll('M', '') ?? '0';
    final seconds = match.group(3)?.replaceAll('S', '') ?? '0';

    if (hours.isNotEmpty) {
      return '$hours:${minutes.padLeft(2, '0')}:${seconds.padLeft(2, '0')}';
    } else {
      return '${minutes.padLeft(1, '0')}:${seconds.padLeft(2, '0')}';
    }
  }
}
