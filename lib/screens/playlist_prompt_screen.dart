import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';

class PlaylistPromptScreen extends StatefulWidget {
  const PlaylistPromptScreen({super.key});

  @override
  State<PlaylistPromptScreen> createState() => _PlaylistPromptScreenState();
}

class _PlaylistPromptScreenState extends State<PlaylistPromptScreen> {
  final _promptController = TextEditingController();
  int _currentIndex = 1;

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Title
              Text(
                'Generate a Playlist',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Sample Prompt
              Text(
                'Sample Prompt:',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'میرے بچے کی عمر ابھی ایک سال سے کم ہے اور وہ مجھے اردو نظم، اس کا نام سے کرتون اور ایک سائنس کی ویڈیو بو',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 40),
              // Input Field
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.veryLightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _promptController,
                  maxLines: 1,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Enter a promt to generate a playlist',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGray.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send, color: AppColors.primary),
                      onPressed: () {
                        if (_promptController.text.isNotEmpty) {
                          Navigator.pushNamed(context, '/generated-playlist');
                        }
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      Navigator.pushNamed(context, '/generated-playlist');
                    }
                  },
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
