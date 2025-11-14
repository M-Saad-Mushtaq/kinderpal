import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Avatar
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.veryLightBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.child_care,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // App Name
              Text('Kinder Pal', style: AppTextStyles.heading1),
              const SizedBox(height: 10),
              Text(
                'Safe and Smart Content',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textGray,
                ),
              ),
              const Spacer(),
              // Get Started Button
              CustomButton(
                text: 'Get Started',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
