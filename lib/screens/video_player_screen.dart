import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/youtube_video.dart';
import '../providers/profile_provider.dart';
import '../services/viewing_history_service.dart';
import '../services/custom_rules_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final YouTubeVideo video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  final ViewingHistoryService _historyService = ViewingHistoryService();
  final CustomRulesService _customRulesService = CustomRulesService();
  int _watchDuration = 0;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _checkTimeConstraints(); // Check before allowing playback

    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        captionLanguage: 'en',
      ),
    );

    // Track watch duration and save continuously
    _controller.addListener(_trackWatchDuration);
  }

  /// Check if video playback is allowed based on time constraints
  Future<void> _checkTimeConstraints() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedProfile = profileProvider.selectedProfile;

    if (selectedProfile != null) {
      // Get today's total screen time in minutes
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final todayScreenTime = await _historyService.getTotalScreenTime(
        childProfileId: selectedProfile.id,
        startDate: startOfDay,
        endDate: now,
      );
      final screenTimeMinutes = (todayScreenTime / 60).round();

      // Check if playback is allowed
      final canPlay = await _customRulesService.canPlayVideo(
        childProfileId: selectedProfile.id,
        currentScreenTime: screenTimeMinutes,
      );

      if (!canPlay && mounted) {
        // Show dialog and close player
        Navigator.pop(context);
        Future.microtask(() {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('⏰ Screen Time Limit Reached'),
              content: Text(
                'You\'ve reached your daily screen time limit of $screenTimeMinutes minutes.\n\nTake a break and come back later!',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
      }
    }
  }

  void _trackWatchDuration() {
    if (_controller.value.isPlaying) {
      final currentSeconds = _controller.value.position.inSeconds;

      // Only update if seconds changed
      if (currentSeconds != _watchDuration) {
        _watchDuration = currentSeconds;

        // Save to database every second
        _saveWatchProgress();
      }
    }
  }

  void _saveWatchProgress() {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedProfile = profileProvider.selectedProfile;

    if (selectedProfile != null && _watchDuration > 0) {
      // Fire and forget - don't await to avoid blocking playback
      _historyService
          .upsertViewingHistory(
            childProfileId: selectedProfile.id,
            videoId: widget.video.id,
            videoTitle: widget.video.title,
            durationWatched: _watchDuration,
          )
          .catchError((e) {
            debugPrint('Error saving watch progress: $e');
          });
    }
  }

  @override
  void dispose() {
    // Get final watch position before disposing controller
    if (_controller.value.isReady) {
      final finalPosition = _controller.value.position.inSeconds;
      if (finalPosition > _watchDuration) {
        _watchDuration = finalPosition;
        // Save final position one last time
        _saveWatchProgress();
      }
    }

    debugPrint('DISPOSE: Final watch duration = $_watchDuration seconds');

    _controller.dispose();

    // Reset orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        progressColors: ProgressBarColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
        ),
        onReady: () {
          debugPrint('Player is ready');
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppColors.beige,
          appBar: _isFullScreen
              ? null
              : AppBar(
                  backgroundColor: AppColors.white,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.textDark),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Now Playing',
                          style: AppTextStyles.heading3,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),
          body: _isFullScreen
              ? Center(child: player)
              : Column(
                  children: [
                    // Video Player
                    player,

                    // Video Info
                    Expanded(
                      child: Container(
                        color: AppColors.white,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title Section with border
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.beige,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  widget.video.title,
                                  style: AppTextStyles.heading3.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Channel info with background
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.veryLightBlue,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primaryLight.withOpacity(
                                      0.2,
                                    ),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: AppColors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.video.channelTitle,
                                            style: AppTextStyles.bodyLarge
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 14,
                                                color: AppColors.textGray,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                widget.video.publishedAt
                                                    .toString()
                                                    .split(' ')[0],
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color: AppColors.textGray,
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
                              const SizedBox(height: 16),

                              // Description with distinct styling
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.veryLightBlue,
                                      AppColors.beige,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.pink.withOpacity(0.3),
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
                                          Icons.description,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Description',
                                          style: AppTextStyles.bodyLarge
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.white.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.video.description.isNotEmpty
                                            ? widget.video.description
                                            : 'No description available',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              color: AppColors.textDark,
                                              height: 1.5,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
