import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';
import '../services/youtube_credentials_service.dart';

class YouTubeApiSetupScreen extends StatefulWidget {
  const YouTubeApiSetupScreen({super.key});

  @override
  State<YouTubeApiSetupScreen> createState() => _YouTubeApiSetupScreenState();
}

class _YouTubeApiSetupScreenState extends State<YouTubeApiSetupScreen> {
  final _apiKeyController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  bool _showInputFields = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveCredentials() async {
    final apiKey = _apiKeyController.text.trim();
    final clientId = _clientIdController.text.trim();
    final clientSecret = _clientSecretController.text.trim();

    if (apiKey.isEmpty || clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save to secure storage
    try {
      await YouTubeCredentialsService.saveCredentials(
        apiKey: apiKey,
        clientId: clientId,
        clientSecret: clientSecret.isNotEmpty ? clientSecret : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credentials saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to create profile screen
        Navigator.pushReplacementNamed(context, '/create-profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving credentials: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _skipSetup() {
    Navigator.pushReplacementNamed(context, '/create-profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.youtube_searched_for,
                      size: 80,
                      color: AppColors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'YouTube API Setup',
                      style: AppTextStyles.heading1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enable YouTube watch history tracking',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Instructions Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'What We Need',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'To track YouTube watch history, we need you to set up a Google Cloud project and enable YouTube Data API v3.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You will need to provide:',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRequirement('YouTube Data API v3 Key'),
                    _buildRequirement('OAuth 2.0 Client ID'),
                    _buildRequirement('OAuth 2.0 Client Secret (optional)'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Setup Steps
              Text('Setup Steps:', style: AppTextStyles.heading3),
              const SizedBox(height: 16),

              _buildStep(
                number: '1',
                title: 'Go to Google Cloud Console',
                description:
                    'Open the Google Cloud Console to create a project',
                buttonText: 'Open Console',
                onTap: () => _launchURL('https://console.cloud.google.com'),
              ),
              const SizedBox(height: 12),

              _buildStep(
                number: '2',
                title: 'Create or Select a Project',
                description:
                    'Create a new project or select an existing one from the dropdown',
                isClickable: false,
              ),
              const SizedBox(height: 12),

              _buildStep(
                number: '3',
                title: 'Enable YouTube Data API v3',
                description:
                    'Go to "APIs & Services" → "Library" → Search for "YouTube Data API v3" → Click Enable',
                buttonText: 'API Library',
                onTap: () =>
                    _launchURL('https://console.cloud.google.com/apis/library'),
              ),
              const SizedBox(height: 12),

              _buildStep(
                number: '4',
                title: 'Create API Key',
                description:
                    'Go to "APIs & Services" → "Credentials" → "Create Credentials" → "API Key"',
                buttonText: 'Credentials',
                onTap: () => _launchURL(
                  'https://console.cloud.google.com/apis/credentials',
                ),
              ),
              const SizedBox(height: 12),

              _buildStep(
                number: '5',
                title: 'Create OAuth 2.0 Client ID',
                description:
                    'Create Credentials → OAuth client ID → Select "Android" or "iOS" → Follow instructions',
                isClickable: false,
              ),
              const SizedBox(height: 12),

              _buildStep(
                number: '6',
                title: 'Copy Your Credentials',
                description:
                    'Copy the API Key and OAuth 2.0 Client ID from the credentials page',
                isClickable: false,
              ),
              const SizedBox(height: 32),

              // Done Button
              if (!_showInputFields)
                Column(
                  children: [
                    CustomButton(
                      text: 'Done - Enter Credentials',
                      icon: Icons.check_circle,
                      onPressed: () {
                        setState(() {
                          _showInputFields = true;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _skipSetup,
                      child: Text(
                        'Skip for Now',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textGray,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

              // Input Fields
              if (_showInputFields) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.veryLightBlue, AppColors.beige],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Your Credentials',
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 20),
                      // API Key
                      Text(
                        'YouTube Data API v3 Key *',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _apiKeyController,
                        decoration: InputDecoration(
                          hintText: 'AIzaSy...',
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // OAuth Client ID
                      Text(
                        'OAuth 2.0 Client ID *',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _clientIdController,
                        decoration: InputDecoration(
                          hintText: '123456789-abc.apps.googleusercontent.com',
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Client Secret (Optional)
                      Text(
                        'OAuth 2.0 Client Secret (Optional)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _clientSecretController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'GOCSPX-...',
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Save & Continue',
                        icon: Icons.save,
                        onPressed: _saveCredentials,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _skipSetup,
                          child: Text(
                            'Skip for Now',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textGray,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    String? buttonText,
    VoidCallback? onTap,
    bool isClickable = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textGray,
                  ),
                ),
                if (buttonText != null && onTap != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            buttonText,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
