import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/custom_rule.dart';

class CustomRulesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all rules for a child profile using the helper view
  Future<List<CustomRule>> getRules(String childProfileId) async {
    try {
      final response = await _supabase
          .from('v_custom_rules_complete')
          .select()
          .eq('child_profile_id', childProfileId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CustomRule.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching rules: $e');
      return [];
    }
  }

  /// Get only active rules for a child profile
  Future<List<CustomRule>> getActiveRules(String childProfileId) async {
    try {
      final response = await _supabase
          .from('v_custom_rules_complete')
          .select()
          .eq('child_profile_id', childProfileId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CustomRule.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching active rules: $e');
      return [];
    }
  }

  /// Save a parsed rule from Ollama with all related data
  Future<CustomRule> saveRule({
    required String childProfileId,
    required String ruleText,
    required Map<String, dynamic> parsedRule,
  }) async {
    print('📝 Saving rule: $ruleText');
    print('📊 Parsed data: $parsedRule');

    // 1. Insert main rule
    final ruleResponse = await _supabase
        .from('custom_rules')
        .insert({
          'child_profile_id': childProfileId,
          'rule_text': ruleText,
          'rule_type': parsedRule['rule_type'],
          'goal_identified': parsedRule['goal_identified'],
          'age_context': parsedRule['age_context'],
          'severity': parsedRule['severity'],
        })
        .select()
        .single();

    final ruleId = ruleResponse['id'];
    print('✅ Rule saved with ID: $ruleId');

    // 2. Insert blocked channels
    if (parsedRule['blocked_channels'] != null &&
        (parsedRule['blocked_channels'] as List).isNotEmpty) {
      final channels = (parsedRule['blocked_channels'] as List)
          .map(
            (ch) => {'custom_rule_id': ruleId, 'channel_name': ch.toString()},
          )
          .toList();

      await _supabase.from('rule_blocked_channels').insert(channels);
      print(
        '🚫 Saved ${channels.length} blocked channels: ${channels.map((c) => c['channel_name']).join(", ")}',
      );
    }

    // 3. Insert blocked categories
    if (parsedRule['blocked_categories'] != null &&
        (parsedRule['blocked_categories'] as List).isNotEmpty) {
      final categories = (parsedRule['blocked_categories'] as List)
          .map((cat) => {'custom_rule_id': ruleId, 'category': cat.toString()})
          .toList();

      await _supabase.from('rule_blocked_categories').insert(categories);
      print(
        '🚫 Saved ${categories.length} blocked categories: ${categories.map((c) => c['category']).join(", ")}',
      );
    }

    // 4. Insert allowed categories
    if (parsedRule['allowed_categories'] != null &&
        (parsedRule['allowed_categories'] as List).isNotEmpty) {
      final categories = (parsedRule['allowed_categories'] as List)
          .map((cat) => {'custom_rule_id': ruleId, 'category': cat.toString()})
          .toList();

      await _supabase.from('rule_allowed_categories').insert(categories);
      print(
        '✅ Saved ${categories.length} allowed categories: ${categories.map((c) => c['category']).join(", ")}',
      );
    }

    // 5. Insert time constraints
    if (parsedRule['time_constraint'] != null) {
      final constraint = parsedRule['time_constraint'] as Map<String, dynamic>;
      await _supabase.from('rule_time_constraints').insert({
        'custom_rule_id': ruleId,
        'daily_limit': constraint['daily_limit'],
        'start_time': constraint['start_time'],
        'end_time': constraint['end_time'],
        'weekday_limit': constraint['weekday_limit'],
        'weekend_limit': constraint['weekend_limit'],
      });
      print(
        '⏰ Saved time constraints: ${constraint['daily_limit']} min daily limit',
      );
    }

    // 6. Fetch complete rule with all relations
    final completeRule = await _supabase
        .from('v_custom_rules_complete')
        .select()
        .eq('id', ruleId)
        .single();

    return CustomRule.fromJson(completeRule);
  }

  /// Delete a rule (cascade deletes all related data)
  Future<void> deleteRule(String ruleId) async {
    await _supabase.from('custom_rules').delete().eq('id', ruleId);
  }

  /// Toggle rule active status
  Future<void> toggleRule(String ruleId, bool isActive) async {
    await _supabase
        .from('custom_rules')
        .update({'is_active': isActive})
        .eq('id', ruleId);
  }

  /// Get all blocked channels from active rules
  Future<Set<String>> getBlockedChannels(String childProfileId) async {
    final rules = await getActiveRules(childProfileId);
    return rules
        .expand((rule) => rule.blockedChannels ?? [])
        .map((ch) => ch.toLowerCase())
        .toSet()
        .cast<String>();
  }

  /// Get all blocked categories from active rules
  Future<Set<String>> getBlockedCategories(String childProfileId) async {
    final rules = await getActiveRules(childProfileId);
    return rules
        .expand((rule) => rule.blockedCategories ?? [])
        .map((cat) => cat.toLowerCase())
        .toSet()
        .cast<String>();
  }

  /// Get all allowed categories from active rules
  Future<Set<String>> getAllowedCategories(String childProfileId) async {
    final rules = await getActiveRules(childProfileId);
    return rules
        .expand((rule) => rule.allowedCategories ?? [])
        .map((cat) => cat.toLowerCase())
        .toSet()
        .cast<String>();
  }

  /// Check if video playback is allowed based on time constraints
  Future<bool> canPlayVideo({
    required String childProfileId,
    required int currentScreenTime, // in minutes
  }) async {
    final rules = await getActiveRules(childProfileId);

    for (final rule in rules) {
      if (rule.timeConstraint != null) {
        final constraint = rule.timeConstraint!;

        // Check time window
        if (!constraint.isWithinTimeWindow()) {
          return false;
        }

        // Check daily/weekday/weekend limit
        final limit = constraint.getApplicableLimit();
        if (limit != null && currentScreenTime >= limit) {
          return false;
        }
      }
    }

    return true;
  }
}
