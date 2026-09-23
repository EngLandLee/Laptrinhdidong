enum AddonCategory { rental, beverage, gear }

class VenueAddonItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String unit;
  final AddonCategory category;
  final String icon;
  final List<String> sportTypes;

  const VenueAddonItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.category,
    required this.icon,
    this.sportTypes = const ['all'],
  });
}
