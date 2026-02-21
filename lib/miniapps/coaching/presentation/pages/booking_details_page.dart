import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../coaching_routes.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<BookingBloc>().add(LoadBooking(widget.bookingId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BookingFailure) {
            return Center(child: Text(state.message));
          }
          if (state is BookingLoaded || state is BookingCreated) {
            final booking = state is BookingLoaded
                ? state.booking
                : (state as BookingCreated).booking;
            final dateFmt = DateFormat('EEE, MMM d · HH:mm');
            final slotText =
                '${dateFmt.format(booking.startAt)} - ${DateFormat('HH:mm').format(booking.endAt)}';
            final isPaid = booking.status == 'PAID';

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.topicTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${booking.status}'),
                  const SizedBox(height: 8),
                  Text('Slot: $slotText'),
                  const SizedBox(height: 8),
                  Text('Duration: ${booking.durationMinutes} minutes'),
                  const SizedBox(height: 8),
                  Text('Amount: ${booking.amount.toStringAsFixed(0)}'),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isPaid
                          ? () {
                              Navigator.of(context).pushNamed(
                                CoachingRoutes.call,
                                arguments: booking.id,
                              );
                            }
                          : null,
                      child: const Text('Join Audio Call'),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
