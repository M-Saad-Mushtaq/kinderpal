import 'package:supabase_flutter/supabase_flutter.dart';

class ViewingHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Add viewing history
  Future<void> addViewingHistory({
    required String childProfileId,
    required String videoId,
    required String videoTitle,
    required int durationWatched,
  }) async {
    try {
      await _supabase.from('viewing_history').insert({
        'child_profile_id': childProfileId,
        'video_id': videoId,
        'video_title': videoTitle,
        'duration_watched': durationWatched,
        'watched_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get viewing history for a child profile
  Future<List<Map<String, dynamic>>> getViewingHistory({
    required String childProfileId,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('viewing_history')
          .select()
          .eq('child_profile_id', childProfileId)
          .order('watched_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get total screen time for a child profile
  Future<int> getTotalScreenTime({
    required String childProfileId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('viewing_history')
          .select('duration_watched')
          .eq('child_profile_id', childProfileId);

      if (startDate != null) {
        query = query.gte('watched_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('watched_at', endDate.toIso8601String());
      }

      final response = await query;

      int totalSeconds = 0;
      for (var record in response) {
        totalSeconds += (record['duration_watched'] as int?) ?? 0;
      }

      return totalSeconds;
    } catch (e) {
      rethrow;
    }
  }

  // Delete viewing history
  Future<void> deleteViewingHistory(String id) async {
    try {
      await _supabase.from('viewing_history').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}
