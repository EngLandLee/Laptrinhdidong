import 'package:equatable/equatable.dart';
import '../../../domain/entities/time_slot.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingSlotsUpdated extends BookingState {
  final List<TimeSlot> selectedSlots;
  final double totalPrice;

  const BookingSlotsUpdated({
    required this.selectedSlots,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [selectedSlots, totalPrice];
}
