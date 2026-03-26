import 'env_config.dart';

class ApiConfig {
  static const String baseUrl = EnvConfig.apiBaseUrl;
  
  // API Endpoints
  static String get videosEndpoint => '$baseUrl/api/videos';
  static String get analysisEndpoint => '$baseUrl/api/analyze';
  static String get classifyEndpoint => '$baseUrl/classify';
  static String get historyEndpoint => '$baseUrl/history';
  // Add more endpoints as needed
}