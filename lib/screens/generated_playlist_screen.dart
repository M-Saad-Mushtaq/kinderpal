import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';

class GeneratedPlaylistScreen extends StatefulWidget {
  const GeneratedPlaylistScreen({super.key});

  @override
  State<GeneratedPlaylistScreen> createState() =>
      _GeneratedPlaylistScreenState();
}

class _GeneratedPlaylistScreenState extends State<GeneratedPlaylistScreen> {
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

  final List<Map<String, dynamic>> videos = [
    {
      'title': 'Pakkay Dost',
      'duration': '5 min 20 sec',
      'tag': 'Urdu Poems',
      'hasEpisode': true,
      'hasBadge': true,
    },
    {
      'title': 'Urdu Science Video',
      'duration': '5 min 20 sec',
      'tag': 'Safe Content',
      'hasEpisode': false,
      'hasBadge': false,
    },
  ];

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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Text(
                    'Generated ',
                    style: AppTextStyles.heading2,
                  ),
                  Icon(
                    Icons.movie,
                    size: 32,
                    color: AppColors.textDark,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Curated videos approved by parents',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 30),
              // Videos List
              ...videos.map((video) => Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: _buildVideoCard(video),
                  )),
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

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: video['hasBadge'] ? AppColors.yellow : AppColors.transparent,
          width: 4,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.veryLightBlue,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (video['hasEpisode'])
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'EPISODE 3',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (video['hasBadge'])
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['title'],
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video['duration'],
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        video['tag'],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
