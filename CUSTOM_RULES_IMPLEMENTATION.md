# Custom Rules Implementation Guide

## Overview
This guide explains how to implement the structured custom rules system with Ollama LLM parsing in KinderPal.

## Database Schema

### Tables Created:
1. **custom_rules** - Main table storing parsed rules
2. **rule_blocked_channels** - Channels to block
3. **rule_blocked_categories** - Content categories to block
4. **rule_allowed_categories** - Content categories to allow/promote
5. **rule_time_constraints** - Time limits and restrictions

### Key Features:
- ✅ Supports all rule types from Ollama output
- ✅ Proper foreign key relationships
- ✅ Row Level Security (RLS) policies
- ✅ Automatic timestamp updates
- ✅ Indexed for performance
- ✅ Migration script included to preserve existing rules

## Setup Instructions

### Step 1: Run SQL in Supabase

1. Go to Supabase Dashboard → SQL Editor
2. Copy content from `database/custom_rules_schema.sql`
3. Execute the SQL script
4. Verify tables are created

### Step 2: Update Flutter Models

You need to create new Dart models to match the database structure:

**File: `lib/models/custom_rule.dart`**
```dart
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
  final DateTime updatedAt;

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
    required this.updatedAt,
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
      blockedChannels: (json['blocked_channels'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      blockedCategories: (json['blocked_categories'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      allowedCategories: (json['allowed_categories'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      timeConstraint: json['time_constraint'] != null
          ? TimeConstraint.fromJson(json['time_constraint'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class TimeConstraint {
  final int? dailyLimit;
  final String? startTime;
  final String? endTime;
  final int? weekdayLimit;
  final int? weekendLimit;

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
}
```

### Step 3: Create Custom Rules Service

**File: `lib/services/custom_rules_service.dart`**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/custom_rule.dart';

class CustomRulesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all rules for a child profile
  Future<List<CustomRule>> getRules(String childProfileId) async {
    final response = await _supabase
        .from('v_custom_rules_complete')
        .select()
        .eq('child_profile_id', childProfileId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => CustomRule.fromJson(json))
        .toList();
  }

  // Save parsed rule from Ollama
  Future<CustomRule> saveRule({
    required String childProfileId,
    required String ruleText,
    required Map<String, dynamic> parsedRule,
  }) async {
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

    // 2. Insert blocked channels
    if (parsedRule['blocked_channels'] != null) {
      final channels = (parsedRule['blocked_channels'] as List)
          .map((ch) => {
                'custom_rule_id': ruleId,
                'channel_name': ch,
              })
          .toList();
      
      if (channels.isNotEmpty) {
        await _supabase.from('rule_blocked_channels').insert(channels);
      }
    }

    // 3. Insert blocked categories
    if (parsedRule['blocked_categories'] != null) {
      final categories = (parsedRule['blocked_categories'] as List)
          .map((cat) => {
                'custom_rule_id': ruleId,
                'category': cat,
              })
          .toList();
      
      if (categories.isNotEmpty) {
        await _supabase.from('rule_blocked_categories').insert(categories);
      }
    }

    // 4. Insert allowed categories
    if (parsedRule['allowed_categories'] != null) {
      final categories = (parsedRule['allowed_categories'] as List)
          .map((cat) => {
                'custom_rule_id': ruleId,
                'category': cat,
              })
          .toList();
      
      if (categories.isNotEmpty) {
        await _supabase.from('rule_allowed_categories').insert(categories);
      }
    }

    // 5. Insert time constraints
    if (parsedRule['time_constraint'] != null) {
      await _supabase.from('rule_time_constraints').insert({
        'custom_rule_id': ruleId,
        ...parsedRule['time_constraint'],
      });
    }

    // Fetch complete rule with all relations
    final completeRule = await _supabase
        .from('v_custom_rules_complete')
        .select()
        .eq('id', ruleId)
        .single();

    return CustomRule.fromJson(completeRule);
  }

  // Delete a rule (cascade deletes all related data)
  Future<void> deleteRule(String ruleId) async {
    await _supabase.from('custom_rules').delete().eq('id', ruleId);
  }

  // Toggle rule active status
  Future<void> toggleRule(String ruleId, bool isActive) async {
    await _supabase
        .from('custom_rules')
        .update({'is_active': isActive})
        .eq('id', ruleId);
  }
}
```

### Step 4: Integrate Ollama Rule Parsing

You'll need to call your Ollama API from Flutter. Create a service:

**File: `lib/services/ollama_service.dart`**
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class OllamaService {
  // Update with your Ollama server URL
  static const String ollamaUrl = 'http://YOUR_OLLAMA_SERVER:11434/api/chat';

  Future<Map<String, dynamic>> parseRule(String ruleInput) async {
    final response = await http.post(
      Uri.parse(ollamaUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': 'llama3.2',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a rule parser for KinderPal. Extract rule components from parent input about YouTube channels, videos, and content. Only populate fields that are explicitly mentioned.'
          },
          {'role': 'user', 'content': ruleInput}
        ],
        'format': _getRuleSchema(),
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return jsonDecode(result['message']['content']);
    } else {
      throw Exception('Failed to parse rule: ${response.body}');
    }
  }

  Map<String, dynamic> _getRuleSchema() {
    return {
      'type': 'object',
      'properties': {
        'rule_type': {
          'type': 'string',
          'enum': [
            'channel_block',
            'time_limit',
            'content_filter',
            'goal_based',
            'category_control',
            'mixed'
          ]
        },
        'blocked_channels': {
          'type': 'array',
          'items': {'type': 'string'}
        },
        'blocked_categories': {
          'type': 'array',
          'items': {'type': 'string'}
        },
        'allowed_categories': {
          'type': 'array',
          'items': {'type': 'string'}
        },
        'time_constraint': {
          'type': 'object',
          'properties': {
            'daily_limit': {'type': 'number'},
            'start_time': {'type': 'string'},
            'end_time': {'type': 'string'},
            'weekday_limit': {'type': 'number'},
            'weekend_limit': {'type': 'number'}
          }
        },
        'goal_identified': {'type': 'string'},
        'age_context': {'type': 'number'},
        'severity': {
          'type': 'string',
          'enum': ['strict', 'moderate', 'lenient']
        }
      },
      'required': ['rule_type']
    };
  }
}
```

