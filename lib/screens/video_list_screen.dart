import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VideoListScreen extends StatefulWidget {
  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final ApiService _apiService = ApiService();
  List<VideoAnalysis> _videos = [];
  EcoChamberResult? _ecoChamberResult;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Fetch videos with analysis
    final videos = await _apiService.getVideosWithAnalysis();
    
    // Get ecochamber analysis for all videos
    if (videos.isNotEmpty) {
      final videoUrls = videos.map((v) => v.url).toList();
      final ecoResult = await _apiService.getEcoChamberAnalysis(videoUrls);
      
      setState(() {
        _videos = videos;
        _ecoChamberResult = ecoResult;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Analysis'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Ecochamber Summary Card
                if (_ecoChamberResult != null)
                  _buildEcoChamberCard(),
                
                // Videos List
                Expanded(
                  child: ListView.builder(
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      return _buildVideoCard(_videos[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEcoChamberCard() {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.purple.shade50],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Ecochamber Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Most Watched:',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(_ecoChamberResult!.mostWatchedCategory),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _ecoChamberResult!.mostWatchedCategory,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Category Bias:',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${_ecoChamberResult!.categoryPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _ecoChamberResult!.categoryPercentage > 60
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '📌 Recommendations:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ..._ecoChamberResult!.recommendations.map((rec) => Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.fiber_manual_record, size: 8, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Expanded(child: Text(rec)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(VideoAnalysis video) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to video details or play video
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail placeholder
              Container(
                width: 100,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  image: video.thumbnail.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(video.thumbnail),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: video.thumbnail.isEmpty
                    ? Icon(Icons.video_library, color: Colors.grey[600])
                    : null,
              ),
              SizedBox(width: 12),
              // Video info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        // Category tag
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: video.categoryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            video.category,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Confidence tag
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: video.confidenceColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${(video.confidence * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Additional analysis tags
                        if (video.analysisResult.containsKey('sentiment'))
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              video.analysisResult['sentiment'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
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
}