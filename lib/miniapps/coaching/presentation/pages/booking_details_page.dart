import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../coaching_routes.dart';
import '../../data/models.dart';
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
      appBar: AppBar(title: const Text('Session Details')),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingLoading) {
            return const _LoadingView();
          }
          if (state is BookingFailure) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context.read<BookingBloc>().add(LoadBooking(widget.bookingId));
              },
            );
          }
          if (state is BookingLoaded || state is BookingCreated) {
            final booking = state is BookingLoaded
                ? state.booking
                : (state as BookingCreated).booking;
            return _BookingContent(booking: booking);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _BookingContent extends StatelessWidget {
  final Booking booking;

  const _BookingContent({required this.booking});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeFmt = DateFormat('h:mm a');
    final dateFmt = DateFormat('EEEE, d MMMM');
    final compactDateFmt = DateFormat('EEE, d MMM');
    final moneyFmt = NumberFormat('#,###', 'en_US');
    final dateLabel = dateFmt.format(booking.startAt);
    final timeLabel =
        '${timeFmt.format(booking.startAt)} - ${timeFmt.format(booking.endAt)}';
    final amountLabel = 'TZS ${moneyFmt.format(booking.amount)}';
    final statusMeta = _statusMeta(context, booking.status);
    final canJoin = booking.status == 'PAID';
    final nextStep = _nextStepMessage(booking.status);
    final supportCopy = _supportCopy(booking.status);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<BookingBloc>().add(LoadBooking(booking.id));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _HeroCard(
              booking: booking,
              dateLabel: dateLabel,
              timeLabel: timeLabel,
              amountLabel: amountLabel,
              statusMeta: statusMeta,
            ),
            const SizedBox(height: 16),
            _ActionCard(
              title: nextStep.title,
              body: nextStep.body,
              ctaLabel: _primaryActionLabel(booking.status),
              ctaEnabled: canJoin,
              onCtaPressed: canJoin
                  ? () {
                      Navigator.of(
                        context,
                      ).pushNamed(CoachingRoutes.call, arguments: booking.id);
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Session Summary',
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: dateLabel,
                  ),
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    label: 'Time',
                    value: timeLabel,
                  ),
                  _InfoRow(
                    icon: Icons.timelapse_outlined,
                    label: 'Duration',
                    value: '${booking.durationMinutes} minutes',
                  ),
                  _InfoRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Amount',
                    value: amountLabel,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Booking Status',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        statusMeta.icon,
                        color: statusMeta.textColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusMeta.label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    supportCopy,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniPill(
                        icon: Icons.tag_outlined,
                        text: booking.status.replaceAll('_', ' '),
                      ),
                      _MiniPill(
                        icon: Icons.event_available_outlined,
                        text: compactDateFmt.format(booking.startAt),
                      ),
                      _MiniPill(
                        icon: Icons.payments_outlined,
                        text: amountLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Before You Join',
              child: Column(
                children: const [
                  _TipRow(
                    icon: Icons.signal_cellular_alt_outlined,
                    title: 'Use stable data or Wi-Fi',
                    body:
                        'A stronger connection reduces dropouts during the call.',
                  ),
                  _TipRow(
                    icon: Icons.battery_charging_full_outlined,
                    title: 'Charge your phone first',
                    body: 'Low battery is a common reason sessions end early.',
                  ),
                  _TipRow(
                    icon: Icons.headset_mic_outlined,
                    title: 'Use earphones if possible',
                    body:
                        'Audio is usually clearer and easier to hear in busy spaces.',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Booking Reference',
              child: _InfoRow(
                icon: Icons.confirmation_number_outlined,
                label: 'Reference ID',
                value: booking.id,
                isLast: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Booking booking;
  final String dateLabel;
  final String timeLabel;
  final String amountLabel;
  final _StatusMeta statusMeta;

  const _HeroCard({
    required this.booking,
    required this.dateLabel,
    required this.timeLabel,
    required this.amountLabel,
    required this.statusMeta,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary.withValues(alpha: 0.86)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusMeta.icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  statusMeta.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            booking.topicTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your coaching session is scheduled and easy to track from here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(label: 'Date', value: dateLabel),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(label: 'Time', value: timeLabel),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Duration',
                  value: '${booking.durationMinutes} min',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(label: 'Amount', value: amountLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String body;
  final String ctaLabel;
  final bool ctaEnabled;
  final VoidCallback? onCtaPressed;

  const _ActionCard({
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.ctaEnabled,
    required this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: ctaEnabled ? onCtaPressed : null,
              icon: Icon(ctaEnabled ? Icons.call : Icons.lock_clock_outlined),
              label: Text(ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : scheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool isLast;

  const _TipRow({
    required this.icon,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? Colors.transparent : scheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(body, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading your session details...',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'This should only take a moment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
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
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'We could not load this booking.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMeta {
  final String label;
  final IconData icon;
  final Color textColor;

  const _StatusMeta({
    required this.label,
    required this.icon,
    required this.textColor,
  });
}

class _NextStepMessage {
  final String title;
  final String body;

  const _NextStepMessage({required this.title, required this.body});
}

_StatusMeta _statusMeta(BuildContext context, String status) {
  final scheme = Theme.of(context).colorScheme;
  switch (status) {
    case 'PAID':
      return _StatusMeta(
        label: 'Ready to join',
        icon: Icons.verified_outlined,
        textColor: Colors.green.shade700,
      );
    case 'COMPLETED':
      return _StatusMeta(
        label: 'Session completed',
        icon: Icons.check_circle_outline,
        textColor: Colors.green.shade700,
      );
    case 'PAYMENT_FAILED':
      return _StatusMeta(
        label: 'Payment failed',
        icon: Icons.error_outline,
        textColor: scheme.error,
      );
    case 'CANCELLED':
      return _StatusMeta(
        label: 'Session cancelled',
        icon: Icons.cancel_outlined,
        textColor: scheme.error,
      );
    case 'PENDING_PAYMENT':
    default:
      return _StatusMeta(
        label: 'Pending payment',
        icon: Icons.hourglass_top_outlined,
        textColor: scheme.primary,
      );
  }
}

_NextStepMessage _nextStepMessage(String status) {
  switch (status) {
    case 'PAID':
      return const _NextStepMessage(
        title: 'Everything is set',
        body:
            'Your booking is confirmed. When your session time opens, tap below to join the audio call.',
      );
    case 'COMPLETED':
      return const _NextStepMessage(
        title: 'Session already completed',
        body:
            'This booking has already been used. You can still review the details here for your records.',
      );
    case 'PAYMENT_FAILED':
      return const _NextStepMessage(
        title: 'Payment needs attention',
        body:
            'This booking was not confirmed because the payment did not complete successfully.',
      );
    case 'CANCELLED':
      return const _NextStepMessage(
        title: 'This session is no longer active',
        body:
            'The booking has been cancelled, so joining is not available from this page.',
      );
    case 'PENDING_PAYMENT':
    default:
      return const _NextStepMessage(
        title: 'Complete payment first',
        body:
            'Your session time is reserved, but joining stays locked until payment is confirmed.',
      );
  }
}

String _supportCopy(String status) {
  switch (status) {
    case 'PAID':
      return 'Keep this page handy on the day of your session. If the call does not open immediately, refresh and try again.';
    case 'COMPLETED':
      return 'The call window for this session has ended. Use the details below for reference.';
    case 'PAYMENT_FAILED':
      return 'Check your mobile money balance or network signal, then try the payment flow again from your bookings list.';
    case 'CANCELLED':
      return 'No further action is needed on this booking unless support asks for the reference ID below.';
    case 'PENDING_PAYMENT':
    default:
      return 'Payment confirmation can take a moment on mobile networks. Refresh this page after you complete payment.';
  }
}

String _primaryActionLabel(String status) {
  switch (status) {
    case 'PAID':
      return 'Join audio session';
    case 'COMPLETED':
      return 'Session closed';
    case 'PAYMENT_FAILED':
      return 'Payment not completed';
    case 'CANCELLED':
      return 'Session unavailable';
    case 'PENDING_PAYMENT':
    default:
      return 'Waiting for payment';
  }
}
