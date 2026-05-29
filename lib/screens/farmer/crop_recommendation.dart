import 'package:flutter/material.dart';
import '../../models/agriai_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CropRecommendation extends StatefulWidget {
  const CropRecommendation({super.key});

  @override
  State<CropRecommendation> createState() => _CropRecommendationState();
}

class _CropRecommendationState extends State<CropRecommendation> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  List<CropRecommendationItem> _recommendations = [];
  CropPriceForecast? _topForecast;
  String? _region;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final profile = await _api.getProfile();
    final region = profile?.region?.trim();
    _region = (region != null && region.isNotEmpty) ? region : 'Oromia';

    final result = await _api.recommendCropWithDefaults();
    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _loading = false;
        _error = result.message ?? 'Could not load AI recommendations';
      });
      return;
    }

    CropPriceForecast? forecast;
    if (result.recommendations.isNotEmpty) {
      final topCrop = result.recommendations.first.crop;
      final priceResult = await _api.predictCropPrice(
        cropName: topCrop,
        region: _region!,
      );
      if (priceResult.success) {
        forecast = priceResult.forecast;
      }
    }

    if (!mounted) return;
    setState(() {
      _recommendations = result.recommendations;
      _topForecast = forecast;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecommendations,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Crop Insights',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 26,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: _loading ? null : _loadRecommendations,
                        icon: const Icon(Icons.refresh_rounded),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroBanner(region: _region),
                      if (_topForecast != null) ...[
                        const SizedBox(height: 16),
                        _PriceForecastCard(forecast: _topForecast!),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Top Recommendations',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      else if (_error != null)
                        _ErrorState(message: _error!, onRetry: _loadRecommendations)
                      else if (_recommendations.isEmpty)
                        const _EmptyState()
                      else
                        ..._recommendations.asMap().entries.map(
                              (entry) => _RecommendationCard(
                                item: entry.value,
                                featured: entry.key == 0,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final String? region;

  const _HeroBanner({this.region});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI-Powered Recommendations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  region != null
                      ? 'Based on soil data and $region market trends'
                      : 'Based on soil and regional market trends',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceForecastCard extends StatelessWidget {
  final CropPriceForecast forecast;

  const _PriceForecastCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final trendIcon = forecast.trend == 'increasing'
        ? Icons.trending_up_rounded
        : forecast.trend == 'decreasing'
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price outlook: ${forecast.cropName}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(trendIcon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '${forecast.predictedPrice.toStringAsFixed(0)} ETB • ${forecast.trend} (${forecast.trendPercentage.toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          Text(
            '${forecast.region} • ${forecast.month}/${forecast.year}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final CropRecommendationItem item;
  final bool featured;

  const _RecommendationCard({
    required this.item,
    required this.featured,
  });

  @override
  Widget build(BuildContext context) {
    final confidence = item.confidencePercent;
    final confidenceLabel =
        confidence != null ? '${confidence.toStringAsFixed(0)}% match' : item.confidence;

    if (!featured) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.grass_rounded, color: AppColors.primary, size: 20),
          ),
          title: Text(
            _formatCropName(item.crop),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(confidenceLabel),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCropName(item.crop),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                _Chip(label: confidenceLabel),
                const SizedBox(height: 4),
                const Text(
                  'Best pick from AgriAI for your soil profile',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCropName(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(message, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'No recommendations returned. Pull to refresh or try again later.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
