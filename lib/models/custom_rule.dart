class CustomRule {
  final String id;
  final String childProfileId;
  final String ruleText;
  final String ruleType;
  final String? goalIdentified;
  final int? ageContext;
  final String? severity;
  final bool isActive;
  final List<String>? blockedChannels;
  final List<String>? blockedCategories;
  final List<String>? allowedCategories;
  final TimeConstraint? timeConstraint;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CustomRule({
    required this.id,
    required this.childProfileId,
    required this.ruleText,
    required this.ruleType,
    this.goalIdentified,
    this.ageContext,
    this.severity,
    this.isActive = true,
    this.blockedChannels,
    this.blockedCategories,
    this.allowedCategories,
    this.timeConstraint,
    required this.createdAt,
    this.updatedAt,
  });

  factory CustomRule.fromJson(Map<String, dynamic> json) {
    return CustomRule(
      id: json['id'],
      childProfileId: json['child_profile_id'],
      ruleText: json['rule_text'],
      ruleType: json['rule_type'],
      goalIdentified: json['goal_identified'],
      ageContext: json['age_context'],
      severity: json['severity'],
      isActive: json['is_active'] ?? true,
      blockedChannels: json['blocked_channels'] != null
          ? (json['blocked_channels'] as List).map((e) => e.toString()).toList()
          : null,
      blockedCategories: json['blocked_categories'] != null
          ? (json['blocked_categories'] as List)
                .map((e) => e.toString())
                .toList()
          : null,
      allowedCategories: json['allowed_categories'] != null
          ? (json['allowed_categories'] as List)
                .map((e) => e.toString())
                .toList()
          : null,
      timeConstraint: json['time_constraint'] != null
          ? TimeConstraint.fromJson(json['time_constraint'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'child_profile_id': childProfileId,
      'rule_text': ruleText,
      'rule_type': ruleType,
      'goal_identified': goalIdentified,
      'age_context': ageContext,
      'severity': severity,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class TimeConstraint {
  final int? dailyLimit; // minutes
  final String? startTime; // HH:MM format
  final String? endTime; // HH:MM format
  final int? weekdayLimit; // minutes
  final int? weekendLimit; // minutes

  TimeConstraint({
    this.dailyLimit,
    this.startTime,
    this.endTime,
    this.weekdayLimit,
    this.weekendLimit,
  });

  factory TimeConstraint.fromJson(Map<String, dynamic> json) {
    return TimeConstraint(
      dailyLimit: json['daily_limit'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      weekdayLimit: json['weekday_limit'],
      weekendLimit: json['weekend_limit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_limit': dailyLimit,
      'start_time': startTime,
      'end_time': endTime,
      'weekday_limit': weekdayLimit,
      'weekend_limit': weekendLimit,
    };
  }

  // Check if current time is within allowed time window
  bool isWithinTimeWindow() {
    if (startTime == null || endTime == null) return true;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final startParts = startTime!.split(':');
    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

    final endParts = endTime!.split(':');
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  // Get the applicable limit based on current day
  int? getApplicableLimit() {
    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    if (isWeekend && weekendLimit != null) return weekendLimit;
    if (!isWeekend && weekdayLimit != null) return weekdayLimit;
    return dailyLimit;
  }
}
