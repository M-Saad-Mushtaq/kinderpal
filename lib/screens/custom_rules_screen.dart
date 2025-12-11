import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';
import '../providers/profile_provider.dart';
import '../services/custom_rules_service.dart';
import '../services/ai_parser_service.dart';
import '../models/custom_rule.dart';

class CustomRulesScreen extends StatefulWidget {
  const CustomRulesScreen({super.key});

  @override
  State<CustomRulesScreen> createState() => _CustomRulesScreenState();
}

class _CustomRulesScreenState extends State<CustomRulesScreen> {
  final _ruleController = TextEditingController();
  final _customRulesService = CustomRulesService();
  // Using Google Gemini AI for smart rule parsing (free)
  final _aiService = AIParserService(useGemini: true);
  List<CustomRule> rules = [];
  bool _isLoading = false;
  bool _aiAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkOllamaConnection();
    _loadRules();
  }

  Future<void> _checkOllamaConnection() async {
    final available = await _aiService.testConnection();
    if (mounted) {
      setState(() => _aiAvailable = available);
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '⚠️ AI parsing disabled. Rules will save as basic text.\nCheck your Gemini API key in ai_parser_service.dart',
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ AI parsing enabled!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _loadRules() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );

    // If no profile is selected, try to load profiles first
    if (profileProvider.selectedProfile == null && !profileProvider.isLoading) {
      await profileProvider.loadProfiles();
      // If still no profile after loading, select the first one
      if (profileProvider.profiles.isNotEmpty &&
          profileProvider.selectedProfile == null) {
        profileProvider.selectProfile(profileProvider.profiles.first);
      }
    }

    final selectedProfile = profileProvider.selectedProfile;

    if (selectedProfile != null) {
      final loadedRules = await _customRulesService.getRules(
        selectedProfile.id,
      );
      if (mounted) {
        setState(() => rules = loadedRules);
      }
    }
  }

  @override
  void dispose() {
    _ruleController.dispose();
    super.dispose();
  }

  Future<void> _addRule() async {
    if (_ruleController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final selectedProfile = profileProvider.selectedProfile;

      if (selectedProfile == null) {
        throw Exception('No profile selected');
      }

      final ruleText = _ruleController.text;

      // Try to parse with AI if available
      Map<String, dynamic>? parsedRule;
      if (_aiAvailable) {
        try {
          parsedRule = await _aiService.parseRule(ruleText);
        } catch (e) {
          print('AI parsing failed: $e');
          // Continue without parsing - fallback to simple text
        }
      }

      // If AI parsing failed or not available, create simple content_filter rule
      parsedRule ??= {'rule_type': 'content_filter', 'severity': 'moderate'};

      // Save to database
      final newRule = await _customRulesService.saveRule(
        childProfileId: selectedProfile.id,
        ruleText: ruleText,
        parsedRule: parsedRule,
      );

      setState(() {
        rules.insert(0, newRule);
        _ruleController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _aiAvailable
                  ? 'Rule parsed and saved! (${parsedRule['rule_type']})'
                  : 'Rule saved as simple text',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().contains('API key')
            ? 'Check your Gemini API key in ai_parser_service.dart'
            : e.toString().contains('Rate limit')
            ? 'Too many requests. Wait a minute or disable AI parsing.'
            : 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeRule(int index) async {
    final rule = rules[index];

    setState(() {
      rules.removeAt(index);
    });

    try {
      await _customRulesService.deleteRule(rule.id);
    } catch (e) {
      // Re-add on error
      setState(() {
        rules.insert(index, rule);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete rule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveCustomRules() async {
    // Rules are already saved to database individually
    // Just navigate to home
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final selectedProfile = profileProvider.selectedProfile;
        final profileName = selectedProfile?.name ?? 'Guest';

        return Scaffold(
          backgroundColor: AppColors.beige,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Avatar
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.veryLightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.child_care,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Name
                  Text(
                    profileName,
                    style: AppTextStyles.heading2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  // Title
                  Text(
                    'Enter Some Custom Rules',
                    style: AppTextStyles.heading3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Rules List
                  ...rules.asMap().entries.map((entry) {
                    final rule = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.veryLightBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rule.ruleText,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getRuleTypeColor(
                                            rule.ruleType,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          rule.ruleType
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      if (rule.severity != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          rule.severity!,
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textGray,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
                              onPressed: () => _removeRule(entry.key),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  // Input Field
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.veryLightBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _ruleController,
                          maxLines: 3,
                          minLines: 3,
                          style: AppTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Type your custom rule here...',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textGray.withOpacity(0.6),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Add Rule Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addRule,
                            icon: const Icon(Icons.add, size: 20),
                            label: Text(
                              'Add Rule',
                              style: AppTextStyles.buttonSmall,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Continue Button
                  CustomButton(text: 'Continue', onPressed: _saveCustomRules),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getRuleTypeColor(String ruleType) {
    switch (ruleType) {
      case 'channel_block':
        return Colors.red;
      case 'time_limit':
        return Colors.orange;
      case 'content_filter':
        return Colors.purple;
      case 'goal_based':
        return Colors.green;
      case 'category_control':
        return Colors.blue;
      case 'mixed':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }
}
