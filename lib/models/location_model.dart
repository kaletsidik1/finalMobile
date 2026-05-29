class Region {
  final String name;
  final List<String> woredas;

  Region({required this.name, required this.woredas});
}

// Ethiopian regions data
final List<Region> ethiopianRegions = [
  Region(
    name: 'Addis Ababa',
    woredas: ['Addis Ketema', 'Akaky Kaliti', 'Arada', 'Bole', 'Gullele', 'Kirkos', 'Kolfe Keranio', 'Lideta', 'Nifas Silk-Lafto', 'Yeka'],
  ),
  Region(
    name: 'Amhara',
    woredas: ['Bahir Dar', 'Gondar', 'Dessie', 'Debre Markos', 'Debre Birhan', 'Weldiya', 'Kombolcha', 'Finote Selam'],
  ),
  Region(
    name: 'Oromia',
    woredas: ['Adama', 'Jimma', 'Bishoftu', 'Shashamane', 'Ambo', 'Nekemte', 'Bale Robe', 'Assela'],
  ),
  Region(
    name: 'Tigray',
    woredas: ['Mekelle', 'Adigrat', 'Axum', 'Shire', 'Adwa', 'Humera'],
  ),
  Region(
    name: 'Sidama',
    woredas: ['Hawassa', 'Yirgalem', 'Aleta Wondo', 'Bensa', 'Chuko'],
  ),
  Region(
    name: 'SNNPR',
    woredas: ['Arba Minch', 'Sodo', 'Dilla', 'Hossana', 'Wolaita Sodo', 'Jinka'],
  ),
  Region(
    name: 'Harari',
    woredas: ['Harar', 'Dire Teyara', 'Amir Nur'],
  ),
  Region(
    name: 'Somali',
    woredas: ['Jijiga', 'Gode', 'Kelafo', 'Degehabur', 'Warder'],
  ),
  Region(
    name: 'Afar',
    woredas: ['Semera', 'Asayita', 'Awash', 'Dubti', 'Erebti'],
  ),
  Region(
    name: 'Benishangul-Gumuz',
    woredas: ['Asosa', 'Bambasi', 'Menge', 'Kemashi', 'Sherkole'],
  ),
  Region(
    name: 'Gambella',
    woredas: ['Gambella', 'Itang', 'Abobo', 'Gog', 'Jor'],
  ),
  Region(
    name: 'Dire Dawa',
    woredas: ['Dire Dawa', 'Gurgura', 'Shinile'],
  ),
];