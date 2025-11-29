import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';
import '../widgets/rule_chip.dart';
import '../providers/profile_provider.dart';

class CustomRulesScreen extends StatefulWidget {
  const CustomRulesScreen({super.key});

  @override
  State<CustomRulesScreen> createState() => _CustomRulesScreenState();
}

class _CustomRulesScreenState extends State<CustomRulesScreen> {
  final _ruleController = TextEditingController();
  final List<String> rules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load existing custom rules
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final selectedProfile = profileProvider.selectedProfile;
      if (selectedProfile != null && selectedProfile.customRules.isNotEmpty) {
        setState(() {
          rules.addAll(selectedProfile.customRules);
        });
      } else {
        // Add default rules if no custom rules exist
        setState(() {
          rules.addAll(['No Toys Videos', 'No Children Vlogs']);
        });
      }
    });
  }

  @override
  void dispose() {
    _ruleController.dispose();
    super.dispose();
  }

  void _addRule() {
    if (_ruleController.text.isNotEmpty) {
      setState(() {
        rules.add(_ruleController.text);
        _ruleController.clear();
      });
    }
  }

  void _removeRule(int index) {
    setState(() {
      rules.removeAt(index);
    });
  }

  Future<void> _saveCustomRules() async {
    setState(() => _isLoading = true);

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedProfile = profileProvider.selectedProfile;

    if (selectedProfile != null) {
      final success = await profileProvider.updateProfile(
        profileId: selectedProfile.id,
        name: selectedProfile.name,
        age: selectedProfile.age,
        customRules: rules,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              profileProvider.errorMessage ?? 'Failed to save custom rules',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/home');
    }
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: RuleChip(
                        text: entry.value,
                        onDelete: () => _removeRule(entry.key),
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
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                          text: 'Continue',
                          onPressed: _saveCustomRules,
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
