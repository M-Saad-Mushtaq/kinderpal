import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';
import 'custom_rules_service.dart';

class YouTubeService {
  static const String _apiKey = 'AIzaSyCXxSdotaK9WTpWJc9QPnyh77MBcVw6TL4';
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  // Search videos with safe search enabled
  Future<List<YouTubeVideo>> searchVideos({
    required String query,
    int maxResults = 20,
    String? regionCode = 'US',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'key': _apiKey,
          'q': query,
          'part': 'snippet',
          'type': 'video',
          'maxResults': maxResults.toString(),
          'safeSearch': 'strict',
          'videoEmbeddable': 'true',
          'regionCode': regionCode ?? 'US',
          'relevanceLanguage': 'en',
          'videoCategoryId': '27', // Education category
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        // Get video IDs
        final videoIds = items
            .map((item) {
              if (item['id'] is String) {
                return item['id'] as String;
              } else if (item['id'] is Map) {
                return item['id']['videoId'] as String;
              }
              return '';
            })
            .where((id) => id.isNotEmpty)
            .toList();

        // Fetch full details including duration
        if (videoIds.isNotEmpty) {
          final detailsUrl = Uri.parse('$_baseUrl/videos').replace(
            queryParameters: {
              'key': _apiKey,
              'id': videoIds.join(','),
              'part': 'snippet,contentDetails,statistics',
            },
          );

          final detailsResponse = await http.get(detailsUrl);

          if (detailsResponse.statusCode == 200) {
            final detailsData = json.decode(detailsResponse.body);
            final detailsItems = detailsData['items'] as List;

            return detailsItems
                .map((item) => YouTubeVideo.fromJson(item))
                .toList();
          }
        }

        return items.map((item) => YouTubeVideo.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching videos: $e');
    }
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
      for (String preference in preferences) {
        final videos = await getVideosByPreference(
          preference: preference,
          maxResults: 5,
          childAge: childAge,
        );
        allVideos.addAll(videos);
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

      return filteredVideos..shuffle();
    } catch (e) {
      throw Exception('Error loading home feed: $e');
    }
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

