import 'package:intl/intl.dart';
import '../../domain/entities/time_slot.dart';

class TimeSlotModel extends TimeSlot {
  const TimeSlotModel({
    required super.id,
    required super.date,
    required super.courtNumber,
    required super.startTime,
    required super.endTime,
    required super.price,
    required super.status,
    super.lockedBy,
    super.lockedAt,
  });

  String get formattedPrice {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)} đ';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'courtNumber': courtNumber,
      'startTime': startTime,
      'endTime': endTime,
      'price': price,
      'status': status.name,
      'lockedBy': lockedBy,
      'lockedAt': lockedAt?.toIso8601String(),
    };
  }

  factory TimeSlotModel.fromMap(Map<String, dynamic> map, String id) {
    return TimeSlotModel(
      id: id,
      date: map['date'] as String,
      courtNumber: map['courtNumber'] as int,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      price: (map['price'] as num).toDouble(),
      status: SlotStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SlotStatus.available,
      ),
      lockedBy: map['lockedBy'] as String?,
      lockedAt: map['lockedAt'] != null ? DateTime.tryParse(map['lockedAt']) : null,
    );
  }
}
