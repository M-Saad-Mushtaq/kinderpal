import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';
import '../providers/profile_provider.dart';
import '../services/viewing_history_service.dart';
import '../services/api_service.dart';
import '../services/flagged_inappropriate_service.dart';
import '../models/youtube_video.dart';
import 'video_player_screen.dart';
import 'ecochamber_analysis_result_screen.dart';
import 'flagged_inappropriate_list_screen.dart';

class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({super.key});

  @override
  State<GuardianDashboardScreen> createState() =>
      _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState extends State<GuardianDashboardScreen> {
  final ViewingHistoryService _historyService = ViewingHistoryService();
  final ApiService _apiService = ApiService();
  final FlaggedInappropriateService _flaggedService =
      FlaggedInappropriateService();
  bool _isLoading = true;
  String _totalScreenTime = '0min';
  List<Map<String, dynamic>> _watchHistory = [];
  int _flaggedInappropriateCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this screen
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedProfile = profileProvider.selectedProfile;

    if (selectedProfile != null) {
      try {
        // Get total screen time
        final totalSeconds = await _historyService.getTotalScreenTime(
          childProfileId: selectedProfile.id,
        );

        // Convert to hours, minutes, and seconds
        final hours = totalSeconds ~/ 3600;
        final minutes = (totalSeconds % 3600) ~/ 60;
        final seconds = totalSeconds % 60;

        // Format as hour:minutes:seconds
        String timeStr =
            '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        // Get watch history
        final history = await _historyService.getViewingHistory(
          childProfileId: selectedProfile.id,
          limit: 10,
        );

        final flaggedCount = await _flaggedService.getFlaggedVideosCount(
          selectedProfile.id,
        );

        setState(() {
          _totalScreenTime = timeStr;
          _watchHistory = history;
          _flaggedInappropriateCount = flaggedCount;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading dashboard data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
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
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  Future<void> _analyzeEcochamberFromHistory() async {
    if (_watchHistory.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No watch history available for analysis.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final urls = _watchHistory
        .map((item) => item['video_id']?.toString().trim() ?? '')
        .where((id) => id.isNotEmpty)
        .map((id) => 'https://www.youtube.com/watch?v=$id')
        .toSet()
        .toList();

    if (urls.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid video URLs found in history.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await _apiService.analyzeEcoChamberHistory(urls);

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EcochamberAnalysisResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to analyze ecochamber: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textDark),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.1),
                              AppColors.veryLightBlue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 40,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total Screen Time',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _totalScreenTime,
                              style: AppTextStyles.heading2.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Last Watched Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryLight.withOpacity(0.3),
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
                                  Icons.video_library,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Last Watched',
                                    style: AppTextStyles.heading3.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _watchHistory.isEmpty
                                  ? 'No videos watched yet'
                                  : 'View watch history for this profile',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: _watchHistory.isEmpty
                                  ? 'No History'
                                  : 'View Watch History (${_watchHistory.length})',
                              icon: Icons.history,
                              onPressed: _watchHistory.isEmpty
                                  ? null
                                  : () {
                                      _showFullHistory();
                                    },
                              useGradient: false,
                              backgroundColor: AppColors.primary,
                              textColor: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.red.withOpacity(0.12),
                              AppColors.white,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.red.withOpacity(0.3),
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
                                  Icons.report_gmailerrorred,
                                  color: AppColors.red,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Flagged Inappropriate',
                                    style: AppTextStyles.heading3.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _flaggedInappropriateCount == 0
                                  ? 'No flagged videos yet'
                                  : '$_flaggedInappropriateCount videos flagged by model',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: _flaggedInappropriateCount == 0
                                  ? 'No Flagged Videos'
                                  : 'View Flagged Videos ($_flaggedInappropriateCount)',
                              icon: Icons.warning_amber_rounded,
                              onPressed: _flaggedInappropriateCount == 0
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const FlaggedInappropriateListScreen(),
                                        ),
                                      );
                                    },
                              useGradient: false,
                              backgroundColor: AppColors.red,
                              textColor: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.green.withOpacity(0.12),
                              AppColors.white,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.green.withOpacity(0.3),
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
                                  Icons.analytics_outlined,
                                  color: AppColors.green,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Ecochamber',
                                    style: AppTextStyles.heading3.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _watchHistory.isEmpty
                                  ? 'Watch history required to run analysis'
                                  : 'Analyze the same watch history shown above',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: _watchHistory.isEmpty
                                  ? 'No History'
                                  : 'Analyze Ecochamber (${_watchHistory.length})',
                              icon: Icons.bubble_chart,
                              onPressed: _watchHistory.isEmpty
                                  ? null
                                  : _analyzeEcochamberFromHistory,
                              useGradient: false,
                              backgroundColor: AppColors.green,
                              textColor: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // YouTube Watch History Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.red.withOpacity(0.1),
                              AppColors.white,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.red.withOpacity(0.3),
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
                                  Icons.youtube_searched_for,
                                  color: AppColors.red,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'YouTube Watch History',
                                    style: AppTextStyles.heading3.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'View watch history from your YouTube account',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textGray,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'View YouTube History',
                              icon: Icons.open_in_new,
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/youtube-history',
                                );
                              },
                              useGradient: false,
                              backgroundColor: AppColors.red,
                              textColor: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Action Buttons
                      CustomButton(
                        text: 'Switch Child Profile',
                        icon: Icons.switch_account,
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/profile-selection',
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildWatchHistoryItem(Map<String, dynamic> item) {
    return InkWell(
      onTap: () {
        // Navigate to video player with the video data
        final videoId = item['video_id'];
        final videoTitle = item['video_title'] ?? 'Unknown Video';

        if (videoId != null && videoId.isNotEmpty) {
          // Create a minimal YouTubeVideo object from history data
          final video = YouTubeVideo(
            id: videoId,
            title: videoTitle,
            description: '',
            thumbnailUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
            channelTitle: '',
            channelId: '',
            publishedAt: DateTime.now(),
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
          color: AppColors.beige,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
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
                    item['video_title'] ?? 'Unknown Video',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(item['duration_watched'] ?? 0),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textGray,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(item['watched_at'] ?? ''),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_outline, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  void _showFullHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Watch History', style: AppTextStyles.heading2),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _watchHistory.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildWatchHistoryItem(_watchHistory[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
