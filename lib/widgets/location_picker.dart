import 'package:flutter/material.dart';
import '../models/location_model.dart';

class LocationPicker extends StatelessWidget {
  final String? selectedRegion;
  final String? selectedWoreda;
  final Function(String?) onRegionChanged;
  final Function(String?) onWoredaChanged;

  const LocationPicker({
    super.key,
    required this.selectedRegion,
    required this.selectedWoreda,
    required this.onRegionChanged,
    required this.onWoredaChanged,
  });

  List<String> get woredasForSelectedRegion {
    if (selectedRegion == null) return [];
    final region = ethiopianRegions.firstWhere(
      (r) => r.name == selectedRegion,
      orElse: () => Region(name: '', woredas: []),
    );
    return region.woredas;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Region Dropdown
        DropdownButtonFormField<String>(
          initialValue: selectedRegion,
          hint: const Text('Select Region'),
          items: ethiopianRegions.map((region) {
            return DropdownMenuItem(
              value: region.name,
              child: Text(region.name),
            );
          }).toList(),
          onChanged: onRegionChanged,
          decoration: InputDecoration(
            labelText: 'Region',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Woreda Dropdown
        DropdownButtonFormField<String>(
          initialValue: selectedWoreda,
          hint: const Text('Select Woreda'),
          items: woredasForSelectedRegion.map((woreda) {
            return DropdownMenuItem(
              value: woreda,
              child: Text(woreda),
            );
          }).toList(),
          onChanged: selectedRegion != null ? onWoredaChanged : null,
          decoration: InputDecoration(
            labelText: 'Woreda',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}