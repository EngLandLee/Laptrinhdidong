import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:sporthub/domain/entities/time_slot.dart';
import 'package:sporthub/presentation/blocs/booking/booking_bloc.dart';
import 'package:sporthub/presentation/blocs/booking/booking_event.dart';
import 'package:sporthub/presentation/blocs/booking/booking_state.dart';

void main() {
  group('BookingBloc', () {
    const slot1 = TimeSlot(
      id: 'slot_1',
      date: '2026-09-06',
      courtNumber: 1,
      startTime: '18:00',
      endTime: '19:00',
      price: 150000.0,
      status: SlotStatus.available,
    );

    const slot2 = TimeSlot(
      id: 'slot_2',
      date: '2026-09-06',
      courtNumber: 1,
      startTime: '19:00',
      endTime: '20:00',
      price: 150000.0,
      status: SlotStatus.available,
    );

    test('initial state is BookingInitial', () {
      expect(BookingBloc().state, isA<BookingInitial>());
    });

    blocTest<BookingBloc, BookingState>(
      'emits updated selected slots and total price when ToggleSlotEvent is added',
      build: () => BookingBloc(),
      act: (bloc) => bloc.add(const ToggleSlotEvent(slot1)),
      expect: () => [
        isA<BookingSlotsUpdated>()
            .having((s) => s.selectedSlots.length, 'selectedSlots length', 1)
            .having((s) => s.totalPrice, 'totalPrice', 150000.0),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'removes slot when ToggleSlotEvent is added for an already selected slot',
      build: () => BookingBloc(),
      act: (bloc) {
        bloc.add(const ToggleSlotEvent(slot1));
        bloc.add(const ToggleSlotEvent(slot2));
        bloc.add(const ToggleSlotEvent(slot1));
      },
      expect: () => [
        isA<BookingSlotsUpdated>()
            .having((s) => s.selectedSlots.length, 'selectedSlots length', 1)
            .having((s) => s.totalPrice, 'totalPrice', 150000.0),
        isA<BookingSlotsUpdated>()
            .having((s) => s.selectedSlots.length, 'selectedSlots length', 2)
            .having((s) => s.totalPrice, 'totalPrice', 300000.0),
        isA<BookingSlotsUpdated>()
            .having((s) => s.selectedSlots.length, 'selectedSlots length', 1)
            .having((s) => s.selectedSlots.first.id, 'remaining slot id', 'slot_2')
            .having((s) => s.totalPrice, 'totalPrice', 150000.0),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'clears all selected slots when ClearSelectedSlotsEvent is added',
      build: () => BookingBloc(),
      seed: () => const BookingSlotsUpdated(
        selectedSlots: [slot1, slot2],
        totalPrice: 300000.0,
      ),
      act: (bloc) => bloc.add(ClearSelectedSlotsEvent()),
      expect: () => [
        isA<BookingSlotsUpdated>()
            .having((s) => s.selectedSlots, 'selectedSlots', isEmpty)
            .having((s) => s.totalPrice, 'totalPrice', 0.0),
      ],
    );
  });
}
