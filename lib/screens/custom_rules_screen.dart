import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';
import '../widgets/rule_chip.dart';

class CustomRulesScreen extends StatefulWidget {
  const CustomRulesScreen({super.key});

  @override
  State<CustomRulesScreen> createState() => _CustomRulesScreenState();
}

class _CustomRulesScreenState extends State<CustomRulesScreen> {
  final _ruleController = TextEditingController();
  final List<String> rules = ['No Toys Videos', 'No Children Vlogs'];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Padding(
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
                'Zara',
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.veryLightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                constraints: const BoxConstraints(minHeight: 120),
                child: TextField(
                  controller: _ruleController,
                  maxLines: 3,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Type ...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGray.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _addRule(),
                ),
              ),
              const Spacer(),
              // Continue Button
              CustomButton(
                text: 'Continue',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
