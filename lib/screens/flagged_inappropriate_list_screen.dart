import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/profile_provider.dart';
import '../services/flagged_inappropriate_service.dart';
import '../models/flagged_inappropriate_video.dart';
import 'flagged_inappropriate_detail_screen.dart';

class FlaggedInappropriateListScreen extends StatefulWidget {
  const FlaggedInappropriateListScreen({super.key});

  @override
  State<FlaggedInappropriateListScreen> createState() =>
      _FlaggedInappropriateListScreenState();
}

class _FlaggedInappropriateListScreenState
    extends State<FlaggedInappropriateListScreen> {
  final FlaggedInappropriateService _service = FlaggedInappropriateService();
  bool _isLoading = true;
  List<FlaggedInappropriateVideo> _items = [];

  @override
  void initState() {
    super.initState();
    _loadFlaggedVideos();
  }

  Future<void> _loadFlaggedVideos() async {
    final profile = Provider.of<ProfileProvider>(context, listen: false)
        .selectedProfile;

    if (profile == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _items = [];
        });
      }
      return;
    }

    try {
      final videos = await _service.getFlaggedVideos(profile.id);
      if (mounted) {
        setState(() {
          _items = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load flagged videos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: Text('Flagged Inappropriate', style: AppTextStyles.heading3),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textDark),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadFlaggedVideos();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(
                    'No flagged inappropriate videos yet.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textGray,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FlaggedInappropriateDetailScreen(item: item),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.red.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.report_gmailerrorred,
                                color: AppColors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.videoTitle ?? 'Untitled video',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Model: ${item.modelLabel ?? 'flagged_inappropriate'}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                  Text(
                                    'Gemini: ${item.geminiIsInappropriate == null ? 'pending' : (item.geminiIsInappropriate! ? 'inappropriate' : 'not inappropriate')}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.textGray,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
