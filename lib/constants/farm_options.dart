class FarmOption {
  final String value;
  final String label;

  const FarmOption({required this.value, required this.label});
}

const soilTypeOptions = [
  FarmOption(value: 'clay', label: 'Clay'),
  FarmOption(value: 'sandy', label: 'Sandy'),
  FarmOption(value: 'loam', label: 'Loam'),
  FarmOption(value: 'silt', label: 'Silt'),
  FarmOption(value: 'peaty', label: 'Peaty'),
  FarmOption(value: 'chalky', label: 'Chalky'),
  FarmOption(value: 'laterite', label: 'Laterite'),
];

const soilColorOptions = [
  FarmOption(value: 'black', label: 'Black'),
  FarmOption(value: 'red', label: 'Red'),
  FarmOption(value: 'brown', label: 'Brown'),
  FarmOption(value: 'gray', label: 'Gray'),
  FarmOption(value: 'yellowish', label: 'Yellowish'),
];

String labelForOption(List<FarmOption> options, String? value) {
  if (value == null || value.isEmpty) return '';
  return options
      .firstWhere(
        (o) => o.value == value,
        orElse: () => FarmOption(value: value, label: value),
      )
      .label;
}
