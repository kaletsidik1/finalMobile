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

  bool _initialLoading = true;
  bool _running = false;
  String? _error;

  List<Farm> _farms = [];
  Farm? _selectedFarm;

  SoilClimateData? _soilData;
  bool _isFetchingSoil = false;

  List<CropRecommendationItem> _recommendations = [];
  CropPriceForecast? _topForecast;
  String? _region;
  bool _hasRun = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });

    final profile = await _api.getProfile();
    final region = profile?.region?.trim();
    _region = (region != null && region.isNotEmpty) ? region : 'Oromia';

    final farmsResult = await _api.getFarms();
    if (!mounted) return;

    setState(() {
      if (farmsResult.success) {
        _farms = farmsResult.farms;
      }
      _initialLoading = false;
    });
  }

  Future<void> _onFarmSelected(String? id) async {
    final farm = id != null ? _farms.firstWhere((f) => f.id == id) : null;

    setState(() {
      _selectedFarm = farm;
      _soilData = null;
      _recommendations = [];
      _topForecast = null;
      _hasRun = false;
      _error = null;
    });

    if (farm == null) return;

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
  }

  Future<void> _getRecommendation() async {
    if (_selectedFarm == null) return;

    setState(() {
      _running = true;
      _error = null;
      _recommendations = [];
      _topForecast = null;
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
        _running = false;
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
      _running = false;
      _hasRun = true;
    });
  }

  String _confidenceDescription(double? percent) {
    if (percent == null) return 'Good match';
    if (percent >= 85) return 'Excellent match for your soil';
    if (percent >= 70) return 'Strong match for your soil';
    if (percent >= 50) return 'Moderate match for your soil';
    return 'Possible option for your soil';
  }

  String _trendIcon(String trend) {
    switch (trend) {
      case 'increasing':
        return '\u2191';
      case 'decreasing':
        return '\u2193';
      default:
        return '\u2192';
    }
  }

  String _trendDescription(String trend) {
    switch (trend) {
      case 'increasing':
        return 'Price is rising';
      case 'decreasing':
        return 'Price is falling';
      default:
        return 'Price is stable';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: _initialLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildHeader(),
                    _buildFarmSelector(),
                    if (_isFetchingSoil) _buildSoilLoading(),
                    if (_selectedFarm != null && _soilData != null) _buildSoilData(),
                    if (_selectedFarm != null) _buildActionButton(),
                    if (_running) _buildRunningState(),
                    if (_error != null) _buildError(),
                    if (_hasRun && !_running && _recommendations.isNotEmpty)
                      ..._buildResults(),
                    if (_hasRun && !_running && _recommendations.isEmpty && _error == null)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No recommendations returned for this farm. Try again later.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crop Insights',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select a farm below, then get AI-powered crop recommendations tailored to your soil.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmSelector() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: DropdownButtonFormField<String>(
          value: _selectedFarm?.id,
          decoration: InputDecoration(
            labelText: 'Choose your farm land',
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            hintText: 'Select a farm...',
            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: const Icon(Icons.agriculture_rounded, color: AppColors.primary),
          ),
          items: _farms.map((f) {
            final soilInfo = f.soilType != null && f.soilType!.isNotEmpty
                ? ' - ${f.soilType!.substring(0, 1).toUpperCase()}${f.soilType!.substring(1)} soil'
                : '';
            return DropdownMenuItem(
              value: f.id,
              child: Text(
                '${f.name}$soilInfo',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _onFarmSelected,
        ),
      ),
    );
  }

  Widget _buildSoilLoading() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 12),
              Text(
                'Fetching soil & climate data from satellites...',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoilData() {
    final farm = _selectedFarm!;
    final data = _soilData!;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.science_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          farm.locationLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
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
              const Divider(height: 24),
              _soilRow(Icons.eco_rounded, 'Nitrogen (N)', data.nitrogen, 'mg/kg', '%.1f'),
              _soilRow(Icons.science_outlined, 'pH Level', data.ph, '', '%.1f'),
              _soilRow(Icons.thermostat_rounded, 'Temperature', data.temperature, '\u00b0C', '%.1f'),
              _soilRow(Icons.water_drop_rounded, 'Humidity', data.humidity, '%', '%.0f'),
              _soilRow(Icons.umbrella_rounded, 'Rainfall', data.rainfall, 'mm', '%.0f'),
              if (farm.soilType != null && farm.soilType!.isNotEmpty)
                _staticRow(Icons.layers_rounded, 'Soil Type', farm.soilType!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _soilRow(IconData icon, String label, double? value, String unit, String format) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value != null ? '${value.toStringAsFixed(0)}$unit' : '--',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _staticRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.substring(0, 1).toUpperCase() + value.substring(1),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final canRun = _selectedFarm != null && !_isFetchingSoil && !_running;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: canRun ? _getRecommendation : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _running
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(
              _running ? 'Analyzing your soil...' : 'Get Recommendation',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRunningState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(
              'AI is analyzing your soil data...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _getRecommendation,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResults() {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: _HeroBanner(
            farmName: _selectedFarm?.name,
            region: _selectedFarm?.region?.isNotEmpty == true
                ? _selectedFarm!.region
                : _region,
          ),
        ),
      ),
      if (_topForecast != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _PriceForecastCard(
              forecast: _topForecast!,
              trendIcon: _trendIcon,
              trendDescription: _trendDescription,
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Recommended Crops for Your Farm',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text(
            'Based on your soil data, here are the best crops ranked by suitability',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        sliver: SliverList.separated(
          itemCount: _recommendations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = _recommendations[index];
            final confidence = item.confidencePercent;
            return _DetailedRecommendationCard(
              rank: index + 1,
              cropName: item.crop,
              confidence: confidence,
              description: _confidenceDescription(confidence),
              isTopPick: index == 0,
              total: _recommendations.length,
            );
          },
        ),
      ),
    ];
  }
}

