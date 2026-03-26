class FlaggedInappropriateVideo {
  final String id;
  final String childProfileId;
  final String videoId;
  final String? videoTitle;
  final String? videoUrl;
  final bool modelFlaggedInappropriate;
  final String? modelLabel;
  final String? modelReason;
  final String? transcript;
  final bool transcriptAvailable;
  final DateTime? transcriptFetchedAt;
  final int? reviewedForAge;
  final bool? geminiIsInappropriate;
  final double? geminiConfidence;
  final String? geminiReason;
  final Map<String, dynamic>? geminiResponse;
  final DateTime? geminiReviewedAt;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FlaggedInappropriateVideo({
    required this.id,
    required this.childProfileId,
    required this.videoId,
    this.videoTitle,
    this.videoUrl,
    required this.modelFlaggedInappropriate,
    this.modelLabel,
    this.modelReason,
    this.transcript,
    required this.transcriptAvailable,
    this.transcriptFetchedAt,
    this.reviewedForAge,
    this.geminiIsInappropriate,
    this.geminiConfidence,
    this.geminiReason,
    this.geminiResponse,
    this.geminiReviewedAt,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory FlaggedInappropriateVideo.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '');
    }

    DateTime? parseDate(dynamic value) {
      final text = value?.toString();
      if (text == null || text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    return FlaggedInappropriateVideo(
      id: json['id']?.toString() ?? '',
      childProfileId: json['child_profile_id']?.toString() ?? '',
      videoId: json['video_id']?.toString() ?? '',
      videoTitle: json['video_title']?.toString(),
      videoUrl: json['video_url']?.toString(),
      modelFlaggedInappropriate: json['model_flagged_inappropriate'] == true,
      modelLabel: json['model_label']?.toString(),
      modelReason: json['model_reason']?.toString(),
      transcript: json['transcript']?.toString(),
      transcriptAvailable: json['transcript_available'] == true,
      transcriptFetchedAt: parseDate(json['transcript_fetched_at']),
      reviewedForAge: json['reviewed_for_age'] is int
          ? json['reviewed_for_age'] as int
          : int.tryParse(json['reviewed_for_age']?.toString() ?? ''),
      geminiIsInappropriate: json['gemini_is_inappropriate'] as bool?,
      geminiConfidence: parseDouble(json['gemini_confidence']),
      geminiReason: json['gemini_reason']?.toString(),
      geminiResponse: json['gemini_response'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['gemini_response'])
          : null,
      geminiReviewedAt: parseDate(json['gemini_reviewed_at']),
      status: json['status']?.toString() ?? 'pending_transcript',
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDate(json['updated_at']),
    );
  }
}
