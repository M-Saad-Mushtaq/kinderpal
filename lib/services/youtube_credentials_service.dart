import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class YouTubeCredentialsService {
  static const _storage = FlutterSecureStorage();

  static const String _apiKeyKey = 'youtube_api_key';
  static const String _clientIdKey = 'youtube_client_id';
  static const String _clientSecretKey = 'youtube_client_secret';

  // Save API credentials
  static Future<void> saveCredentials({
    required String apiKey,
    required String clientId,
    String? clientSecret,
  }) async {
    await _storage.write(key: _apiKeyKey, value: apiKey);
    await _storage.write(key: _clientIdKey, value: clientId);
    if (clientSecret != null && clientSecret.isNotEmpty) {
      await _storage.write(key: _clientSecretKey, value: clientSecret);
    }
  }

  // Get API Key
  static Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyKey);
  }

  // Get Client ID
  static Future<String?> getClientId() async {
    return await _storage.read(key: _clientIdKey);
  }

  // Get Client Secret
  static Future<String?> getClientSecret() async {
    return await _storage.read(key: _clientSecretKey);
  }

  // Check if credentials exist
  static Future<bool> hasCredentials() async {
    final apiKey = await getApiKey();
    final clientId = await getClientId();
    return apiKey != null && clientId != null;
  }

  // Clear all credentials
  static Future<void> clearCredentials() async {
    await _storage.delete(key: _apiKeyKey);
    await _storage.delete(key: _clientIdKey);
    await _storage.delete(key: _clientSecretKey);
  }

  // Get all credentials at once
  static Future<Map<String, String?>> getAllCredentials() async {
    return {
      'apiKey': await getApiKey(),
      'clientId': await getClientId(),
      'clientSecret': await getClientSecret(),
    };
  }
}
