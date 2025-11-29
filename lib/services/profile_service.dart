import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/child_profile.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all child profiles for the current guardian
  Future<List<ChildProfile>> getChildProfiles() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('child_profiles')
          .select()
          .eq('guardian_id', userId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ChildProfile.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Create a new child profile
  Future<ChildProfile> createChildProfile({
    required String name,
    required int age,
    List<String> preferences = const [],
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('child_profiles')
          .insert({
            'guardian_id': userId,
            'name': name,
            'age': age,
            'preferences': preferences,
          })
          .select()
          .single();

      return ChildProfile.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Update child profile
  Future<ChildProfile> updateChildProfile({
    required String profileId,
    String? name,
    int? age,
    List<String>? preferences,
    List<String>? customRules,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (age != null) updates['age'] = age;
      if (preferences != null) updates['preferences'] = preferences;
      if (customRules != null) updates['custom_rules'] = customRules;

      final response = await _supabase
          .from('child_profiles')
          .update(updates)
          .eq('id', profileId)
          .select()
          .single();

      return ChildProfile.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Delete child profile
  Future<void> deleteChildProfile(String profileId) async {
    try {
      await _supabase.from('child_profiles').delete().eq('id', profileId);
    } catch (e) {
      rethrow;
    }
  }
}
