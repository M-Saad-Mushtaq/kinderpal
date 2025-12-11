import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/youtube_auth_service.dart';
import '../widgets/custom_button.dart';
import '../models/youtube_video.dart';
import 'video_player_screen.dart';

class YouTubeHistoryScreen extends StatefulWidget {
  const YouTubeHistoryScreen({super.key});

  @override
  State<YouTubeHistoryScreen> createState() => _YouTubeHistoryScreenState();
}

class _YouTubeHistoryScreenState extends State<YouTubeHistoryScreen> {
  final YouTubeAuthService _authService = YouTubeAuthService();
  bool _isSignedIn = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _watchHistory = [];
  Map<String, dynamic>? _channelInfo;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    setState(() {
      _isLoading = true;
    });

    final isSignedIn = await _authService.isSignedIn();

    if (isSignedIn) {
      await _loadData();
    }

    setState(() {
      _isSignedIn = isSignedIn;
      _isLoading = false;
    });
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('YouTube History: Starting sign-in process...');
      final success = await _authService.signInToYouTube();

      if (success) {
        print('YouTube History: Sign-in successful, loading data...');
        await _loadData();
        setState(() {
          _isSignedIn = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully signed in to YouTube!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('YouTube History: Sign-in failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to sign in to YouTube. Please check the debug console for details.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('YouTube History: Exception during sign-in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final history = await _authService.getWatchHistory(maxResults: 50);
      final channel = await _authService.getUserChannelInfo();

      setState(() {
        _watchHistory = history;
        _channelInfo = channel;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    setState(() {
      _isSignedIn = false;
      _watchHistory = [];
      _channelInfo = null;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('YouTube Watch History', style: AppTextStyles.heading3),
        actions: [
          if (_isSignedIn)
            IconButton(
              icon: Icon(Icons.logout, color: AppColors.red),
              onPressed: _signOut,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : !_isSignedIn
            ? _buildSignInView()
            : _buildHistoryView(),
      ),
    );
  }

  Widget _buildSignInView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.youtube_searched_for,
              size: 100,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Access YouTube Watch History',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in with your Google account to view your YouTube watch history and activity',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Sign in with Google',
              icon: Icons.login,
              onPressed: _signIn,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.veryLightBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Note:',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'YouTube API has limitations on accessing watch history. We can show your recent activity and recommendations.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Channel Info Card
            if (_channelInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.veryLightBlue,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _channelInfo!['title'] ?? 'My Channel',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_channelInfo!['subscriberCount']} subscribers',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Activity Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activity', style: AppTextStyles.heading3),
                Text(
                  '${_watchHistory.length} items',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Watch History List
            if (_watchHistory.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 64,
                        color: AppColors.textGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No activity found',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _watchHistory.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _watchHistory[index];
                  return _buildHistoryItem(item);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final videoId = item['videoId'] ?? '';

    return InkWell(
      onTap: () {
        if (videoId.isNotEmpty) {
          // Create YouTubeVideo object and navigate to video player
          final video = YouTubeVideo(
            id: videoId,
            title: item['title'] ?? 'Unknown Video',
            description: item['description'] ?? '',
            thumbnailUrl:
                item['thumbnailUrl'] ??
                'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
            channelTitle: item['channelTitle'] ?? '',
            channelId: '',
            publishedAt: item['publishedAt'] ?? DateTime.now(),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(video: video),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryLight.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail placeholder
            Container(
              width: 100,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.veryLightBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.play_circle_outline,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'Unknown Video',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['channelTitle'] ?? '',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(item['publishedAt'] ?? DateTime.now()),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_filled, color: AppColors.primary, size: 28),
          ],
        ),
      ),
    );
  }
}
