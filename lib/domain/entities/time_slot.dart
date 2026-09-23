enum SlotStatus { available, locked, booked }

class TimeSlot {
  final String id;
  final String date;
  final int courtNumber;
  final String startTime;
  final String endTime;
  final double price;
  final SlotStatus status;
  final String? lockedBy;
  final DateTime? lockedAt;

  final String? venueId;

  const TimeSlot({
    required this.id,
    required this.date,
    required this.courtNumber,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.status,
    this.lockedBy,
    this.lockedAt,
    this.venueId,
  });

  bool get isAvailable => status == SlotStatus.available;

  TimeSlot copyWith({
    String? id,
    String? date,
    int? courtNumber,
    String? startTime,
    String? endTime,
    double? price,
    SlotStatus? status,
    String? lockedBy,
    DateTime? lockedAt,
    String? venueId,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      date: date ?? this.date,
      courtNumber: courtNumber ?? this.courtNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      price: price ?? this.price,
      status: status ?? this.status,
      lockedBy: lockedBy ?? this.lockedBy,
      lockedAt: lockedAt ?? this.lockedAt,
      venueId: venueId ?? this.venueId,
    );
  }
}
