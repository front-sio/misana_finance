import 'package:flutter/material.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/feature/home/presentation/widgets/status_pill.dart';
import 'package:misana_finance_app/feature/home/presentation/widgets/animated_amount.dart';

class AccountHeader extends StatelessWidget {
  final String accountNumber;
  final String status;
  final double balance;
  final bool showBalance;
  final VoidCallback onToggleBalance;
  final String userName;
  final List<Widget> actions;

  const AccountHeader({
    super.key,
    required this.accountNumber,
    required this.status,
    required this.balance,
    required this.showBalance,
    required this.onToggleBalance,
    required this.userName,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 28),
      decoration: const BoxDecoration(
        color: BrandColors.orange,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome,',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(status: status),
              const SizedBox(width: 12),
              _buildBalanceToggle(),
            ],
          ),
          const SizedBox(height: 18),
          _buildBalanceRow(),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceToggle() {
    return InkWell(
      onTap: onToggleBalance,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Icon(
          showBalance ? Icons.visibility : Icons.visibility_off,
          key: ValueKey(showBalance),
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildBalanceRow() {
    return Row(
      children: [
        const Text(
          'Balance: ',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: showBalance
              ? AnimatedAmount(
                  key: ValueKey(balance),
                  value: balance,
                )
              : Container(
                  key: const ValueKey('hidden'),
                  width: 70,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
        ),
      ],
    );
  }
}