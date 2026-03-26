import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';
import '../config/env_config.dart';
import 'custom_rules_service.dart';
import 'api_service.dart';
import 'flagged_inappropriate_service.dart';

class YouTubeService {
  static const String _apiKey = EnvConfig.youtubeApiKey;
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  final ApiService _apiService = ApiService();
  final FlaggedInappropriateService _flaggedService =
      FlaggedInappropriateService();

  // Search videos with safe search enabled
  Future<List<YouTubeVideo>> searchVideos({
    required String query,
    int maxResults = 20,
    String? regionCode = 'US',
  }) async {
    try {
      final normalizedQuery = query.trim();
      if (normalizedQuery.isEmpty) {
        return [];
      }

      if (_apiKey.isEmpty) {
        throw Exception('YOUTUBE_API_KEY is missing. Set it via --dart-define.');
      }

      final effectiveRegion = regionCode ?? 'US';
      final strategies = _buildSearchStrategies(
        query: normalizedQuery,
        maxResults: maxResults,
      );

      print('🔍 Searching YouTube for "$normalizedQuery" with ${strategies.length} strategies');

      final futures = strategies
          .map(
            (strategy) => _searchVideoIds(
              query: strategy.query,
              maxResults: strategy.maxResults,
              regionCode: effectiveRegion,
              order: strategy.order,
              videoCategoryId: strategy.videoCategoryId,
            ),
          )
          .toList();

      final batches = await Future.wait(futures);

      final mergedIds = <String>[];
      final seen = <String>{};
      for (final batch in batches) {
        for (final id in batch) {
          if (seen.add(id)) {
            mergedIds.add(id);
          }
        }
      }

      if (mergedIds.isEmpty) {
        return [];
      }

      final detailsIds = mergedIds.take(50).toList();
      final detailedVideos = await _fetchVideoDetails(detailsIds);

      if (detailedVideos.isEmpty) {
        return [];
      }

      final diversified = _diversifyByChannel(
        detailedVideos,
        targetCount: maxResults,
      );

      return diversified;
    } catch (e) {
      throw Exception('Error searching videos: $e');
    }
  }

  List<_SearchStrategy> _buildSearchStrategies({
    required String query,
    required int maxResults,
  }) {
    final lower = query.toLowerCase();
    final hasKidsIntent =
        lower.contains('kid') ||
        lower.contains('child') ||
        lower.contains('children') ||
        lower.contains('toddler');

    final strategyCount = maxResults <= 8 ? 2 : 3;
    final perStrategy = ((maxResults / strategyCount).ceil() + 3).clamp(5, 12);

    final strategies = <_SearchStrategy>[
      _SearchStrategy(
        query: query,
        order: 'relevance',
        videoCategoryId: '27',
        maxResults: perStrategy,
      ),
      _SearchStrategy(
        query: hasKidsIntent ? query : '$query for kids',
        order: 'viewCount',
        maxResults: perStrategy,
      ),
    ];

    if (strategyCount == 3) {
      strategies.add(
        _SearchStrategy(
          query: hasKidsIntent ? '$query learning' : '$query educational',
          order: 'date',
          maxResults: perStrategy,
        ),
      );
    }

    return strategies;
  }

