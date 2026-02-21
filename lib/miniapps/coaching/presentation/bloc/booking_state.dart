import 'package:equatable/equatable.dart';
import '../../data/models.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoading extends BookingState {
  const BookingLoading();
}

class BookingCreated extends BookingState {
  final Booking booking;
  const BookingCreated(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingLoaded extends BookingState {
  final Booking booking;
  const BookingLoaded(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingFailure extends BookingState {
  final String message;
  const BookingFailure(this.message);

  @override
  List<Object?> get props => [message];
}
