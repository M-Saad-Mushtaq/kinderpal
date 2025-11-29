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

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final YouTubeService _youtubeService = YouTubeService();
  final TextEditingController _searchController = TextEditingController();
  List<YouTubeVideo> _videos = [];
  bool _isLoading = true;
  bool _isSearching = false;

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
        );

        // Apply custom rules filtering
        final filteredVideos = _youtubeService.filterVideosByRules(
          videos: videos,
          customRules: selectedProfile.customRules,
        );

        setState(() {
          _videos = filteredVideos;
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

      // Apply custom rules filtering
      final filteredVideos = selectedProfile != null
          ? _youtubeService.filterVideosByRules(
              videos: videos,
              customRules: selectedProfile.customRules,
            )
          : videos;

      setState(() {
        _videos = filteredVideos;
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
      Navigator.of(context).pushReplacementNamed('/playlist-prompt');
    } else if (index == 2) {
      Navigator.of(context).pushReplacementNamed('/profile');
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
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
}
