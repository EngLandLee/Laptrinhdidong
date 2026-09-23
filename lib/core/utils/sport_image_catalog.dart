class SportImageCatalog {
  static const List<String> badmintonPresets = [
    'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', // Court with racquets
    'https://images.unsplash.com/photo-1599474924187-334a4ae5bd3c?w=800', // Court floor
    'https://images.unsplash.com/photo-1521537634581-0dced2fed2a8?w=800', // Badminton match
  ];

  static const List<String> pickleballPresets = [
    'https://images.unsplash.com/photo-1599474924187-334a4ae5bd3c?w=800', // Court surface
    'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800', // Outdoor court
    'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800', // Net and racquets
  ];

  static const List<String> footballPresets = [
    'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800', // Turf pitch
    'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800', // Soccer ball on turf
    'https://images.unsplash.com/photo-1518604667004-7472797e1272?w=800', // Match action
  ];

  static List<String> getPresetsForSport(String sport) {
    switch (sport.toLowerCase()) {
      case 'badminton':
        return badmintonPresets;
      case 'pickleball':
        return pickleballPresets;
      case 'football':
        return footballPresets;
      default:
        return badmintonPresets;
    }
  }

  static String getDefaultImageForSport(String sport) {
    final presets = getPresetsForSport(sport);
    return presets.first;
  }
}
