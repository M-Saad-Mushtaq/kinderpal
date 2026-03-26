import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/youtube_video.dart';
import '../models/flagged_inappropriate_video.dart';
import 'api_service.dart';
import 'ai_parser_service.dart';

class FlaggedInappropriateService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ApiService _apiService = ApiService();
  final AIParserService _aiParserService = AIParserService(useGemini: true);

  Future<void> processAndSaveFlaggedVideo({
    required String childProfileId,
    required int childAge,
    required YouTubeVideo video,
    required String modelLabel,
  }) async {
    final videoUrl = 'https://www.youtube.com/watch?v=${video.id}';

    String? transcript;
    bool transcriptAvailable = false;
    DateTime? transcriptFetchedAt;

    TranscriptReviewResult? review;
    DateTime? geminiReviewedAt;
    String status = 'pending_transcript';

    try {
      transcript = await _apiService.fetchTranscript(videoUrl);
      transcriptAvailable = transcript != null && transcript.trim().isNotEmpty;
      transcriptFetchedAt = DateTime.now().toUtc();

      if (transcriptAvailable) {
        status = 'pending_gemini';
        try {
          review = await _aiParserService.reviewTranscriptForAge(
            transcript: transcript!,
            childAge: childAge,
            videoTitle: video.title,
            videoUrl: videoUrl,
          );
          geminiReviewedAt = DateTime.now().toUtc();
          status = 'reviewed';
        } catch (e) {
          status = 'error';
          print('Gemini second opinion failed for ${video.id}: $e');
        }
      }
    } catch (e) {
      status = 'error';
      print('Transcript fetch failed for ${video.id}: $e');
    }

    final payload = <String, dynamic>{
      'child_profile_id': childProfileId,
      'video_id': video.id,
      'video_title': video.title,
      'video_url': videoUrl,
      'model_flagged_inappropriate': true,
      'model_label': modelLabel,
      'model_reason': 'flagged_inappropriate by model',
      'transcript': transcript,
      'transcript_available': transcriptAvailable,
      'transcript_fetched_at': transcriptFetchedAt?.toIso8601String(),
      'reviewed_for_age': childAge,
      'gemini_is_inappropriate': review?.isInappropriate,
      'gemini_confidence': review?.confidence,
      'gemini_reason': review?.reason,
      'gemini_response': review == null
          ? null
          : {
              'is_inappropriate': review.isInappropriate,
              'confidence': review.confidence,
              'reason': review.reason,
            },
      'gemini_reviewed_at': geminiReviewedAt?.toIso8601String(),
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _supabase.from('flagged_inappropriate_videos').upsert(
          payload,
          onConflict: 'child_profile_id,video_id',
        );
  }

  Future<List<FlaggedInappropriateVideo>> getFlaggedVideos(
    String childProfileId,
  ) async {
    final response = await _supabase
        .from('flagged_inappropriate_videos')
        .select()
        .eq('child_profile_id', childProfileId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response)
        .map(FlaggedInappropriateVideo.fromJson)
        .toList();
  }

  Future<int> getFlaggedVideosCount(String childProfileId) async {
    final response = await _supabase
        .from('flagged_inappropriate_videos')
        .select('id')
        .eq('child_profile_id', childProfileId);

    return List<Map<String, dynamic>>.from(response).length;
  }
}
