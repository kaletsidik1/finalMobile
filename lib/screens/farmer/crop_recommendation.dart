import 'package:flutter/material.dart';
import '../../models/agriai_model.dart';
import '../../models/farm_model.dart';
import '../../services/api_service.dart';
import '../../services/soil_climate_service.dart';
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

  List<Farm> _farms = [];
  Farm? _selectedFarm;
  bool _farmsLoaded = false;

  SoilClimateData? _soilData;
  bool _isFetchingSoil = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final profile = await _api.getProfile();
    final region = profile?.region?.trim();
    _region = (region != null && region.isNotEmpty) ? region : 'Oromia';

    final farmsResult = await _api.getFarms();
    if (farmsResult.success) {
      _farms = farmsResult.farms;
      _farmsLoaded = true;
    }

    await _runRecommendation();
  }

  Future<void> _onFarmSelected(Farm? farm) async {
    setState(() {
      _selectedFarm = farm;
      _soilData = null;
    });

    if (farm == null) {
      _runRecommendation();
      return;
    }

    final lat = farm.latitude;
    final lng = farm.longitude;

    if (lat != null && lng != null) {
      setState(() => _isFetchingSoil = true);
      final data = await SoilClimateService.fetch(lat, lng);
      if (!mounted) return;
      setState(() {
        _soilData = data;
        _isFetchingSoil = false;
      });
    }

    _runRecommendation();
  }

  Future<void> _runRecommendation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _api.recommendCropWithDefaults(
      nitrogen: _selectedFarm?.nitrogen?.toInt() ?? _soilData?.nitrogen?.toInt() ?? 50,
      phosphorus: _selectedFarm?.phosphorus?.toInt() ?? _soilData?.phosphorus?.toInt() ?? 30,
      potassium: _selectedFarm?.potassium?.toInt() ?? _soilData?.potassium?.toInt() ?? 20,
      temperature: _selectedFarm?.temperature ?? _soilData?.temperature ?? 25,
      humidity: _selectedFarm?.humidity ?? _soilData?.humidity ?? 60,
      ph: _selectedFarm?.ph ?? _soilData?.ph ?? 6.5,
      rainfall: _selectedFarm?.rainfall ?? _soilData?.rainfall ?? 100,
      soilColor: _selectedFarm?.soilColor ?? 'brown',
      region: _selectedFarm?.region?.isNotEmpty == true
          ? _selectedFarm!.region
          : _region,
    );

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
      final recRegion = (_selectedFarm?.region?.isNotEmpty == true
          ? _selectedFarm!.region!
          : _region)!;
      final priceResult = await _api.predictCropPrice(
        cropName: topCrop,
        region: recRegion,
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
          onRefresh: _load,
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
                        onPressed: _loading ? null : _load,
                        icon: const Icon(Icons.refresh_rounded),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_farmsLoaded && _farms.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedFarm?.id,
                      decoration: InputDecoration(
                        labelText: 'Select Farm',
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      hint: const Text('All farms (default soil)'),
                      items: _farms.map((f) {
                        return DropdownMenuItem(
                          value: f.id,
                          child: Text(f.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (id) {
                        _onFarmSelected(
                          id != null ? _farms.firstWhere((f) => f.id == id) : null,
                        );
                      },
                    ),
                  ),
                ),
              if (_selectedFarm != null && _soilData != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _SoilDataCard(data: _soilData!),
                  ),
                ),
              if (_selectedFarm != null && _isFetchingSoil)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _SoilDataLoading(),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroBanner(
                        region: _selectedFarm?.region?.isNotEmpty == true
                            ? _selectedFarm!.region
                            : _region,
                        farmName: _selectedFarm?.name,
                      ),
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
                        _ErrorState(message: _error!, onRetry: _runRecommendation)
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

class _SoilDataCard extends StatelessWidget {
  final SoilClimateData data;

  const _SoilDataCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = <String, String?>{
      'Nitrogen (N)': data.nitrogen != null ? '${data.nitrogen!.toStringAsFixed(1)} mg/kg' : null,
      'Phosphorus (P)': data.phosphorus != null ? '${data.phosphorus!.toStringAsFixed(1)} mg/kg' : null,
      'Potassium (K)': data.potassium != null ? '${data.potassium!.toStringAsFixed(1)} mg/kg' : null,
      'pH': data.ph?.toStringAsFixed(1),
      'Temperature': data.temperature != null ? '${data.temperature!.toStringAsFixed(1)}°C' : null,
      'Humidity': data.humidity != null ? '${data.humidity!.toStringAsFixed(0)}%' : null,
      'Rainfall': data.rainfall != null ? '${data.rainfall!.toStringAsFixed(0)} mm' : null,
    };

    final entries = items.entries.where((e) => e.value != null).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Soil Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Auto-detected',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${e.key}: ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    e.value!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SoilDataLoading extends StatelessWidget {
  const _SoilDataLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Fetching soil & climate data…',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final String? region;
  final String? farmName;

  const _HeroBanner({this.region, this.farmName});

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
                  farmName != null
                      ? 'Based on $farmName soil data'
                      : region != null
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
