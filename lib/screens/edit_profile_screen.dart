import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'Zara');
  final _screenTimeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _screenTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text('Edit Profile Info', style: AppTextStyles.heading2),
              const SizedBox(height: 10),
              Text(
                "Update Zara's details below.",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 30),
              // Avatar
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.veryLightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.child_care,
                      size: 30,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Zara's Avatar (Add Photo)",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Name Field
              CustomTextField(
                hintText: "Enter Zara's Name",
                controller: _nameController,
              ),
              const SizedBox(height: 16),
              // Screen Time Field
              CustomTextField(
                hintText: 'Screen Time',
                controller: _screenTimeController,
              ),
              const SizedBox(height: 40),
              // Save Button
              CustomButton(
                text: 'Save Changes',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              // Cancel Button
              CustomButton(
                text: 'Cancel',
                onPressed: () {
                  Navigator.pop(context);
                },
                backgroundColor: AppColors.white,
                textColor: AppColors.textDark,
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
