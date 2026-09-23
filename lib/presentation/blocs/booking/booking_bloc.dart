import 'package:flutter_bloc/flutter_bloc.dart';
import 'booking_event.dart';
import 'booking_state.dart';
import '../../../domain/entities/time_slot.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc() : super(const BookingInitial()) {
    on<ToggleSlotEvent>(_onToggleSlot);
    on<ClearSelectedSlotsEvent>(_onClearSlots);
  }

  void _onToggleSlot(ToggleSlotEvent event, Emitter<BookingState> emit) {
    final currentSlots = state is BookingSlotsUpdated
        ? List<TimeSlot>.from((state as BookingSlotsUpdated).selectedSlots)
        : <TimeSlot>[];

    final exists = currentSlots.any((s) => s.id == event.slot.id);
    if (exists) {
      currentSlots.removeWhere((s) => s.id == event.slot.id);
    } else {
      currentSlots.add(event.slot);
    }

    final total = currentSlots.fold<double>(0.0, (sum, item) => sum + item.price);
    emit(BookingSlotsUpdated(selectedSlots: currentSlots, totalPrice: total));
  }

  void _onClearSlots(ClearSelectedSlotsEvent event, Emitter<BookingState> emit) {
    emit(const BookingSlotsUpdated(selectedSlots: [], totalPrice: 0.0));
  }
}
