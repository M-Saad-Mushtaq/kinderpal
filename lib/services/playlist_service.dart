import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/playlist.dart';

class PlaylistService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Playlist> savePlaylist({
    required String childProfileId,
    required String name,
    required List<String> videoIds,
    String? description,
  }) async {
    final response = await _supabase
        .from('playlists')
        .insert({
          'child_profile_id': childProfileId,
          'name': name,
          'description': description,
          'video_ids': videoIds,
        })
        .select()
        .single();

    return Playlist.fromJson(response);
  }

  Future<List<Playlist>> getPlaylists(String childProfileId) async {
    final response = await _supabase
        .from('playlists')
        .select()
        .eq('child_profile_id', childProfileId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Playlist.fromJson(json)).toList();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _supabase.from('playlists').delete().eq('id', playlistId);
  }
}
