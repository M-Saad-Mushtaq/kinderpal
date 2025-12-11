import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/youtube/v3.dart' as youtube;
import 'package:http/http.dart' as http;

class YouTubeAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/youtube.readonly',
      'https://www.googleapis.com/auth/youtube.force-ssl',
    ],
  );

  GoogleSignInAccount? _currentUser;
  youtube.YouTubeApi? _youtubeApi;

  // Sign in to Google and get YouTube access
  Future<bool> signInToYouTube() async {
    try {
      print('DEBUG: Starting Google Sign-In...');
      final account = await _googleSignIn.signIn();

      if (account == null) {
        print('DEBUG: Sign-in cancelled by user or failed');
        return false;
      }

      print('DEBUG: Sign-in successful, user: ${account.email}');
      _currentUser = account;

      // Get authentication headers
      print('DEBUG: Getting auth headers...');
      final authHeaders = await account.authHeaders;
      print('DEBUG: Auth headers obtained');

      final authenticateClient = _GoogleAuthClient(authHeaders);
      _youtubeApi = youtube.YouTubeApi(authenticateClient);

      print('DEBUG: YouTube API initialized successfully');
      return true;
    } catch (e, stackTrace) {
      print('ERROR: Failed to sign in to YouTube');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Check if user is already signed in
  Future<bool> isSignedIn() async {
    final account = await _googleSignIn.signInSilently();
    if (account != null) {
      _currentUser = account;
      final authHeaders = await account.authHeaders;
      final authenticateClient = _GoogleAuthClient(authHeaders);
      _youtubeApi = youtube.YouTubeApi(authenticateClient);
      return true;
    }
    return false;
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _youtubeApi = null;
  }

  // Get YouTube watch history
  Future<List<Map<String, dynamic>>> getWatchHistory({
    int maxResults = 50,
  }) async {
    if (_youtubeApi == null) {
      throw Exception('Not signed in to YouTube');
    }

    try {
      List<Map<String, dynamic>> watchHistory = [];

      print('DEBUG: Attempting to access Watch History playlist...');

      // Try to access the Watch History playlist (special playlist ID: HL)
      try {
        final playlistItems = await _youtubeApi!.playlistItems.list(
          ['snippet', 'contentDetails'],
          playlistId: 'HL', // Special playlist ID for Watch History
          maxResults: maxResults,
        );

        print(
          'DEBUG: Watch History items found: ${playlistItems.items?.length ?? 0}',
        );

        if (playlistItems.items != null && playlistItems.items!.isNotEmpty) {
          for (var item in playlistItems.items!) {
            final videoId = item.contentDetails?.videoId;
            if (videoId != null && videoId.isNotEmpty) {
              watchHistory.add({
                'videoId': videoId,
                'title': item.snippet?.title ?? 'Unknown Video',
                'description': item.snippet?.description ?? '',
                'publishedAt': item.snippet?.publishedAt ?? DateTime.now(),
                'thumbnailUrl':
                    item.snippet?.thumbnails?.high?.url ??
                    item.snippet?.thumbnails?.medium?.url ??
                    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                'channelTitle': item.snippet?.channelTitle ?? '',
              });
            }
          }

          print(
            'DEBUG: Successfully loaded ${watchHistory.length} videos from Watch History',
          );
          return watchHistory;
        }
      } catch (e) {
        print('DEBUG: Watch History playlist not accessible: $e');
        print(
          'WARNING: YouTube API does not allow watch history access due to privacy restrictions',
        );
      }

      print('DEBUG: Falling back to activities...');

      // Fallback: Try to get activities
      try {
        final activities = await _youtubeApi!.activities.list(
          ['snippet', 'contentDetails'],
          mine: true,
          maxResults: maxResults,
        );

        print('DEBUG: Activities found: ${activities.items?.length ?? 0}');

        if (activities.items != null) {
          for (var activity in activities.items!) {
            print('DEBUG: Activity type: ${activity.snippet?.type}');

            String? videoId;

            // Handle different activity types
            if (activity.snippet?.type == 'recommendation') {
              videoId =
                  activity.contentDetails?.recommendation?.resourceId?.videoId;
            } else if (activity.snippet?.type == 'like') {
              videoId = activity.contentDetails?.like?.resourceId?.videoId;
            }

            if (videoId != null && videoId.isNotEmpty) {
              watchHistory.add({
                'videoId': videoId,
                'title': activity.snippet?.title ?? 'Unknown Video',
                'description': activity.snippet?.description ?? '',
                'publishedAt': activity.snippet?.publishedAt ?? DateTime.now(),
                'thumbnailUrl':
                    activity.snippet?.thumbnails?.high?.url ??
                    activity.snippet?.thumbnails?.medium?.url ??
                    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                'channelTitle': activity.snippet?.channelTitle ?? '',
              });
            }
          }
        }
      } catch (e) {
        print('DEBUG: Error fetching activities: $e');
      }

      // Also try to get liked videos as fallback
      try {
        print('DEBUG: Fetching liked videos...');
        final videosResponse = await _youtubeApi!.videos.list(
          ['snippet'],
          myRating: 'like',
          maxResults: maxResults,
        );

        print(
          'DEBUG: Liked videos found: ${videosResponse.items?.length ?? 0}',
        );

        if (videosResponse.items != null) {
          for (var video in videosResponse.items!) {
            // Avoid duplicates
            if (!watchHistory.any((item) => item['videoId'] == video.id)) {
              watchHistory.add({
                'videoId': video.id ?? '',
                'title': video.snippet?.title ?? 'Unknown Video',
                'description': video.snippet?.description ?? '',
                'publishedAt': video.snippet?.publishedAt ?? DateTime.now(),
                'thumbnailUrl':
                    video.snippet?.thumbnails?.high?.url ??
                    video.snippet?.thumbnails?.medium?.url ??
                    'https://img.youtube.com/vi/${video.id}/hqdefault.jpg',
                'channelTitle': video.snippet?.channelTitle ?? '',
              });
            }
          }
        }
      } catch (e) {
        print('DEBUG: Error fetching liked videos: $e');
      }

      print('DEBUG: Total videos in history: ${watchHistory.length}');
      return watchHistory;
    } catch (e) {
      print('ERROR: Failed to get watch history: $e');
      rethrow;
    }
  }

  // Get user's YouTube channel info
  Future<Map<String, dynamic>?> getUserChannelInfo() async {
    if (_youtubeApi == null) {
      throw Exception('Not signed in to YouTube');
    }

    try {
      final channelsResponse = await _youtubeApi!.channels.list([
        'snippet',
        'statistics',
      ], mine: true);

      if (channelsResponse.items == null || channelsResponse.items!.isEmpty) {
        return null;
      }

      final channel = channelsResponse.items!.first;
      return {
        'id': channel.id ?? '',
        'title': channel.snippet?.title ?? '',
        'description': channel.snippet?.description ?? '',
        'thumbnailUrl': channel.snippet?.thumbnails?.high?.url ?? '',
        'subscriberCount': channel.statistics?.subscriberCount ?? '0',
        'videoCount': channel.statistics?.videoCount ?? '0',
      };
    } catch (e) {
      print('Error getting channel info: $e');
      return null;
    }
  }

  GoogleSignInAccount? get currentUser => _currentUser;
}

// Custom HTTP client for authenticated requests
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
