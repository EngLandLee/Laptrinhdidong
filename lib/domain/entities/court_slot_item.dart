enum CourtSlotStatus {
  available,
  bookedApp,
  reservedManual,
  maintenance,
}

class CourtSlotItem {
  final String slotId;
  final String courtName;
  final String sportType;
  final String timeRange;
  final CourtSlotStatus status;
  final String? customerName;
  final String? customerPhone;
  final String? ticketId;
  final double price;

  const CourtSlotItem({
    required this.slotId,
    required this.courtName,
    required this.sportType,
    required this.timeRange,
    required this.status,
    this.customerName,
    this.customerPhone,
    this.ticketId,
    required this.price,
  });

  int get startHour {
    final parts = timeRange.split(':');
    return parts.isNotEmpty ? (int.tryParse(parts[0].trim()) ?? 0) : 0;
  }

  bool get isPeakHour => startHour >= 17 && startHour < 21;
  bool get isOffPeakHour => startHour >= 8 && startHour < 16;

  CourtSlotItem copyWith({
    String? slotId,
    String? courtName,
    String? sportType,
    String? timeRange,
    CourtSlotStatus? status,
    String? customerName,
    String? customerPhone,
    String? ticketId,
    double? price,
    bool clearCustomer = false,
  }) {
    return CourtSlotItem(
      slotId: slotId ?? this.slotId,
      courtName: courtName ?? this.courtName,
      sportType: sportType ?? this.sportType,
      timeRange: timeRange ?? this.timeRange,
      status: status ?? this.status,
      customerName: clearCustomer ? null : (customerName ?? this.customerName),
      customerPhone: clearCustomer ? null : (customerPhone ?? this.customerPhone),
      ticketId: clearCustomer ? null : (ticketId ?? this.ticketId),
      price: price ?? this.price,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourtSlotItem &&
          runtimeType == other.runtimeType &&
          slotId == other.slotId &&
          courtName == other.courtName &&
          sportType == other.sportType &&
          timeRange == other.timeRange &&
          status == other.status &&
          customerName == other.customerName &&
          customerPhone == other.customerPhone &&
          ticketId == other.ticketId &&
          price == other.price;

  @override
  int get hashCode =>
      slotId.hashCode ^
      courtName.hashCode ^
      sportType.hashCode ^
      timeRange.hashCode ^
      status.hashCode ^
      customerName.hashCode ^
      customerPhone.hashCode ^
      ticketId.hashCode ^
      price.hashCode;
}
