import 'dart:convert';
import 'package:http/http.dart' as http;

class OllamaService {
  // Update this URL to match your Ollama server
  // For local development: 'http://localhost:11434/api/chat'
  // For network: 'http://YOUR_IP:11434/api/chat'
  static const String ollamaUrl = 'http://localhost:11434/api/chat';

  /// Parse natural language rule input into structured format
  Future<Map<String, dynamic>> parseRule(String ruleInput) async {
    try {
      final response = await http.post(
        Uri.parse(ollamaUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama3.2',
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are a rule parser for KinderPal parental control app. 
Extract rule components from parent input about YouTube channels, videos, and content. 
Only populate fields that are explicitly mentioned in the input.
Be strict about channel names and categories.''',
            },
            {'role': 'user', 'content': ruleInput},
          ],
          'format': _getRuleSchema(),
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final parsedContent = jsonDecode(result['message']['content']);

        // Validate required fields
        if (parsedContent['rule_type'] == null) {
          throw Exception('Rule type is required');
        }

        return parsedContent;
      } else {
        throw Exception(
          'Failed to parse rule: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Ollama parsing error: $e');
      rethrow;
    }
  }

  /// Get the JSON schema for Ollama structured output
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
            'mixed',
          ],
          'description': 'Type of parental control rule',
        },
        'blocked_channels': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'List of YouTube channel names to block',
        },
        'blocked_categories': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'List of content categories to block (gaming, vlogs, etc.)',
        },
        'allowed_categories': {
          'type': 'array',
          'items': {'type': 'string'},
          'description':
              'List of content categories to allow/promote (educational, science, etc.)',
        },
        'time_constraint': {
          'type': 'object',
          'properties': {
            'daily_limit': {
              'type': 'number',
              'description': 'Total minutes allowed per day',
            },
            'start_time': {
              'type': 'string',
              'description': 'Start time in HH:MM format (24-hour)',
            },
            'end_time': {
              'type': 'string',
              'description': 'End time in HH:MM format (24-hour)',
            },
            'weekday_limit': {
              'type': 'number',
              'description': 'Minutes allowed on weekdays',
            },
            'weekend_limit': {
              'type': 'number',
              'description': 'Minutes allowed on weekends',
            },
          },
        },
        'goal_identified': {
          'type': 'string',
          'description': 'Parent\'s goal or reason for the rule',
        },
        'age_context': {
          'type': 'number',
          'description': 'Child\'s age if mentioned',
        },
        'severity': {
          'type': 'string',
          'enum': ['strict', 'moderate', 'lenient'],
          'description': 'How strictly to enforce the rule',
        },
      },
      'required': ['rule_type'],
    };
  }

  /// Test if Ollama server is accessible
  Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse(ollamaUrl.replaceAll('/api/chat', '/api/tags')))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Ollama connection test failed: $e');
      return false;
    }
  }
}
