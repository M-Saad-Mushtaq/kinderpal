import 'dart:convert';
import 'package:http/http.dart' as http;

/// AI service for parsing custom rules
/// Supports both local Ollama and cloud Google Gemini API
class AIParserService {
  // Ollama configuration (local, free, runs on your machine)
  static const String ollamaUrl = 'http://localhost:11434/api/chat';

  // Google Gemini API (cloud, free tier: 15 requests/minute, 1500/day)
  // Get your free API key at: https://aistudio.google.com/app/apikey
  static const String geminiApiKey = 'AIzaSyBbrYOYrYj3XBoKULQUcpQ-OofaeDzvgag';
  static const String geminiUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent';

  final bool _useGemini;

  /// Create AI parser service
  /// [useGemini] - If true, uses Google Gemini API. If false, uses local Ollama
  AIParserService({bool useGemini = false}) : _useGemini = useGemini;

  /// Parse natural language rule input into structured format
  Future<Map<String, dynamic>> parseRule(String ruleInput) async {
    if (_useGemini) {
      return await _parseWithGemini(ruleInput);
    } else {
      return await _parseWithOllama(ruleInput);
    }
  }

  /// Parse rule using local Ollama
  Future<Map<String, dynamic>> _parseWithOllama(String ruleInput) async {
    try {
      final response = await http
          .post(
            Uri.parse(ollamaUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'llama3.2',
              'messages': [
                {'role': 'system', 'content': _getSystemPrompt()},
                {'role': 'user', 'content': ruleInput},
              ],
              'format': _getRuleSchema(),
              'stream': false,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final parsedContent = jsonDecode(result['message']['content']);

        if (parsedContent['rule_type'] == null) {
          throw Exception('Rule type is required');
        }

        return parsedContent;
      } else {
        throw Exception(
          'Ollama error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Ollama parsing error: $e');
      rethrow;
    }
  }

  /// Parse rule using Google Gemini API (free cloud alternative)
  Future<Map<String, dynamic>> _parseWithGemini(String ruleInput) async {
    if (geminiApiKey.isEmpty) {
      throw Exception(
        'Gemini API key not configured. Add your free key in ai_parser_service.dart',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$geminiUrl?key=$geminiApiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {
                      'text':
                          '''${_getSystemPrompt()}

User input: "$ruleInput"

Respond ONLY with valid JSON matching this schema:
${jsonEncode(_getRuleSchema())}

Extract the rule components and return JSON.''',
                    },
                  ],
                },
              ],
              'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 1000},
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final text = result['candidates'][0]['content']['parts'][0]['text'];

        // Extract JSON from response (Gemini might add markdown formatting)
        String jsonText = text.trim();
        if (jsonText.startsWith('```json')) {
          jsonText = jsonText.substring(7);
        }
        if (jsonText.startsWith('```')) {
          jsonText = jsonText.substring(3);
        }
        if (jsonText.endsWith('```')) {
          jsonText = jsonText.substring(0, jsonText.length - 3);
        }

        final parsedContent = jsonDecode(jsonText.trim());

        print('🤖 Gemini parsed rule:');
        print('   Type: ${parsedContent['rule_type']}');
        print('   Blocked channels: ${parsedContent['blocked_channels']}');
        print('   Blocked categories: ${parsedContent['blocked_categories']}');
        print('   Time constraint: ${parsedContent['time_constraint']}');

        if (parsedContent['rule_type'] == null) {
          throw Exception('Rule type is required');
        }

        return parsedContent;
      } else if (response.statusCode == 503) {
        throw Exception(
          'Gemini is temporarily busy. Try again in a few seconds.',
        );
      } else {
        final errorMsg = response.statusCode == 400
            ? 'Invalid API key. Create new key at aistudio.google.com/app/apikey'
            : response.statusCode == 429
            ? 'Rate limit: 15 requests/minute, 1500/day'
            : 'API error (${response.statusCode})';
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('Gemini parsing error: $e');
      rethrow;
    }
  }

  /// Test if the selected AI service is accessible
  Future<bool> testConnection() async {
    if (_useGemini) {
      return await _testGeminiConnection();
    } else {
      return await _testOllamaConnection();
    }
  }

  Future<bool> _testOllamaConnection() async {
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

  Future<bool> _testGeminiConnection() async {
    if (geminiApiKey.isEmpty) {
      print('Gemini: API key is empty');
      return false;
    }

    print('Testing Gemini API with key: ${geminiApiKey.substring(0, 10)}...');

    try {
      final response = await http
          .post(
            Uri.parse('$geminiUrl?key=$geminiApiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': 'Test'},
                  ],
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Gemini response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Gemini API connected successfully!');
        return true;
      } else if (response.statusCode == 503) {
        print('⚠️ Gemini model temporarily overloaded, but API is working!');
        return true; // API is configured correctly, just busy
      } else {
        print('❌ Gemini API error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Gemini connection test failed: $e');
      return false;
    }
  }

  String _getSystemPrompt() {
    return '''You are a rule parser for KinderPal parental control app. 
Extract rule components from parent input about YouTube channels, videos, and content. 
Only populate fields that are explicitly mentioned in the input.
Be strict about channel names and categories.''';
  }

  /// Get the JSON schema for AI structured output
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
}
