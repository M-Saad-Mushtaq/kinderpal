import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';

class GuardianDashboardScreen extends StatelessWidget {
  const GuardianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Title
              Text(
                'Guardian\nDashboard',
                style: AppTextStyles.heading1.copyWith(fontSize: 36),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Total Screen Time Card
              Container(
                width: double.infinity,
                height: 150,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.veryLightBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 40, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text(
                      'Total Screen Time',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('1hr 30min', style: AppTextStyles.heading3),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Last Watched Card
              Container(
                width: double.infinity,
                height: 150,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.veryLightBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library,
                      color: AppColors.primary,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last Watched',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Education', style: AppTextStyles.bodyLarge),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Alerts Card
              Container(
                width: double.infinity,
                height: 150,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.veryLightBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning, size: 50, color: AppColors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Alerts',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Download Report Button
              CustomButton(
                text: 'Download Report',
                onPressed: () {
                  // Handle download report
                },
              ),
              const SizedBox(height: 16),
              // Switch Profile Button
              CustomButton(
                text: 'Switch Child Profile',
                icon: Icons.switch_account,
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/profile-selection');
                },
                useGradient: false,
                backgroundColor: AppColors.veryLightBlue,
                textColor: AppColors.primary,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
