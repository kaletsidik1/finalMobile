import 'package:flutter/material.dart';
import '../../config/env_config.dart';
import '../../models/farm_model.dart';
import '../../services/api_service.dart';
import '../../services/mistral_ai_service.dart';
import '../../services/soil_climate_service.dart';
import '../../theme/app_theme.dart';

class FarmerChatScreen extends StatefulWidget {
  final String? defaultRegion;

  const FarmerChatScreen({super.key, this.defaultRegion});

  @override
  State<FarmerChatScreen> createState() => _FarmerChatScreenState();
}

class _FarmerChatScreenState extends State<FarmerChatScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage.assistant(
        EnvConfig.useMistralAi
            ? 'Hello! I\'m your AgriMarket farming assistant.\n\n'
                'Ask me about crops, soil, seasons, or markets in Ethiopia — '
                'or use the menu (☰) for detailed crop recommendations and price forecasts.'
            : 'Hello! I\'m your AgriMarket farming assistant.\n\n'
                'Add your Mistral API key in .env to enable chat answers. '
                'You can still use the menu (☰) for crop recommendations and price forecasts.',
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _addMessage(_ChatMessage message) {
    setState(() => _messages.add(message));
    _scrollToBottom();
  }

  List<Map<String, String>> _conversationHistory() {
    if (_messages.length <= 1) return [];

    final prior = _messages.sublist(0, _messages.length - 1);
    final history = prior
        .map(
          (m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.text,
          },
        )
        .toList();

    const maxMessages = 20;
    if (history.length > maxMessages) {
      return history.sublist(history.length - maxMessages);
    }
    return history;
  }

  Future<void> _sendUserText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _addMessage(_ChatMessage.user(trimmed));
    _inputController.clear();

    setState(() => _isTyping = true);

    try {
      if (!EnvConfig.useMistralAi) {
        _addMessage(
          _ChatMessage.assistant(
            'Chat replies need a Mistral API key.\n\n'
            'Add MISTRAL_API_KEY to your .env file and restart the app. '
            'You can still use the menu (☰) for crop recommendations and price forecasts.',
          ),
        );
        return;
      }

      final region = widget.defaultRegion?.trim();
      final reply = await MistralAiService().chat(
        userMessage: trimmed,
        history: _conversationHistory(),
        region: region != null && region.isNotEmpty ? region : null,
      );

      if (!mounted) return;
      _addMessage(_ChatMessage.assistant(reply.trim()));
    } catch (e) {
      if (!mounted) return;
      _addMessage(
        _ChatMessage.assistant(
          'Sorry, I could not answer that right now.\n'
          '${e.toString().replaceFirst('Exception: ', '')}',
        ),
      );
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  String _formatCropName(String raw) {
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Future<void> _runCropRecommendation(Map<String, dynamic> form) async {
    final summary = 'Crop recommendation request\n'
        'N: ${form['nitrogen']}, P: ${form['phosphorus']}, K: ${form['potassium']}\n'
        'Temp: ${form['temperature']}°C, Humidity: ${form['humidity']}%, '
        'pH: ${form['ph']}, Rainfall: ${form['rainfall']} mm';

    _addMessage(_ChatMessage.user(summary));
    setState(() => _isTyping = true);

    try {
      final data = await _api.recommendCrop(form);
      final recs = data['recommendations'] as List? ?? [];

      if (recs.isEmpty) {
        _addMessage(
          _ChatMessage.assistant('No recommendations were returned. Try different soil values.'),
        );
        return;
      }

      final buffer = StringBuffer('Here are your top crop recommendations:\n\n');
      for (var i = 0; i < recs.length; i++) {
        final item = recs[i] as Map<String, dynamic>;
        final crop = item['crop']?.toString() ?? 'Unknown';
        final confidence = item['confidence']?.toString() ?? '—';
        var confValue = double.tryParse(confidence) ?? 0;
        if (confValue > 0 && confValue <= 1) confValue *= 100;
        buffer.writeln(
          '${i + 1}. ${_formatCropName(crop)} — ${confValue.toStringAsFixed(0)}% match',
        );
      }
      buffer.write(
        '\nThese results are based on your soil nutrients, pH, and climate inputs.',
      );
      _addMessage(_ChatMessage.assistant(buffer.toString()));
    } catch (e) {
      _addMessage(
        _ChatMessage.assistant(
          'Sorry, I couldn\'t fetch crop recommendations.\n${e.toString().replaceFirst('Exception: ', '')}',
        ),
      );
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  Future<void> _runPriceForecast(Map<String, dynamic> form) async {
    final crop = form['crop_name'];
    final region = form['region'];
    final year = form['year'];
    final month = form['month'];

    _addMessage(
      _ChatMessage.user(
        'Price forecast for $crop in $region ($month/$year)',
      ),
    );
    setState(() => _isTyping = true);

    try {
      final data = await _api.predictPrice(form);
      final price = (data['predicted_price'] as num?)?.toDouble();
      final trend = data['trend']?.toString() ?? 'stable';
      final trendPct = (data['trend_percentage'] as num?)?.toDouble() ?? 0;
      final interval = data['confidence_interval'] as List?;

      final buffer = StringBuffer()
        ..writeln('Price forecast for ${data['crop_name'] ?? crop}')
        ..writeln('Region: ${data['region'] ?? region}')
        ..writeln('Period: ${data['month']}/${data['year']}')
        ..writeln()
        ..writeln(
          'Predicted price: ETB ${price?.toStringAsFixed(2) ?? '—'} per kg',
        )
        ..writeln('Trend: $trend (${trendPct >= 0 ? '+' : ''}${trendPct.toStringAsFixed(1)}%)');

      if (interval != null && interval.length >= 2) {
        final low = (interval[0] as num).toDouble();
        final high = (interval[1] as num).toDouble();
        buffer.writeln(
          'Confidence range: ETB ${low.toStringAsFixed(2)} – ${high.toStringAsFixed(2)}',
        );
      }

      _addMessage(_ChatMessage.assistant(buffer.toString()));
    } catch (e) {
      _addMessage(
        _ChatMessage.assistant(
          'Sorry, I couldn\'t fetch the price forecast.\n${e.toString().replaceFirst('Exception: ', '')}',
        ),
      );
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _showCropRecommendationSheet() {
    final _farms = <Farm>[];
    Farm? _selectedFarm;
    SoilClimateData? _soilData;
    bool _loadingFarms = true;
    bool _isFetchingSoil = false;
    bool fetchError = false;

    _api.getFarms().then((result) {
      if (result.success) {
        _farms.addAll(result.farms);
      }
      _loadingFarms = false;
    });

    void selectFarm(String? id) {
      final farm = id != null ? _farms.firstWhere((f) => f.id == id) : null;
      _selectedFarm = farm;
      _soilData = null;
      _isFetchingSoil = false;
      fetchError = false;

      if (farm == null) return;

      final lat = farm.latitude;
      final lng = farm.longitude;
      if (lat == null || lng == null) return;

      _isFetchingSoil = true;
      SoilClimateService.fetch(lat, lng).then((data) {
        _soilData = data;
        _isFetchingSoil = false;
        fetchError = data.error != null;
      });
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Get Crop Recommendation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select a farm land to get AI recommendations based on its soil data.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (_loadingFarms)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      )
                    else if (_farms.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No farms registered yet. Go to Farms tab to add one first.',
                                style: TextStyle(fontSize: 13, color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        value: _selectedFarm?.id,
                        decoration: InputDecoration(
                          labelText: 'Choose your farm land *',
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          hintText: 'Select a farm...',
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
                          prefixIcon: const Icon(Icons.agriculture_rounded, color: AppColors.primary),
                        ),
                        hint: const Text('Select a farm...'),
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
                        onChanged: (id) {
                          setSheetState(() => selectFarm(id));
                        },
                      ),
                      if (_selectedFarm != null && _isFetchingSoil) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
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
                                'Fetching soil & climate data...',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_selectedFarm != null && _soilData != null) ...[
                        const SizedBox(height: 12),
                        _ChatSoilDataCard(farm: _selectedFarm!, data: _soilData!),
                      ],
                      if (_selectedFarm != null && fetchError) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Could not fetch live data. Using default values.',
                                  style: TextStyle(fontSize: 12, color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _selectedFarm == null || _isFetchingSoil
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _runCropRecommendation({
                                  'nitrogen': _soilData?.nitrogen?.toInt() ?? 50,
                                  'phosphorus': _soilData?.phosphorus?.toInt() ?? 30,
                                  'potassium': _soilData?.potassium?.toInt() ?? 20,
                                  'temperature': _soilData?.temperature ?? 25,
                                  'humidity': _soilData?.humidity ?? 60,
                                  'ph': _soilData?.ph ?? 6.5,
                                  'rainfall': _soilData?.rainfall ?? 100,
                                  'soil_color': _selectedFarm?.soilColor ?? 'brown',
                                });
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Get Recommendation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPriceForecastSheet() async {
    List<String> crops = [];
    List<String> regions = [];
    String? selectedCrop;
    String? selectedRegion;
    var year = DateTime.now().year;
    var month = DateTime.now().month;
    var loadingMeta = true;
    String? metaError;

    try {
      final meta = await _api.getPriceForecasterMetadata();
      crops = (meta['crops'] as List?)?.map((e) => e.toString()).toList() ?? [];
      regions = (meta['regions'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (crops.isNotEmpty) selectedCrop = crops.first;
      final defaultRegion = widget.defaultRegion?.trim();
      if (defaultRegion != null &&
          defaultRegion.isNotEmpty &&
          regions.contains(defaultRegion)) {
        selectedRegion = defaultRegion;
      } else if (regions.isNotEmpty) {
        selectedRegion = regions.first;
      }
    } catch (e) {
      metaError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loadingMeta = false;
    }

    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Get Price Forecast',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Predict market prices using historical trends.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (loadingMeta)
                      const Center(child: CircularProgressIndicator())
                    else if (metaError != null)
                      Text(metaError!, style: const TextStyle(color: AppColors.error))
                    else ...[
                      DropdownButtonFormField<String>(
                        value: selectedCrop,
                        decoration: _inputDecoration('Crop'),
                        items: crops
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setSheetState(() => selectedCrop = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedRegion,
                        decoration: _inputDecoration('Region'),
                        items: regions
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setSheetState(() => selectedRegion = v),
                      ),
                      const SizedBox(height: 12),
                      _FormRow(
                        children: [
                          DropdownButtonFormField<int>(
                            value: month,
                            decoration: _inputDecoration('Month'),
                            items: List.generate(
                              12,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text(_monthName(i + 1)),
                              ),
                            ),
                            onChanged: (v) {
                              if (v != null) setSheetState(() => month = v);
                            },
                          ),
                          DropdownButtonFormField<int>(
                            value: year,
                            decoration: _inputDecoration('Year'),
                            items: List.generate(
                              5,
                              (i) {
                                final y = DateTime.now().year + i;
                                return DropdownMenuItem(value: y, child: Text('$y'));
                              },
                            ),
                            onChanged: (v) {
                              if (v != null) setSheetState(() => year = v);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: selectedCrop == null || selectedRegion == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _runPriceForecast({
                                  'crop_name': selectedCrop,
                                  'region': selectedRegion,
                                  'year': year,
                                  'month': month,
                                });
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Get Forecast'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'crop':
        _showCropRecommendationSheet();
        break;
      case 'price':
        _showPriceForecastSheet();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _ChatAppBar(onMenuSelected: _onMenuSelected),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return const _TypingIndicator();
                  }
                  return _MessageBubble(message: _messages[index]);
                },
              ),
            ),
            _ChatInputBar(
              controller: _inputController,
              enabled: !_isTyping,
              onSend: () => _sendUserText(_inputController.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget {
  final void Function(String value) onMenuSelected;

  const _ChatAppBar({required this.onMenuSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AgriMarket AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Farming assistant',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            tooltip: 'Menu',
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'crop',
                child: Row(
                  children: [
                    Icon(Icons.grass_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 12),
                    Text('Get Crop Recommendation'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'price',
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 12),
                    Text('Get Price Forecast'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const SizedBox(
            width: 32,
            height: 16,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: enabled ? (_) => onSend() : null,
              decoration: InputDecoration(
                hintText: 'Message AgriMarket AI...',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: enabled ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: enabled ? onSend : null,
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;

  const _ChatMessage({required this.isUser, required this.text});

  factory _ChatMessage.user(String text) => _ChatMessage(isUser: true, text: text);
  factory _ChatMessage.assistant(String text) =>
      _ChatMessage(isUser: false, text: text);
}

class _ChatSoilDataCard extends StatelessWidget {
  final Farm farm;
  final SoilClimateData data;

  const _ChatSoilDataCard({required this.farm, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  farm.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
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
          const SizedBox(height: 12),
          _dataRow('Nitrogen (N)', data.nitrogen, 'mg/kg'),
          _dataRow('pH Level', data.ph, ''),
          _dataRow('Temperature', data.temperature, '\u00b0C'),
          _dataRow('Humidity', data.humidity, '%'),
          _dataRow('Rainfall', data.rainfall, 'mm'),
          if (farm.soilType != null && farm.soilType!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.layers_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Soil: ${farm.soilType!.substring(0, 1).toUpperCase()}${farm.soilType!.substring(1)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, double? value, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
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
}

class _FormRow extends StatelessWidget {
  final List<Widget> children;

  const _FormRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _NumberField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(label),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 13),
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );
}

String _monthName(int month) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return names[month - 1];
}
