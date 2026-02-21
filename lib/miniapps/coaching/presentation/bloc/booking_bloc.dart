import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/coaching_repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final CoachingRepository repo;

  BookingBloc(this.repo) : super(const BookingInitial()) {
    on<CreateBooking>(_onCreateBooking);
    on<LoadBooking>(_onLoadBooking);
  }

  Future<void> _onCreateBooking(CreateBooking event, Emitter<BookingState> emit) async {
    emit(const BookingLoading());
    try {
      final booking = await repo.createBooking(
        topicId: event.topicId,
        slotId: event.slotId,
        durationMinutes: event.durationMinutes,
      );
      emit(BookingCreated(booking));
    } catch (e) {
      emit(BookingFailure(e.toString()));
    }
  }

  Future<void> _onLoadBooking(LoadBooking event, Emitter<BookingState> emit) async {
    emit(const BookingLoading());
    try {
      final booking = await repo.getBooking(event.bookingId);
      emit(BookingLoaded(booking));
    } catch (e) {
      emit(BookingFailure(e.toString()));
    }
  }
}
