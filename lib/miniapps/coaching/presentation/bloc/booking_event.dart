import 'package:equatable/equatable.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class CreateBooking extends BookingEvent {
  final String topicId;
  final String slotId;
  final int durationMinutes;

  const CreateBooking({
    required this.topicId,
    required this.slotId,
    required this.durationMinutes,
  });

  @override
  List<Object?> get props => [topicId, slotId, durationMinutes];
}

class LoadBooking extends BookingEvent {
  final String bookingId;
  const LoadBooking(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}
