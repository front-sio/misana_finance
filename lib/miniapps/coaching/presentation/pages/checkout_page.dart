import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../coaching_routes.dart';
import '../../data/models.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';

class CheckoutPage extends StatefulWidget {
  final Topic topic;
  final AvailabilitySlot slot;

  const CheckoutPage({super.key, required this.topic, required this.slot});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _duration = 15;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  double get _amount =>
      _duration == 15 ? widget.topic.price15 : widget.topic.price30;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('EEE, MMM d · HH:mm');
    final slotLabel =
        '${timeFmt.format(widget.slot.startAt)} - ${DateFormat('HH:mm').format(widget.slot.endAt)}';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), centerTitle: true),
      body: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingCreated) {
            Navigator.of(context).pushReplacementNamed(
              CoachingRoutes.payment,
              arguments: {
                'bookingId': state.booking.id,
                'phoneNumber': _phoneController.text.trim(),
              },
            );
          }
          if (state is BookingFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.topic.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    slotLabel,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose duration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildDurationTile(15, widget.topic.price15, scheme),
            _buildDurationTile(30, widget.topic.price30, scheme),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Phone number (for ClickPesa)',
                hintText: '2557xxxxxxxx',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inclusive of taxes/fees',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_amount.toStringAsFixed(0)} ${widget.topic.currency}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _phoneController.text.trim().isEmpty
                    ? null
                    : () {
                        context.read<BookingBloc>().add(
                          CreateBooking(
                            topicId: widget.topic.id,
                            slotId: widget.slot.id,
                            durationMinutes: _duration,
                          ),
                        );
                      },
                icon: const Icon(Icons.lock_clock),
                label: const Text('Confirm & Pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationTile(int minutes, double price, ColorScheme scheme) {
    final selected = _duration == minutes;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: RadioListTile<int>(
        value: minutes,
        groupValue: _duration,
        title: Text('$minutes minutes'),
        subtitle: Text('${price.toStringAsFixed(0)} ${widget.topic.currency}'),
        onChanged: (val) => setState(() => _duration = val ?? 15),
      ),
    );
  }
}
