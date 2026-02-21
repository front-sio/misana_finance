import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../coaching_routes.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';

class PaymentStatusPage extends StatefulWidget {
  final String bookingId;
  final String phoneNumber;

  const PaymentStatusPage({
    super.key,
    required this.bookingId,
    required this.phoneNumber,
  });

  @override
  State<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends State<PaymentStatusPage> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(
      StartPayment(
        bookingId: widget.bookingId,
        phoneNumber: widget.phoneNumber,
      ),
    );
  }

  @override
  void dispose() {
    context.read<PaymentBloc>().add(const StopPaymentPolling());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Status')),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            Navigator.of(context).pushReplacementNamed(
              CoachingRoutes.booking,
              arguments: state.booking.id,
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentInitiating) {
            return const _LoadingView(
              message: 'Initiating ClickPesa payment...',
            );
          }
          if (state is PaymentPending) {
            final order = state.payment.orderReference.isNotEmpty
                ? state.payment.orderReference
                : state.payment.transactionId;
            return _LoadingView(
              message: 'Waiting for payment confirmation...',
              detail: order.isNotEmpty ? 'Order: $order' : null,
            );
          }
          if (state is PaymentFailed) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context.read<PaymentBloc>().add(
                  StartPayment(
                    bookingId: widget.bookingId,
                    phoneNumber: widget.phoneNumber,
                  ),
                );
              },
            );
          }
          return const _LoadingView(message: 'Preparing payment...');
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final String message;
  final String? detail;

  const _LoadingView({required this.message, this.detail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(detail!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
