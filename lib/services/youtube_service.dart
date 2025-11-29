import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';

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

      return uniqueVideos.values.toList()..shuffle();
    } catch (e) {
      throw Exception('Error loading home feed: $e');
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

  // Filter videos based on custom rules
  List<YouTubeVideo> filterVideosByRules({
    required List<YouTubeVideo> videos,
    required List<String> customRules,
  }) {
    if (customRules.isEmpty) return videos;

    return videos.where((video) {
      final lowerTitle = video.title.toLowerCase();
      final lowerDescription = video.description.toLowerCase();
      final lowerChannel = video.channelTitle.toLowerCase();

      for (String rule in customRules) {
        final lowerRule = rule.toLowerCase();

        // Check if rule contains blocked keywords
        if (lowerRule.contains('no toys') &&
            (lowerTitle.contains('toy') || lowerDescription.contains('toy'))) {
          return false;
        }

        if (lowerRule.contains('no vlogs') &&
            (lowerTitle.contains('vlog') ||
                lowerDescription.contains('vlog'))) {
          return false;
        }

        // Add more rule patterns as needed
        final keywords = lowerRule
            .split(' ')
            .where((w) => w.length > 2)
            .toList();
        for (String keyword in keywords) {
          if (lowerTitle.contains(keyword) ||
              lowerDescription.contains(keyword) ||
              lowerChannel.contains(keyword)) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }
}
