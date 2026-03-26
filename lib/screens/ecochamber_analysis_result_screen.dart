import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/api_service.dart';

class EcochamberAnalysisResultScreen extends StatelessWidget {
  final HistoryEcoChamberResult result;

  const EcochamberAnalysisResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final genres = result.genreDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Ecochamber Analysis', style: AppTextStyles.heading3),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _parseApiColor(result.hexColor).withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _parseApiColor(result.hexColor).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            result.label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _parseApiColor(result.hexColor),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'ECI ${result.eciScore.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: _parseApiColor(result.hexColor),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Primary Topic: ${result.primaryTopic}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Primary Genre: ${result.primaryGenre}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${result.totalVideos} analyzed videos',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Breakdown', style: AppTextStyles.heading3),
              const SizedBox(height: 10),
              _buildMetricCard(result.diversity),
              _buildMetricCard(result.dominance),
              _buildMetricCard(result.homophily),
              const SizedBox(height: 20),
              Text('Genre Distribution', style: AppTextStyles.heading3),
              const SizedBox(height: 10),
              if (genres.isEmpty)
                _buildEmptyCard('No genre distribution returned.')
              else
                ...genres.map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryLight.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.value.toString(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text('Echo Titles', style: AppTextStyles.heading3),
              const SizedBox(height: 10),
              if (result.echoTitles.isEmpty)
                _buildEmptyCard('No title-level echo data returned.')
              else
                ...result.echoTitles.take(5).map(
                  (title) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryLight.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      title,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(HistoryMetric metric) {
    final normalized = metric.value.clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  metric.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                metric.value.toStringAsFixed(2),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: normalized,
            minHeight: 7,
            backgroundColor: AppColors.veryLightBlue,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          if (metric.insight.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              metric.insight,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textGray,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
      ),
    );
  }

  Color _parseApiColor(String hex) {
    final sanitized = hex.trim().replaceFirst('#', '');
    if (sanitized.length == 6) {
      final value = int.tryParse('FF$sanitized', radix: 16);
      if (value != null) {
        return Color(value);
      }
    }
    return AppColors.green;
  }
}
