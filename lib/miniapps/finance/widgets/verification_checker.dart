import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/miniapps/finance/feature/kyc/presentation/bloc/kyc_bloc.dart';
import 'package:misana_finance_app/miniapps/finance/feature/kyc/presentation/bloc/kyc_event.dart';
import 'package:misana_finance_app/miniapps/finance/feature/kyc/presentation/bloc/kyc_state.dart';
import 'package:misana_finance_app/auth/session/auth_cubit.dart';

/// A widget that checks KYC verification status and shows appropriate UI
class VerificationChecker extends StatefulWidget {
  final Widget child;
  final Widget? unverifiedWidget;
  final bool showBanner;
  final String? customMessage;

  const VerificationChecker({
    super.key,
    required this.child,
    this.unverifiedWidget,
    this.showBanner = true,
    this.customMessage,
  });

  @override
  State<VerificationChecker> createState() => _VerificationCheckerState();
}

class _VerificationCheckerState extends State<VerificationChecker> {
  String? _userId;
  bool _checkedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVerification());
  }

  void _checkVerification() {
    final auth = context.read<AuthCubit>();
    final userId = (auth.state.user?['id'] ?? '').toString();
    
    if (userId.isNotEmpty && !_checkedOnce) {
      setState(() {
        _userId = userId;
        _checkedOnce = true;
      });
      // Force refresh of user profile first to get latest verification status
      auth.refreshProfile().then((_) {
        if (mounted) {
          // Then load KYC status
          context.read<KycBloc>().add(KycLoadStatus(userId: userId));
          // Only start polling if not already verified
          final kycState = context.read<KycBloc>().state;
          if (!kycState.isVerified) {
            context.read<KycBloc>().add(KycStartPolling(userId: userId));
          }
        }
      });
    }
  }

  @override
  void dispose() {
    if (_userId != null && _userId!.isNotEmpty) {
      context.read<KycBloc>().add(KycStopPolling());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KycBloc, KycState>(
      builder: (context, kycState) {
        final isVerified = kycState.isVerified;

        // If unverified and custom widget provided, show it
        if (!isVerified && widget.unverifiedWidget != null) {
          return widget.unverifiedWidget!;
        }

        // Show child with optional banner
        return Column(
          children: [
            if (!isVerified && widget.showBanner) _buildVerificationBanner(context, kycState),
            Expanded(child: widget.child),
          ],
        );
      },
    );
  }

  Widget _buildVerificationBanner(BuildContext context, KycState kycState) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String message;

    if (kycState.isPending || kycState.isProcessing) {
      bgColor = Colors.orange;
      textColor = Colors.white;
      icon = Icons.hourglass_empty;
      message = widget.customMessage ?? 'Uthibitisho unaendelea. Subiri kidogo...';
    } else if (kycState.isRejected) {
      bgColor = Colors.red;
      textColor = Colors.white;
      icon = Icons.error_outline;
      message = widget.customMessage ?? 'Uthibitisho umekataliwa. Tafadhali jaribu tena.';
    } else {
      bgColor = Colors.blue;
      textColor = Colors.white;
      icon = Icons.info_outline;
      message = widget.customMessage ?? 'Tafadhali thibitisha utambulisho wako ili kutumia huduma zote.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
          if (!kycState.isPending && !kycState.isProcessing)
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/kyc');
              },
              style: TextButton.styleFrom(
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: const Text('Thibitisha', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

/// Widget to block access for unverified users
class VerificationRequiredPage extends StatelessWidget {
  final String featureName;
  final String description;

  const VerificationRequiredPage({
    super.key,
    required this.featureName,
    this.description = 'Uthibitisho wa utambulisho unahitajika ili kufikia huduma hii.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(featureName),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                'Uthibitisho Unahitajika',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              BlocBuilder<KycBloc, KycState>(
                builder: (context, kycState) {
                  if (kycState.isPending || kycState.isProcessing) {
                    return Column(
                      children: [
                        CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Uthibitisho unaendelea...',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ],
                    );
                  }

                  return ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/kyc');
                    },
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Thibitisha Utambulisho'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
