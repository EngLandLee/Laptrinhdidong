import 'package:equatable/equatable.dart';
import '../../../domain/entities/time_slot.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class ToggleSlotEvent extends BookingEvent {
  final TimeSlot slot;

  const ToggleSlotEvent(this.slot);

  @override
  List<Object?> get props => [slot];
}

class ClearSelectedSlotsEvent extends BookingEvent {
  const ClearSelectedSlotsEvent();
}
