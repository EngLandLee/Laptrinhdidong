class SportZone {
  final String zoneId;
  final String sportType;
  final String zoneName;
  final String facilityDescription;
  final String badgeText;
  final List<int> courtNumbers;
  final String priceRangeDisplay;

  const SportZone({
    required this.zoneId,
    required this.sportType,
    required this.zoneName,
    required this.facilityDescription,
    required this.badgeText,
    required this.courtNumbers,
    required this.priceRangeDisplay,
  });
}