  Future<List<String>> _searchVideoIds({
    required String query,
    required int maxResults,
    required String regionCode,
    required String order,
    String? videoCategoryId,
  }) async {
    final params = <String, String>{
      'key': _apiKey,
      'q': query,
      'part': 'snippet',
      'type': 'video',
      'maxResults': maxResults.toString(),
      'safeSearch': 'strict',
      'videoEmbeddable': 'true',
      'regionCode': regionCode,
      'relevanceLanguage': 'en',
      'order': order,
    };

    if (videoCategoryId != null && videoCategoryId.isNotEmpty) {
      params['videoCategoryId'] = videoCategoryId;
    }

    final url = Uri.parse('$_baseUrl/search').replace(queryParameters: params);
    final response = await http.get(url);
    if (response.statusCode != 200) {
      return [];
    }

    final data = json.decode(response.body);
    final items = data['items'] as List? ?? [];

    return items
        .map((item) {
          if (item['id'] is String) {
            return item['id'] as String;
          }
          if (item['id'] is Map) {
            return item['id']['videoId']?.toString() ?? '';
          }
          return '';
        })
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<List<YouTubeVideo>> _fetchVideoDetails(List<String> videoIds) async {
    if (videoIds.isEmpty) {
      return [];
    }

    final detailsUrl = Uri.parse('$_baseUrl/videos').replace(
      queryParameters: {
        'key': _apiKey,
        'id': videoIds.join(','),
        'part': 'snippet,contentDetails,statistics',
      },
    );

    final detailsResponse = await http.get(detailsUrl);
    if (detailsResponse.statusCode != 200) {
      return [];
    }

    final detailsData = json.decode(detailsResponse.body);
    final detailsItems = detailsData['items'] as List? ?? [];

    return detailsItems.map((item) => YouTubeVideo.fromJson(item)).toList();
  }

  List<YouTubeVideo> _diversifyByChannel(
    List<YouTubeVideo> videos, {
    required int targetCount,
  }) {
    if (videos.isEmpty) {
      return videos;
    }

    final buckets = <String, List<YouTubeVideo>>{};
    for (final video in videos) {
      final channelKey =
          video.channelId.trim().isNotEmpty
              ? video.channelId.trim()
              : video.channelTitle.trim().toLowerCase();
      buckets.putIfAbsent(channelKey, () => []).add(video);
    }

    final result = <YouTubeVideo>[];
    final keys = buckets.keys.toList();

    while (result.length < targetCount) {
      var addedInRound = false;
      for (final key in keys) {
        final queue = buckets[key];
        if (queue != null && queue.isNotEmpty) {
          result.add(queue.removeAt(0));
          addedInRound = true;
          if (result.length >= targetCount) {
            break;
          }
        }
      }
      if (!addedInRound) {
        break;
      }
    }

    return result;
  }

  // Get videos by preference category
  Future<List<YouTubeVideo>> getVideosByPreference({
    required String preference,
    int maxResults = 20,
    int? childAge,
  }) async {
    // Map preferences to kid-friendly search queries
    final Map<String, String> preferenceQueries = {
      'Art & Crafts': 'kids art and crafts tutorial',
      'Art &\nCrafts': 'kids art and crafts tutorial',
      'Learning': 'educational videos for kids',
      'Puzzles': 'kids puzzle games learning',
      'Urdu\nPoems': 'urdu poems for children',
      'Urdu Poems': 'urdu poems for children',
      'Science & Nature': 'science experiments for kids',
      'Science &\nNature': 'science experiments for kids',
      'Sports': 'kids sports and activities',
      'Animals': 'animal documentaries for kids',
      'Activities': 'fun activities for kids',
      'Cooking Fun': 'cooking for kids easy recipes',
      'Cooking\nFun': 'cooking for kids easy recipes',
      'Music': 'kids educational songs',
    };

    // Add age-appropriate suffix
    String ageQuery = '';
    if (childAge != null) {
      if (childAge <= 6) {
        ageQuery = ' toddler preschool';
      } else if (childAge <= 10) {
        ageQuery = ' elementary school';
      } else {
        ageQuery = ' middle school';
      }
    }

    final query = (preferenceQueries[preference] ?? preference) + ageQuery;
    return searchVideos(query: query, maxResults: maxResults);
  }

  // Get videos for home feed based on all preferences
  Future<List<YouTubeVideo>> getHomeFeedVideos({
    required List<String> preferences,
    int? childAge,
    int maxResults = 30,
    String? childProfileId,
    List<String> customRules = const [], // legacy text-rule array from child_profiles
  }) async {
    try {
      List<YouTubeVideo> allVideos = [];

      // Get videos for each preference
      if (preferences.isNotEmpty) {
        final preferenceFutures = preferences
            .map(
              (preference) => getVideosByPreference(
                preference: preference,
                maxResults: 5,
                childAge: childAge,
              ),
            )
            .toList();
        final preferenceResults = await Future.wait(preferenceFutures);
        for (final videos in preferenceResults) {
          allVideos.addAll(videos);
        }
      }

      // If no preferences, get general kid-friendly content
      if (preferences.isEmpty) {
        allVideos = await searchVideos(
          query: 'educational videos for kids',
          maxResults: maxResults,
        );
      }

      // Remove duplicates
      final uniqueVideos = <String, YouTubeVideo>{};
      for (var video in allVideos) {
        uniqueVideos[video.id] = video;
      }

      List<YouTubeVideo> filteredVideos = uniqueVideos.values.toList();

      // Apply all parental rules (structured + legacy text array)
      if (childProfileId != null) {
        filteredVideos = await applyAllRules(
          videos: filteredVideos,
          childProfileId: childProfileId,
          legacyCustomRules: customRules,
        );
      }

      final classifiedVideos = await classifyVideos(
        filteredVideos,
        childProfileId: childProfileId,
        childAge: childAge,
      );
      return classifiedVideos..shuffle();
    } catch (e) {
      throw Exception('Error loading home feed: $e');
    }
  }

  Future<List<YouTubeVideo>> classifyVideos(
    List<YouTubeVideo> videos, {
    String? childProfileId,
    int? childAge,
  }) async {
    if (videos.isEmpty) {
      print('🏷️ [classifyVideos] No videos to classify');
      return videos;
    }

    final isApiUp = await _apiService.isApiRunning();
    if (!isApiUp) {
      print('🏷️ [classifyVideos] Skipping classification because /running is not 200');
      return videos;
    }

    print('🏷️ [classifyVideos] Starting classification for ${videos.length} videos');
    final enrichedVideos = <YouTubeVideo>[];
    int filteredFlaggedCount = 0;
    for (final video in videos) {
      final videoUrl = 'https://www.youtube.com/watch?v=${video.id}';
      final category = await _apiService.classifyVideo(videoUrl);
      if (category != null && category.isNotEmpty) {
        if (category.trim().toLowerCase() == 'flagged_inappropriate') {
          filteredFlaggedCount += 1;
          print('🚫 [classifyVideos] ${video.id} flagged_inappropriate, removing from feed');

          if (childProfileId != null && childAge != null) {
            try {
              await _flaggedService.processAndSaveFlaggedVideo(
                childProfileId: childProfileId,
                childAge: childAge,
                video: video,
                modelLabel: category,
              );
            } catch (e) {
              print('⚠️ [classifyVideos] Failed to save flagged video ${video.id}: $e');
            }
          }
          continue;
        }

        print('🏷️ [classifyVideos] ${video.id} -> "$category"');
        enrichedVideos.add(video.copyWith(modelCategory: category));
      } else {
        print('🏷️ [classifyVideos] ${video.id} -> no category');
        enrichedVideos.add(video);
      }
    }

    final taggedCount =
        enrichedVideos
            .where(
              (v) => v.modelCategory != null && v.modelCategory!.trim().isNotEmpty,
            )
            .length;
    print(
      '🏷️ [classifyVideos] Completed. tagged=$taggedCount / total=${enrichedVideos.length}, filtered_flagged=$filteredFlaggedCount',
    );

    return enrichedVideos;
  }

  /// Apply all active parental rules to a video list:
  ///  1. Block by channel name (structured — substring match).
  ///  2. Block by category keyword in title / description / channel (structured).
  ///  3. Allowed-only filter: if guardian set an allow-list, video must
  ///     match at least one allowed keyword (structured).
  ///  4. Legacy custom_rules text-array keyword filter.
  Future<List<YouTubeVideo>> applyAllRules({
    required List<YouTubeVideo> videos,
    required String childProfileId,
    List<String> legacyCustomRules = const [],
  }) async {
    try {
      final ruleData =
          await CustomRulesService().getActiveRuleData(childProfileId);

      return videos.where((video) {
        final titleLower   = video.title.toLowerCase();
        final descLower    = video.description.toLowerCase();
        final channelLower = video.channelTitle.toLowerCase();

        // 1. Block by channel (substring so "Cocomelon" blocks
        //    "Cocomelon - Nursery Rhymes")
        for (final ch in ruleData.blockedChannels) {
          if (channelLower.contains(ch)) {
            print('🚫 Blocked channel "$ch": ${video.channelTitle}');
            return false;
          }
        }

        // 2. Block by category keyword
        for (final cat in ruleData.blockedCategories) {
          if (titleLower.contains(cat) ||
              descLower.contains(cat) ||
              channelLower.contains(cat)) {
            print('🚫 Blocked category "$cat": ${video.title}');
            return false;
          }
        }

        // 3. Allowed-only whitelist filter
        if (ruleData.hasAllowedFilter) {
          final allowed = ruleData.allowedCategories.any(
            (cat) =>
                titleLower.contains(cat) ||
                descLower.contains(cat) ||
                channelLower.contains(cat),
          );
          if (!allowed) {
            print('🚫 Not in allowed categories: ${video.title}');
            return false;
          }
        }

        // 4. Legacy text-rule keyword filter
        for (final rule in legacyCustomRules) {
          final keywords = rule
              .toLowerCase()
              .split(' ')
              .where((w) => w.length > 3)
              .toList();
          for (final kw in keywords) {
            if (titleLower.contains(kw) ||
                descLower.contains(kw) ||
                channelLower.contains(kw)) {
              print('🚫 Legacy rule "$rule" blocked: ${video.title}');
              return false;
            }
          }
        }

        return true;
      }).toList();
    } catch (e) {
      print('Error applying rules: $e');
      return videos;
    }
  }

  // Get video details by ID
  Future<YouTubeVideo?> getVideoDetails(String videoId) async {
    try {
      final url = Uri.parse('$_baseUrl/videos').replace(
        queryParameters: {
          'key': _apiKey,
          'id': videoId,
          'part': 'snippet,contentDetails,statistics',
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        if (items.isNotEmpty) {
          return YouTubeVideo.fromJson(items.first);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error getting video details: $e');
    }
  }

  // Get playlist videos
  Future<List<YouTubeVideo>> getPlaylistVideos({
    required String playlistId,
    int maxResults = 50,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/playlistItems').replace(
        queryParameters: {
          'key': _apiKey,
          'playlistId': playlistId,
          'part': 'snippet',
          'maxResults': maxResults.toString(),
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        return items.map((item) {
          // Adjust the structure for playlist items
          final snippet = item['snippet'];
          final modifiedItem = {
            'id': snippet['resourceId']['videoId'],
            'snippet': snippet,
          };
          return YouTubeVideo.fromJson(modifiedItem);
        }).toList();
      } else {
        throw Exception('Failed to load playlist: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading playlist: $e');
    }
  }

}

class _SearchStrategy {
  final String query;
  final String order;
  final String? videoCategoryId;
  final int maxResults;

  const _SearchStrategy({
    required this.query,
    required this.order,
    this.videoCategoryId,
    required this.maxResults,
  });
}

