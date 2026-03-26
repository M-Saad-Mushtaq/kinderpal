import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  Future<bool> isApiRunning() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/running');
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Generic GET request
  Future<dynamic> getRequest(String endpoint) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.get(url);
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET request failed: $e');
    }
  }
  
  // Generic POST request
  Future<dynamic> postRequest(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: data != null ? json.encode(data) : null,
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST request failed: $e');
    }
  }
  
  // Handle response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  }
  
  // Video-specific methods
  Future<List<VideoAnalysis>> getVideosWithAnalysis() async {
    try {
      final response = await getRequest('/videos'); // Adjust endpoint as needed
      List<dynamic> videosJson = response['videos'] ?? [];
      return videosJson.map((json) => VideoAnalysis.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching videos: $e');
      return [];
    }
  }
  
  // Get ecochamber analysis for a specific video or list
  Future<EcoChamberResult> getEcoChamberAnalysis(List<String> videoUrls) async {
    try {
      final response = await postRequest(
        '/analyze/ecochamber',
        data: {'video_urls': videoUrls},
      );
      return EcoChamberResult.fromJson(response);
    } catch (e) {
      print('Error analyzing ecochamber: $e');
      return EcoChamberResult.empty();
    }
  }

  Future<String?> classifyVideo(String videoUrl) async {
    try {
      final payload = {'url': videoUrl};
      final response = await postRequest('/classify', data: payload);
      if (response is Map<String, dynamic>) {
        final predictedClass = response['predicted_class']?.toString().trim();
        if (predictedClass != null && predictedClass.isNotEmpty) {
          return predictedClass;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> fetchTranscript(String videoUrl) async {
    try {
      final response = await postRequest('/transcript', data: {'url': videoUrl});
      if (response is Map<String, dynamic>) {
        final transcript = response['transcript']?.toString().trim();
        if (transcript != null && transcript.isNotEmpty) {
          return transcript;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching transcript: $e');
      return null;
    }
  }

  Future<HistoryCategoryResult> analyzeHistoryCategories(List<String> videoUrls) async {
    try {
      final response = await postRequest('/history', data: {'video_urls': videoUrls});
      return HistoryCategoryResult.fromJson(response);
    } catch (e) {
      print('Error analyzing history categories: $e');
      return HistoryCategoryResult.empty();
    }
  }

  Future<HistoryEcoChamberResult> analyzeEcoChamberHistory(
    List<String> urls,
  ) async {
    try {
      final response = await postRequest('/history', data: {'urls': urls});
      return HistoryEcoChamberResult.fromJson(response);
    } catch (e) {
      print('Error analyzing ecochamber history: $e');
      return HistoryEcoChamberResult.empty();
    }
  }
}

// Model for Video Analysis
class VideoAnalysis {
  final String id;
  final String title;
  final String url;
  final String thumbnail;
  final Map<String, dynamic> analysisResult;
  final String category; // e.g., 'tech', 'politics', 'entertainment'
  final double confidence; // 0.0 to 1.0
  
  VideoAnalysis({
    required this.id,
    required this.title,
    required this.url,
    required this.thumbnail,
    required this.analysisResult,
    required this.category,
    required this.confidence,
  });
  
  // Get color based on category/result
  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'tech':
        return Colors.blue;
      case 'politics':
        return Colors.red;
      case 'entertainment':
        return Colors.purple;
      case 'sports':
        return Colors.green;
      case 'education':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  // Get tag style based on confidence
  Color get confidenceColor {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }
  
  factory VideoAnalysis.fromJson(Map<String, dynamic> json) {
    return VideoAnalysis(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      analysisResult: json['analysis'] ?? {},
      category: json['category'] ?? 'unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }
}

// Model for Ecochamber Result
class EcoChamberResult {
  final Map<String, int> categoryCounts;
  final String mostWatchedCategory;
  final double categoryPercentage;
  final List<String> recommendations;
  
  EcoChamberResult({
    required this.categoryCounts,
    required this.mostWatchedCategory,
    required this.categoryPercentage,
    required this.recommendations,
  });
  
  factory EcoChamberResult.fromJson(Map<String, dynamic> json) {
    return EcoChamberResult(
      categoryCounts: Map<String, int>.from(json['category_counts'] ?? {}),
      mostWatchedCategory: json['most_watched_category'] ?? 'unknown',
      categoryPercentage: (json['category_percentage'] ?? 0.0).toDouble(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
  
  factory EcoChamberResult.empty() {
    return EcoChamberResult(
      categoryCounts: {},
      mostWatchedCategory: 'unknown',
      categoryPercentage: 0.0,
      recommendations: [],
    );
  }
}

class HistoryCategoryResult {
  final Map<String, int> categories;

  const HistoryCategoryResult({required this.categories});

  String get topCategory {
    if (categories.isEmpty) {
      return 'Unknown';
    }
    final sortedEntries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.first.key;
  }

  int get totalVideos {
    return categories.values.fold(0, (sum, value) => sum + value);
  }

  factory HistoryCategoryResult.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return HistoryCategoryResult.empty();
    }

    dynamic rawCategories = json['categories'];
    rawCategories ??= json['category_counts'];

    if (rawCategories is Map<String, dynamic>) {
      final parsed = <String, int>{};
      rawCategories.forEach((key, value) {
        final count = value is int ? value : int.tryParse(value.toString()) ?? 0;
        if (count > 0) {
          parsed[key] = count;
        }
      });
      return HistoryCategoryResult(categories: parsed);
    }

    if (rawCategories is Map) {
      final parsed = <String, int>{};
      rawCategories.forEach((key, value) {
        final category = key.toString();
        final count = value is int ? value : int.tryParse(value.toString()) ?? 0;
        if (count > 0) {
          parsed[category] = count;
        }
      });
      return HistoryCategoryResult(categories: parsed);
    }

    final singleCategory = json['category']?.toString();
    if (singleCategory != null && singleCategory.trim().isNotEmpty) {
      return HistoryCategoryResult(categories: {singleCategory.trim(): 1});
    }

    return HistoryCategoryResult.empty();
  }

  factory HistoryCategoryResult.empty() {
    return const HistoryCategoryResult(categories: {});
  }
}

class HistoryEcoChamberResult {
  final double eciScore;
  final String label;
  final String description;
  final String hexColor;
  final String primaryGenre;
  final String primaryTopic;
  final Map<String, int> genreDistribution;
  final int totalVideos;
  final List<String> echoTitles;
  final HistoryMetric diversity;
  final HistoryMetric dominance;
  final HistoryMetric homophily;

  const HistoryEcoChamberResult({
    required this.eciScore,
    required this.label,
    required this.description,
    required this.hexColor,
    required this.primaryGenre,
    required this.primaryTopic,
    required this.genreDistribution,
    required this.totalVideos,
    required this.echoTitles,
    required this.diversity,
    required this.dominance,
    required this.homophily,
  });

  factory HistoryEcoChamberResult.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return HistoryEcoChamberResult.empty();
    }

    final results =
        json['results'] is Map<String, dynamic>
            ? json['results'] as Map<String, dynamic>
            : <String, dynamic>{};

    final summaryCard =
        results['summary_card'] is Map<String, dynamic>
            ? results['summary_card'] as Map<String, dynamic>
            : <String, dynamic>{};

    final breakdown =
        results['breakdown'] is Map<String, dynamic>
            ? results['breakdown'] as Map<String, dynamic>
            : <String, dynamic>{};

    final rawData =
        results['raw_data'] is Map<String, dynamic>
            ? results['raw_data'] as Map<String, dynamic>
            : <String, dynamic>{};

    final rawGenreDistribution = results['genre_distribution'];
    final parsedGenreDistribution = <String, int>{};
    if (rawGenreDistribution is Map<String, dynamic>) {
      rawGenreDistribution.forEach((key, value) {
        final parsed = value is int ? value : int.tryParse(value.toString()) ?? 0;
        if (parsed > 0) {
          parsedGenreDistribution[key] = parsed;
        }
      });
    } else if (rawGenreDistribution is Map) {
      rawGenreDistribution.forEach((key, value) {
        final genre = key.toString();
        final parsed = value is int ? value : int.tryParse(value.toString()) ?? 0;
        if (parsed > 0) {
          parsedGenreDistribution[genre] = parsed;
        }
      });
    }

    final eciScoreRaw = summaryCard['eci_score'];
    final eciScore =
        eciScoreRaw is num ? eciScoreRaw.toDouble() : double.tryParse(eciScoreRaw?.toString() ?? '') ?? 0.0;

    final totalVideosRaw = rawData['total_videos'];
    final totalVideos =
        totalVideosRaw is int ? totalVideosRaw : int.tryParse(totalVideosRaw?.toString() ?? '') ?? 0;

    final echoTitlesRaw = rawData['echo_titles'];
    final echoTitles =
        echoTitlesRaw is List
            ? echoTitlesRaw.map((item) => item.toString()).toList()
            : <String>[];

    return HistoryEcoChamberResult(
      eciScore: eciScore,
      label: summaryCard['label']?.toString() ?? 'Unknown',
      description: summaryCard['description']?.toString() ?? 'No description available.',
      hexColor: summaryCard['hex_color']?.toString() ?? '#4CAF50',
      primaryGenre: summaryCard['primary_genre']?.toString() ?? 'Unknown',
      primaryTopic: summaryCard['primary_topic']?.toString() ?? 'Unknown',
      genreDistribution: parsedGenreDistribution,
      totalVideos: totalVideos,
      echoTitles: echoTitles,
      diversity: HistoryMetric.fromJson(
        breakdown['diversity'],
        fallbackTitle: 'Variety Score',
      ),
      dominance: HistoryMetric.fromJson(
        breakdown['dominance'],
        fallbackTitle: 'Topic Concentration',
      ),
      homophily: HistoryMetric.fromJson(
        breakdown['homophily'],
        fallbackTitle: 'Source Bias',
      ),
    );
  }

  factory HistoryEcoChamberResult.empty() {
    return HistoryEcoChamberResult(
      eciScore: 0.0,
      label: 'Unknown',
      description: 'No analysis available.',
      hexColor: '#4CAF50',
      primaryGenre: 'Unknown',
      primaryTopic: 'Unknown',
      genreDistribution: const {},
      totalVideos: 0,
      echoTitles: const [],
      diversity: HistoryMetric.empty('Variety Score'),
      dominance: HistoryMetric.empty('Topic Concentration'),
      homophily: HistoryMetric.empty('Source Bias'),
    );
  }
}

class HistoryMetric {
  final String title;
  final String insight;
  final double value;

  const HistoryMetric({
    required this.title,
    required this.insight,
    required this.value,
  });

  factory HistoryMetric.fromJson(
    dynamic json, {
    required String fallbackTitle,
  }) {
    if (json is! Map<String, dynamic>) {
      return HistoryMetric.empty(fallbackTitle);
    }

    final rawValue = json['value'];
    final value =
        rawValue is num ? rawValue.toDouble() : double.tryParse(rawValue?.toString() ?? '') ?? 0.0;

    return HistoryMetric(
      title: json['title']?.toString() ?? fallbackTitle,
      insight: json['insight']?.toString() ?? '',
      value: value,
    );
  }

  factory HistoryMetric.empty(String title) {
    return HistoryMetric(title: title, insight: '', value: 0.0);
  }
}