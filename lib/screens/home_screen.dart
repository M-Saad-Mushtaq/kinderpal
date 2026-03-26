import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/glass_container.dart';
import '../providers/profile_provider.dart';
import '../services/youtube_service.dart';
import '../models/youtube_video.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  final YouTubeService _youtubeService = YouTubeService();
  final TextEditingController _searchController = TextEditingController();
  List<YouTubeVideo> _videos = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);

    try {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final selectedProfile = profileProvider.selectedProfile;

      if (selectedProfile != null) {
        final videos = await _youtubeService.getHomeFeedVideos(
          preferences: selectedProfile.preferences,
          childAge: selectedProfile.age,
          maxResults: 30,
          childProfileId:
              selectedProfile.id, // Pass profile ID for rule enforcement
          customRules: selectedProfile.customRules, // legacy text-rule sync
        );

        final taggedCount =
            videos
                .where(
                  (v) =>
                      v.modelCategory != null &&
                      v.modelCategory!.trim().isNotEmpty,
                )
                .length;
        print(
          '🏠 [HomeScreen] Loaded videos=${videos.length}, tagged=$taggedCount',
        );

        setState(() {
          _videos = videos; // Videos already filtered by custom rules
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading videos: $e')));
      }
    }
  }

  Future<void> _searchVideos(String query) async {
    if (query.trim().isEmpty) {
      _loadVideos();
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final selectedProfile = profileProvider.selectedProfile;

      final videos = await _youtubeService.searchVideos(
        query: query,
        maxResults: 20,
      );

      // Apply all rules (structured AI-parsed + legacy text array) to search
      final filteredVideos = selectedProfile != null
          ? await _youtubeService.applyAllRules(
              videos: videos,
              childProfileId: selectedProfile.id,
              legacyCustomRules: selectedProfile.customRules,
            )
          : videos;

      final classifiedVideos = await _youtubeService.classifyVideos(
        filteredVideos,
        childProfileId: selectedProfile?.id,
        childAge: selectedProfile?.age,
      );

      final taggedCount =
          classifiedVideos
              .where(
                (v) =>
                    v.modelCategory != null &&
                    v.modelCategory!.trim().isNotEmpty,
              )
              .length;
      print(
        '🔎 [HomeScreen search] classified=${classifiedVideos.length}, tagged=$taggedCount',
      );

      setState(() {
        _videos = classifiedVideos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
      }
    }
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.of(context).pushNamed('/playlist-prompt');
    } else if (index == 2) {
      Navigator.of(context).pushNamed('/profile');
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final selectedProfile = profileProvider.selectedProfile;
        final profileName = selectedProfile?.name ?? 'Guest';
        final showSearchBar =
            selectedProfile != null && selectedProfile.age >= 15;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadVideos,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(20),
                          borderRadius: 20,
                          blur: 15,
                          opacity: 0.2,
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.child_care,
                                  color: AppColors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Hi $profileName ',
                                          style: AppTextStyles.heading3
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const Text(
                                          '👋',
                                          style: TextStyle(fontSize: 24),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      selectedProfile != null
                                          ? 'Age ${selectedProfile.age}'
                                          : 'Kid Avatar',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textLight,
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

                    // Search Bar (only for age 15+)
                    if (showSearchBar)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Container(
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
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: _searchVideos,
                              decoration: InputDecoration(
                                hintText: 'Search videos...',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textGray,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: AppColors.primary,
                                ),
                                suffixIcon: _isSearching
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          color: AppColors.textGray,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _isSearching = false);
                                          _loadVideos();
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (showSearchBar)
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // Loading indicator
                    if (_isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_videos.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No videos found',
                            style: AppTextStyles.bodyLarge,
                          ),
                        ),
                      )
                    else
                      // Video Grid
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final video = _videos[index];
                            return _buildVideoCard(video);
                          }, childCount: _videos.length),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
          ),
        );
      },
    );
  }

  Widget _buildVideoCard(YouTubeVideo video) {
    final tagLabel =
        (video.modelCategory != null && video.modelCategory!.trim().isNotEmpty)
        ? video.modelCategory!.trim()
        : 'temp';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(video: video),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 120,
                      color: AppColors.veryLightBlue,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 120,
                      color: AppColors.veryLightBlue,
                      child: Icon(Icons.error, color: AppColors.textGray),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _categoryColor(tagLabel),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tagLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // Duration badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Video info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      video.channelTitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    final normalized = category.trim().toLowerCase();

    switch (normalized) {
      case 'temp':
        return AppColors.textGray;
      case 'education':
        return AppColors.primary;
      case 'music':
        return AppColors.cyan;
      case 'sports':
        return AppColors.green;
      case 'entertainment':
        return AppColors.pink;
      case 'science':
        return AppColors.blue;
      case 'news':
        return AppColors.peach;
      case 'politics':
        return AppColors.red;
      case 'vlogging':
      case 'general/other':
        return AppColors.lightPurple;
      case 'gaming':
        return AppColors.yellow;
      case 'technology':
      case 'tech':
        return AppColors.cyan;
      default:
        final palette = <Color>[
          AppColors.primary,
          AppColors.cyan,
          AppColors.green,
          AppColors.pink,
          AppColors.blue,
          AppColors.peach,
          AppColors.red,
          AppColors.lightPurple,
          AppColors.yellow,
        ];
        final hash = normalized.codeUnits.fold<int>(
          0,
          (sum, unit) => sum + unit,
        );
        return palette[hash % palette.length];
    }
  }
}
