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

  // Update viewing history (updates the most recent record for a video)
  Future<void> updateViewingHistory({
    required String childProfileId,
    required String videoId,
    required String videoTitle,
    required int durationWatched,
  }) async {
    try {
      final now = DateTime.now();
      final tenMinutesAgo = now.subtract(const Duration(minutes: 10));

      print(
        'DEBUG: Updating video: $videoTitle (ID: $videoId) with duration: $durationWatched seconds',
      );

      // Find the most recent record for this video
      final existing = await _supabase
          .from('viewing_history')
          .select()
          .eq('child_profile_id', childProfileId)
          .eq('video_id', videoId)
          .gte('watched_at', tenMinutesAgo.toIso8601String())
          .order('watched_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        // Update the existing record with the actual watch duration
        print(
          'DEBUG: Updating record (ID: ${existing['id']}) with duration: $durationWatched',
        );
        await _supabase
            .from('viewing_history')
            .update({
              'duration_watched': durationWatched,
              'watched_at': now.toIso8601String(),
            })
            .eq('id', existing['id']);
        print('DEBUG: Update successful');
      } else {
        print(
          'DEBUG: No recent record found to update, this shouldn\'t happen',
        );
      }
    } catch (e) {
      print('DEBUG: Error in updateViewingHistory: $e');
      rethrow;
    }
  }

  // Update or insert viewing history (upsert)
  Future<void> upsertViewingHistory({
    required String childProfileId,
    required String videoId,
    required String videoTitle,
    required int durationWatched,
  }) async {
    try {
      // Check if record exists for this video in the last 10 minutes
      final now = DateTime.now();
      final tenMinutesAgo = now.subtract(const Duration(minutes: 10));

      print(
        'DEBUG: Upserting video: $videoTitle (ID: $videoId) with duration: $durationWatched seconds',
      );

      final existing = await _supabase
          .from('viewing_history')
          .select()
          .eq('child_profile_id', childProfileId)
          .eq('video_id', videoId)
          .gte('watched_at', tenMinutesAgo.toIso8601String())
          .maybeSingle();

      if (existing != null) {
        // Update existing record
        print(
          'DEBUG: Found existing record (ID: ${existing['id']}), updating with duration: $durationWatched',
        );
        await _supabase
            .from('viewing_history')
            .update({
              'duration_watched': durationWatched,
              'watched_at': now.toIso8601String(),
            })
            .eq('id', existing['id']);
        print('DEBUG: Update successful');
      } else {
        // Insert new record
        print('DEBUG: No existing record found, inserting new record');
        await _supabase.from('viewing_history').insert({
          'child_profile_id': childProfileId,
          'video_id': videoId,
          'video_title': videoTitle,
          'duration_watched': durationWatched,
          'watched_at': now.toIso8601String(),
        });
        print('DEBUG: Insert successful');
      }
    } catch (e) {
      print('DEBUG: Error in upsertViewingHistory: $e');
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
