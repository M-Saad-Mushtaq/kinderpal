import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_container.dart';
import '../providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isChecking = false;

  Future<void> _checkEmailVerification() async {
    setState(() => _isChecking = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Reload user session to check email verification status
    final isVerified = await authProvider.checkEmailVerification();

    if (!mounted) return;

    setState(() => _isChecking = false);

    if (isVerified) {
      // Email is verified, navigate to create profile
      Navigator.pushReplacementNamed(context, '/create-profile');
    } else {
      // Show message that email is not verified yet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not verified yet. Please check your inbox.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isChecking = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resendVerificationEmail();

    if (!mounted) return;

    setState(() => _isChecking = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Verification email sent! Please check your inbox.'
              : 'Failed to send email. Please try again.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

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
              // Email Icon
              GlassContainer(
                width: 120,
                height: 120,
                child: Icon(
                  Icons.email_rounded,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 40),
              // Title
              Text(
                'Verify Your Email',
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                'We\'ve sent a verification link to your email address. Please check your inbox and click the link to verify your account.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Don\'t forget to check your spam folder!',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textGray,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              // Check Verification Button
              _isChecking
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        CustomButton(
                          text: 'I\'ve Verified My Email',
                          icon: Icons.check_circle_rounded,
                          onPressed: _checkEmailVerification,
                        ),
                        const SizedBox(height: 16),
                        // Resend Email Button
                        TextButton(
                          onPressed: _resendVerificationEmail,
                          child: Text(
                            'Resend Verification Email',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 40),
              // Back to Login
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(
                  'Back to Login',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textGray,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