class _DetailedRecommendationCard extends StatelessWidget {
  final int rank;
  final String cropName;
  final double? confidence;
  final String description;
  final bool isTopPick;
  final int total;

  const _DetailedRecommendationCard({
    required this.rank,
    required this.cropName,
    required this.confidence,
    required this.description,
    required this.isTopPick,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isTopPick
        ? AppColors.primary
        : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isTopPick ? 1.5 : 1,
        ),
        boxShadow: isTopPick
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isTopPick
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isTopPick ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatCropName(cropName),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isTopPick)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'BEST PICK',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (confidence != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: confidence! / 100,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            color: confidence! >= 70
                                ? AppColors.primary
                                : confidence! >= 50
                                    ? Colors.orange
                                    : Colors.grey,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${confidence!.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
                if (isTopPick) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text(
                          'Best suited for your current soil conditions',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

class _HeroBanner extends StatelessWidget {
  final String? farmName;
  final String? region;

  const _HeroBanner({this.farmName, this.region});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Your Personalized Results',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            farmName != null
                ? 'Recommendations for $farmName'
                : 'Based on your region and soil data',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
          if (region != null) ...[
            const SizedBox(height: 4),
            Text(
              'Region: $region',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceForecastCard extends StatelessWidget {
  final CropPriceForecast forecast;
  final String Function(String) trendIcon;
  final String Function(String) trendDescription;

  const _PriceForecastCard({
    required this.forecast,
    required this.trendIcon,
    required this.trendDescription,
  });

  @override
  Widget build(BuildContext context) {
    final trend = forecast.trend;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 18, color: Colors.amber),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Market Price Outlook',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trendIcon(trend),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _formatCropName(forecast.cropName),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ETB ${forecast.predictedPrice.toStringAsFixed(0)}/kg',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${trendDescription(trend)} (${forecast.trendPercentage >= 0 ? '+' : ''}${forecast.trendPercentage.toStringAsFixed(1)}%)',
            style: TextStyle(
              fontSize: 13,
              color: trend == 'increasing'
                  ? Colors.green
                  : trend == 'decreasing'
                      ? Colors.red
                      : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${forecast.region} - ${_monthName(forecast.month)} ${forecast.year}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatCropName(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _monthName(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return m >= 1 && m <= 12 ? names[m - 1] : '?';
  }
}
