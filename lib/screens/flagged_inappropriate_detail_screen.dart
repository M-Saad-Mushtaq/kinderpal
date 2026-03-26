import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/flagged_inappropriate_video.dart';
import '../models/youtube_video.dart';
import 'video_player_screen.dart';

class FlaggedInappropriateDetailScreen extends StatelessWidget {
  final FlaggedInappropriateVideo item;

  const FlaggedInappropriateDetailScreen({
    super.key,
    required this.item,
  });

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
        title: Text('Flagged Video Detail', style: AppTextStyles.heading3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.videoTitle ?? 'Untitled video',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Video ID: ${item.videoId}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                  if ((item.videoUrl ?? '').isNotEmpty)
                    Text(
                      item.videoUrl!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Model Result', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Text('Label: ${item.modelLabel ?? 'flagged_inappropriate'}'),
                  Text('Reason: ${item.modelReason ?? '-'}'),
                  Text('Status: ${item.status}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transcript', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Text('Available: ${item.transcriptAvailable ? 'yes' : 'no'}'),
                  const SizedBox(height: 6),
                  Text(
                    (item.transcript ?? '').isEmpty
                        ? 'No transcript available.'
                        : item.transcript!,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gemini Second Opinion', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Text('Reviewed for age: ${item.reviewedForAge ?? '-'}'),
                  Text(
                    'Is inappropriate: ${item.geminiIsInappropriate == null ? 'pending' : (item.geminiIsInappropriate! ? 'yes' : 'no')}',
                  ),
                  Text(
                    'Confidence: ${item.geminiConfidence?.toStringAsFixed(2) ?? '-'}',
                  ),
                  Text('Reason: ${item.geminiReason ?? '-'}'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final video = YouTubeVideo(
                    id: item.videoId,
                    title: item.videoTitle ?? 'Flagged Video',
                    description: item.transcript ?? '',
                    thumbnailUrl:
                        'https://img.youtube.com/vi/${item.videoId}/hqdefault.jpg',
                    channelTitle: 'Flagged Content',
                    channelId: '',
                    publishedAt: DateTime.now(),
                    modelCategory: item.modelLabel,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(video: video),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play Video'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
      ),
      child: child,
    );
  }
}