### Step 5: Update Custom Rules Screen

Modify `custom_rules_screen.dart` to use the new service:

```dart
// In _addRule() method:
Future<void> _addRule() async {
  if (_ruleController.text.isEmpty) return;

  setState(() => _isLoading = true);

  try {
    final ollamaService = OllamaService();
    final customRulesService = CustomRulesService();
    
    // Parse rule with Ollama
    final parsedRule = await ollamaService.parseRule(_ruleController.text);
    
    // Save to database
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    await customRulesService.saveRule(
      childProfileId: profileProvider.selectedProfile!.id,
      ruleText: _ruleController.text,
      parsedRule: parsedRule,
    );
    
    // Reload rules
    _loadRules();
    
    _ruleController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rule saved successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
```

## Enforcing Rules

### 1. Channel Blocking
In `youtube_service.dart`, filter videos:

```dart
Future<List<YouTubeVideo>> getFilteredVideos({
  required String childProfileId,
}) async {
  // Get rules
  final customRulesService = CustomRulesService();
  final rules = await customRulesService.getRules(childProfileId);
  
  // Get all blocked channels
  final blockedChannels = rules
      .where((r) => r.isActive)
      .expand((r) => r.blockedChannels ?? [])
      .toSet();
  
  // Fetch videos and filter
  final videos = await getHomeFeedVideos(...);
  
  return videos.where((video) {
    return !blockedChannels.contains(video.channelTitle.toLowerCase());
  }).toList();
}
```

### 2. Category Filtering
Similar approach - check video categories against blocked/allowed lists.

### 3. Time Limits
Check in video player before playing:

```dart
Future<bool> canPlayVideo() async {
  final rules = await customRulesService.getRules(childProfileId);
  
  for (final rule in rules.where((r) => r.isActive)) {
    if (rule.timeConstraint != null) {
      // Check daily limit
      if (rule.timeConstraint!.dailyLimit != null) {
        final todayWatchTime = await getTodayScreenTime();
        if (todayWatchTime >= rule.timeConstraint!.dailyLimit! * 60) {
          return false; // Daily limit exceeded
        }
      }
      
      // Check time window
      final now = TimeOfDay.now();
      if (rule.timeConstraint!.startTime != null && 
          rule.timeConstraint!.endTime != null) {
        // Parse and compare times
        ...
      }
    }
  }
  
  return true;
}
```

## Next Steps

1. **Run SQL** - Execute the schema script in Supabase
2. **Create Models** - Add CustomRule and TimeConstraint models
3. **Create Services** - Add CustomRulesService and OllamaService
4. **Update UI** - Modify custom_rules_screen.dart
5. **Implement Enforcement** - Add rule checking in video filtering and playback
6. **Test** - Try adding various rules and verify they're saved correctly

## Testing

Test with these example rules:
- "Block Cocomelon channel"
- "Limit to 2 hours daily"
- "Block violent content"
- "Only allow educational videos"
- "No videos after 8 PM"
