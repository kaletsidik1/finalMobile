import 'package:flutter/material.dart';

import '../../constants/farm_options.dart';
import '../../models/farm_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/location_picker.dart';

class AddFarmScreen extends StatefulWidget {
  final Farm? farm;

  const AddFarmScreen({super.key, this.farm});

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  final _api = ApiService();
  final _nameController = TextEditingController();
  final _kebeleController = TextEditingController();
  final _nitrogenCtrl = TextEditingController();
  final _phosphorusCtrl = TextEditingController();
  final _potassiumCtrl = TextEditingController();
  final _phCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _humidityCtrl = TextEditingController();
  final _rainfallCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _soilType;
  String _soilColor = 'brown';
  String? _region;
  String? _woreda;
  bool _isSaving = false;

  bool get _isEditing => widget.farm != null;

  @override
  void initState() {
    super.initState();
    final f = widget.farm;
    if (f != null) {
      _nameController.text = f.name;
      _kebeleController.text = f.kebele ?? '';
      _soilType = f.soilType;
      _soilColor = f.soilColor ?? 'brown';
      _region = f.region;
      _woreda = f.woreda;
      _nitrogenCtrl.text = f.nitrogen?.toString() ?? '';
      _phosphorusCtrl.text = f.phosphorus?.toString() ?? '';
      _potassiumCtrl.text = f.potassium?.toString() ?? '';
      _phCtrl.text = f.ph?.toString() ?? '';
      _tempCtrl.text = f.temperature?.toString() ?? '';
      _humidityCtrl.text = f.humidity?.toString() ?? '';
      _rainfallCtrl.text = f.rainfall?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kebeleController.dispose();
    _nitrogenCtrl.dispose();
    _phosphorusCtrl.dispose();
    _potassiumCtrl.dispose();
    _phCtrl.dispose();
    _tempCtrl.dispose();
    _humidityCtrl.dispose();
    _rainfallCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      if (_soilType != null && _soilType!.isNotEmpty) 'soilType': _soilType,
      'soilColor': _soilColor,
      if (_region != null && _region!.isNotEmpty) 'region': _region,
      if (_woreda != null && _woreda!.isNotEmpty) 'woreda': _woreda,
      if (_kebeleController.text.trim().isNotEmpty)
        'kebele': _kebeleController.text.trim(),
      if (_nitrogenCtrl.text.trim().isNotEmpty)
        'nitrogen': double.tryParse(_nitrogenCtrl.text.trim()) ?? 0,
      if (_phosphorusCtrl.text.trim().isNotEmpty)
        'phosphorus': double.tryParse(_phosphorusCtrl.text.trim()) ?? 0,
      if (_potassiumCtrl.text.trim().isNotEmpty)
        'potassium': double.tryParse(_potassiumCtrl.text.trim()) ?? 0,
      if (_phCtrl.text.trim().isNotEmpty)
        'ph': double.tryParse(_phCtrl.text.trim()) ?? 0,
      if (_tempCtrl.text.trim().isNotEmpty)
        'temperature': double.tryParse(_tempCtrl.text.trim()) ?? 0,
      if (_humidityCtrl.text.trim().isNotEmpty)
        'humidity': double.tryParse(_humidityCtrl.text.trim()) ?? 0,
      if (_rainfallCtrl.text.trim().isNotEmpty)
        'rainfall': double.tryParse(_rainfallCtrl.text.trim()) ?? 0,
    };

    final FarmMutationResult result;
    if (_isEditing) {
      result = await _api.updateFarm(widget.farm!.id, payload);
    } else {
      result = await _api.createFarm(payload);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (_isEditing ? 'Farm updated' : 'Farm saved')),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? 'Failed to save farm'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Farm' : 'Add Farm'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                _isEditing
                    ? 'Update your farm land details.'
                    : 'Tell us about your farm land.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Farm Name *',
                hint: 'e.g. North Field, Riverside Plot',
                controller: _nameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Farm name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Soil & Location',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              CustomDropdown<String>(
                label: 'Soil Type',
                value: _soilType,
                hint: 'Select',
                items: soilTypeOptions.map((o) => o.value).toList(),
                itemLabel: (v) => labelForOption(soilTypeOptions, v),
                onChanged: (v) => setState(() => _soilType = v),
              ),
              CustomDropdown<String>(
                label: 'Soil Color',
                value: _soilColor,
                items: soilColorOptions.map((o) => o.value).toList(),
                itemLabel: (v) => labelForOption(soilColorOptions, v),
                onChanged: (v) {
                  if (v != null) setState(() => _soilColor = v);
                },
              ),
              LocationPicker(
                selectedRegion: _region,
                selectedWoreda: _woreda,
                onRegionChanged: (region) {
                  setState(() {
                    _region = region;
                    _woreda = null;
                  });
                },
                onWoredaChanged: (woreda) {
                  setState(() => _woreda = woreda);
                },
              ),
              if (_region == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Select region first to choose a woreda',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              CustomTextField(
                label: 'Kebele (optional)',
                hint: 'e.g. Kebele 01',
                controller: _kebeleController,
              ),
              const SizedBox(height: 16),
              const Text(
                'Soil Chemistry (optional)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Used for accurate AI crop recommendations.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Nitrogen (N)',
                      hint: 'mg/kg',
                      controller: _nitrogenCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Phosphorus (P)',
                      hint: 'mg/kg',
                      controller: _phosphorusCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Potassium (K)',
                      hint: 'mg/kg',
                      controller: _potassiumCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'pH',
                      hint: '0-14',
                      controller: _phCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Temp (°C)',
                      hint: 'e.g. 25',
                      controller: _tempCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Humidity (%)',
                      hint: 'e.g. 60',
                      controller: _humidityCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Rainfall (mm)',
                hint: 'e.g. 100',
                controller: _rainfallCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: _isEditing ? 'Update Farm' : 'Save Farm',
                isLoading: _isSaving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
