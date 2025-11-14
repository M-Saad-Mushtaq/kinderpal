import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> categories = [
    {'name': 'Art', 'color': AppColors.yellow, 'icon': Icons.palette},
    {'name': 'Music', 'color': AppColors.primary, 'icon': Icons.music_note},
    {'name': 'Science', 'color': AppColors.green, 'icon': Icons.science},
    {'name': 'Sports', 'color': AppColors.red, 'icon': Icons.sports_soccer},
  ];

  final List<Map<String, dynamic>> videos = [
    {'title': 'Vocab Video 1', 'duration': '02:15', 'thumbnail': 'vocab'},
    {'title': 'Science Video 1', 'duration': '03:45', 'thumbnail': 'science'},
    {'title': 'Music Video 1', 'duration': '01:30', 'thumbnail': 'music'},
    {'title': 'Science Video 1', 'duration': '04:10', 'thumbnail': 'science2'},
    {'title': 'Sport Video 2', 'duration': '02:30', 'thumbnail': 'sport'},
    {'title': 'Science Video 2', 'duration': '03:00', 'thumbnail': 'science3'},
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      // Navigate to Playlist
      Navigator.pushNamed(context, '/playlist-prompt');
    } else if (index == 2) {
      // Navigate to Profile
      Navigator.pushNamed(context, '/profile');
    }
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
              // Header
              Row(
                children: [
                  Text('Hi Zara ', style: AppTextStyles.heading2),
                  Text('👋', style: TextStyle(fontSize: 28)),
                ],
              ),
              const SizedBox(height: 20),
              // Child Avatar
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.veryLightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.child_care,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zara',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text('Kid Avatar', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Categories
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: categories.map((category) {
                  return Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: category['color'],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category['icon'],
                          color: AppColors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'],
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              // Videos Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.veryLightBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        video['title'],
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(video['duration'], style: AppTextStyles.bodySmall),
                    ],
                  );
                },
              ),
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
