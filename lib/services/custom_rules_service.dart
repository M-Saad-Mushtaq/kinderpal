import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/custom_rule.dart';

/// All active rule data aggregated in a single object so callers
/// only need one DB round-trip before filtering videos.
class RuleFilterData {
  final Set<String> blockedChannels;
  final Set<String> blockedCategories;
  final Set<String> allowedCategories;
  final List<TimeConstraint> timeConstraints;

  const RuleFilterData({
    required this.blockedChannels,
    required this.blockedCategories,
    required this.allowedCategories,
    required this.timeConstraints,
  });

  /// True when the guardian has restricted content to a specific allow-list.
  bool get hasAllowedFilter => allowedCategories.isNotEmpty;

  bool get isEmpty =>
      blockedChannels.isEmpty &&
      blockedCategories.isEmpty &&
      allowedCategories.isEmpty &&
      timeConstraints.isEmpty;
}

class CustomRulesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Read ──────────────────────────────────────────────────────────────────

  /// All rules for a child profile (active + inactive).
  Future<List<CustomRule>> getRules(String childProfileId) async {
    try {
      final response = await _supabase
          .from('custom_rules')
          .select()
          .eq('child_profile_id', childProfileId)
          .order('created_at', ascending: false);
      return (response as List).map((j) => CustomRule.fromJson(j)).toList();
    } catch (e) {
      print('Error fetching rules: $e');
      return [];
    }
  }

  /// Only active rules for a child profile.
  Future<List<CustomRule>> getActiveRules(String childProfileId) async {
    try {
      final response = await _supabase
          .from('custom_rules')
          .select()
          .eq('child_profile_id', childProfileId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return (response as List).map((j) => CustomRule.fromJson(j)).toList();
    } catch (e) {
      print('Error fetching active rules: $e');
      return [];
    }
  }

  /// Aggregated rule data for a profile — single DB call, used by video filter.
  Future<RuleFilterData> getActiveRuleData(String childProfileId) async {
    final rules = await getActiveRules(childProfileId);

    final blockedChannels = rules
        .expand((r) => r.blockedChannels ?? [])
        .map((c) => c.toLowerCase().trim())
        .toSet();

    final blockedCategories = rules
        .expand((r) => r.blockedCategories ?? [])
        .map((c) => c.toLowerCase().trim())
        .toSet();

    final allowedCategories = rules
        .expand((r) => r.allowedCategories ?? [])
        .map((c) => c.toLowerCase().trim())
        .toSet();

    final timeConstraints = rules
        .where((r) => r.timeConstraint != null)
        .map((r) => r.timeConstraint!)
        .toList();

    return RuleFilterData(
      blockedChannels: (blockedChannels as Set).cast<String>(),
      blockedCategories: (blockedCategories as Set).cast<String>(),
      allowedCategories: (allowedCategories as Set).cast<String>(),
      timeConstraints: timeConstraints,
    );
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Save an AI-parsed rule to the single custom_rules table and
  /// keep child_profiles.custom_rules text array in sync.
  Future<CustomRule> saveRule({
    required String childProfileId,
    required String ruleText,
    required Map<String, dynamic> parsedRule,
  }) async {
    print('📝 Saving rule: $ruleText');
    print('📊 Parsed data: $parsedRule');

    final row = {
      'child_profile_id': childProfileId,
      'rule_text': ruleText,
      'rule_type': parsedRule['rule_type'],
      'goal_identified': parsedRule['goal_identified'],
      'age_context': parsedRule['age_context'],
      'severity': parsedRule['severity'],
      'blocked_channels': (parsedRule['blocked_channels'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      'blocked_categories': (parsedRule['blocked_categories'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      'allowed_categories': (parsedRule['allowed_categories'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      'time_constraint': parsedRule['time_constraint'],
      'is_active': true,
    };

    final response = await _supabase
        .from('custom_rules')
        .insert(row)
        .select()
        .single();

    print('✅ Rule saved with ID: ${response['id']}');

    // Keep the child_profiles.custom_rules text array in sync so the
    // legacy keyword filter and profile reads stay consistent.
    await _appendRuleTextToProfile(childProfileId, ruleText);

    return CustomRule.fromJson(response);
  }

  /// Delete a rule and remove its text from child_profiles.custom_rules.
  Future<void> deleteRule(String ruleId) async {
    try {
      final existing = await _supabase
          .from('custom_rules')
          .select('rule_text, child_profile_id')
          .eq('id', ruleId)
          .maybeSingle();

      await _supabase.from('custom_rules').delete().eq('id', ruleId);

      if (existing != null) {
        await _removeRuleTextFromProfile(
          existing['child_profile_id'] as String,
          existing['rule_text'] as String,
        );
      }
    } catch (e) {
      print('Error deleting rule: $e');
      rethrow;
    }
  }

  /// Toggle whether a rule is enforced.
  Future<void> toggleRule(String ruleId, bool isActive) async {
    await _supabase
        .from('custom_rules')
        .update({'is_active': isActive})
        .eq('id', ruleId);
  }

  // ── Convenience getters (delegate to getActiveRuleData) ───────────────────

  Future<Set<String>> getBlockedChannels(String childProfileId) async =>
      (await getActiveRuleData(childProfileId)).blockedChannels;

  Future<Set<String>> getBlockedCategories(String childProfileId) async =>
      (await getActiveRuleData(childProfileId)).blockedCategories;

  Future<Set<String>> getAllowedCategories(String childProfileId) async =>
      (await getActiveRuleData(childProfileId)).allowedCategories;

  /// Returns false if the child has exceeded a daily/weekday/weekend screen-
  /// time limit or is outside an allowed time window.
  Future<bool> canPlayVideo({
    required String childProfileId,
    required int currentScreenTime, // minutes watched today
  }) async {
    final ruleData = await getActiveRuleData(childProfileId);
    for (final constraint in ruleData.timeConstraints) {
      if (!constraint.isWithinTimeWindow()) return false;
      final limit = constraint.getApplicableLimit();
      if (limit != null && currentScreenTime >= limit) return false;
    }
    return true;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _appendRuleTextToProfile(
    String childProfileId,
    String ruleText,
  ) async {
    try {
      final profile = await _supabase
          .from('child_profiles')
          .select('custom_rules')
          .eq('id', childProfileId)
          .single();
      final current = List<String>.from(
        (profile['custom_rules'] as List? ?? []).map((e) => e.toString()),
      );
      if (!current.contains(ruleText)) {
        current.add(ruleText);
        await _supabase
            .from('child_profiles')
            .update({'custom_rules': current})
            .eq('id', childProfileId);
      }
    } catch (e) {
      print('Error syncing rule text to profile: $e');
    }
  }

  Future<void> _removeRuleTextFromProfile(
    String childProfileId,
    String ruleText,
  ) async {
    try {
      final profile = await _supabase
          .from('child_profiles')
          .select('custom_rules')
          .eq('id', childProfileId)
          .single();
      final updated = List<String>.from(
        (profile['custom_rules'] as List? ?? [])
            .map((e) => e.toString())
            .where((r) => r != ruleText),
      );
      await _supabase
          .from('child_profiles')
          .update({'custom_rules': updated})
          .eq('id', childProfileId);
    } catch (e) {
      print('Error removing rule text from profile: $e');
    }
  }
}
