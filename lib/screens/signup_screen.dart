import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Navigate to YouTube API setup screen (email verification disabled)
      // Original: Navigator.pushReplacementNamed(context, '/email-verification');
      Navigator.pushReplacementNamed(context, '/youtube-api-setup');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Sign up failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Check if user already has profiles, otherwise go to create profile
      Navigator.pushReplacementNamed(context, '/create-profile');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Google sign in failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Title
                Text(
                  'Create Account',
                  style: AppTextStyles.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Name Field
                CustomTextField(
                  hintText: 'Full Name',
                  controller: _nameController,
                ),
                const SizedBox(height: 16),
                // Email Field
                CustomTextField(
                  hintText: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Password Field
                CustomTextField(
                  hintText: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 40),
                // Sign Up Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          CustomButton(
                            text: 'Sign Up',
                            icon: Icons.person_add_rounded,
                            onPressed: _handleSignUp,
                          ),
                          const SizedBox(height: 16),
                          // Google Sign-In Button
                          CustomButton(
                            text: 'Sign up with Google',
                            icon: Icons.g_mobiledata,
                            onPressed: _handleGoogleSignUp,
                            useGradient: false,
                            backgroundColor: AppColors.white,
                            textColor: AppColors.textDark,
                          ),
                        ],
                      ),
                const SizedBox(height: 24),
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        'Login',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
