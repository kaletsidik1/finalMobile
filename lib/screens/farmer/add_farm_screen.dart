import 'package:flutter/material.dart';

import '../../constants/farm_options.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/location_picker.dart';

class AddFarmScreen extends StatefulWidget {
  const AddFarmScreen({super.key});

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  final _api = ApiService();
  final _nameController = TextEditingController();
  final _kebeleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _soilType;
  String _soilColor = 'brown';
  String? _region;
  String? _woreda;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _kebeleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final result = await _api.createFarm({
      'name': _nameController.text.trim(),
      if (_soilType != null && _soilType!.isNotEmpty) 'soilType': _soilType,
      'soilColor': _soilColor,
      if (_region != null && _region!.isNotEmpty) 'region': _region,
      if (_woreda != null && _woreda!.isNotEmpty) 'woreda': _woreda,
      if (_kebeleController.text.trim().isNotEmpty)
        'kebele': _kebeleController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Farm saved successfully'),
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
        title: const Text('Add Farm'),
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
                'Tell us about your farm land.',
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
              CustomDropdown<String>(
                label: 'Soil Type',
                value: _soilType,
                hint: 'Select',
                items: soilTypeOptions.map((o) => o.value).toList(),
                itemLabel: (v) =>
                    labelForOption(soilTypeOptions, v),
                onChanged: (v) => setState(() => _soilType = v),
              ),
              CustomDropdown<String>(
                label: 'Soil Color',
                value: _soilColor,
                items: soilColorOptions.map((o) => o.value).toList(),
                itemLabel: (v) =>
                    labelForOption(soilColorOptions, v),
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
              const SizedBox(height: 8),
              CustomButton(
                text: 'Save Farm',
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
