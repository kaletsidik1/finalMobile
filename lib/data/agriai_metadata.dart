/// Local crop/region lists when using Mistral AI (no backend metadata endpoint).
class AgriAiMetadata {
  AgriAiMetadata._();

  static const crops = [
    'teff',
    'wheat',
    'maize',
    'barley',
    'sorghum',
    'coffee',
    'sesame',
    'chickpea',
    'faba bean',
    'potato',
  ];

  static const regions = [
    'Oromia',
    'Amhara',
    'SNNPR',
    'Tigray',
    'Sidama',
    'Afar',
    'Somali',
    'Benishangul-Gumuz',
    'Gambela',
    'Harari',
    'Addis Ababa',
  ];

  static Map<String, dynamic> toMap() => {
        'crops': crops,
        'regions': regions,
      };
}
