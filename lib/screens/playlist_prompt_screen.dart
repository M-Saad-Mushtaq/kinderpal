import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/custom_button.dart';
import '../services/youtube_service.dart';
import '../providers/profile_provider.dart';

class PlaylistPromptScreen extends StatefulWidget {
  const PlaylistPromptScreen({super.key});

  @override
  State<PlaylistPromptScreen> createState() => _PlaylistPromptScreenState();
}

class _PlaylistPromptScreenState extends State<PlaylistPromptScreen> {
  final _promptController = TextEditingController();
  int _currentIndex = 1;
  final YouTubeService _youtubeService = YouTubeService();

  void _onNavTap(int index) {
    if (index == 0) {
      // Pop back to home screen
      Navigator.of(
        context,
      ).popUntil((route) => route.settings.name == '/home' || route.isFirst);
    } else if (index == 2) {
      Navigator.of(context).pushNamed('/profile');
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<void> _generatePlaylist() async {
    final prompt = _promptController.text.trim();

    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a prompt'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final selectedProfile = profileProvider.selectedProfile;

      // Search YouTube with the prompt
      final videos = await _youtubeService.searchVideos(
        query: prompt,
        maxResults: 20,
      );

      // Apply custom rules filtering if profile exists
      final filteredVideos = selectedProfile != null
          ? _youtubeService.filterVideosByRules(
              videos: videos,
              customRules: selectedProfile.customRules,
            )
          : videos;

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to generated playlist with videos
      Navigator.pushNamed(
        context,
        '/generated-playlist',
        arguments: {'videos': filteredVideos, 'playlistName': prompt},
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating playlist: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
              const SizedBox(height: 20),
              Text(
                'Describe what kind of videos you want to see',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Sample Prompts
              Text(
                'Sample Prompts:',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildSamplePrompt('Science experiments for kids'),
              const SizedBox(height: 12),
              _buildSamplePrompt('Art and crafts tutorials'),
              const SizedBox(height: 12),
              _buildSamplePrompt('Educational songs and rhymes'),
              const SizedBox(height: 40),
              // Input Field
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your Prompt:',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _promptController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Type your playlist request here...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textGray,
                        ),
                        filled: true,
                        fillColor: AppColors.veryLightBlue,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Generate Playlist',
                      icon: Icons.playlist_play,
                      onPressed: _generatePlaylist,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
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

  Widget _buildSamplePrompt(String text) {
    return GestureDetector(
      onTap: () {
        _promptController.text = text;
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.veryLightBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
