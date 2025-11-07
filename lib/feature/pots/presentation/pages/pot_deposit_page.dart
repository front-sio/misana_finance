// lib/feature/pots/presentation/pages/pot_deposit_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/savings_progress.dart';
import '../bloc/pots_bloc.dart';
import '../bloc/pots_event.dart';
import '../bloc/pots_state.dart';

class PotDepositPage extends StatefulWidget {
  final String potId;
  final String potName;

  const PotDepositPage({
    super.key,
    required this.potId,
    required this.potName,
  });

  @override
  State<PotDepositPage> createState() => _PotDepositPageState();
}

class _PotDepositPageState extends State<PotDepositPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  FeeCalculation? _feePreview;
  bool _showFeePreview = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _calculateFee() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() {
        _feePreview = null;
        _showFeePreview = false;
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount != null && amount > 0) {
      setState(() {
        _feePreview = FeeCalculation.calculate(amount);
        _showFeePreview = true;
      });
    } else {
      setState(() {
        _feePreview = null;
        _showFeePreview = false;
      });
    }
  }

  Future<void> _confirmAndDeposit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_feePreview == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deposit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are depositing to: ${widget.potName}'),
            const SizedBox(height: 16),
            _buildFeeBreakdown(_feePreview!, isDialog: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Dispatch deposit event
    context.read<PotsBloc>().add(PotDeposit(
          potId: widget.potId,
          amount: _feePreview!.amount,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit Money'),
        elevation: 0,
      ),
      body: BlocListener<PotsBloc, PotsState>(
        listener: (context, state) {
          if (state is PotActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Deposited TZS ${_formatAmount(_feePreview!.netAmount)}',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is PotError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to deposit: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Pot Name Display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.savings,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Depositing to',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.potName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Amount Input
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (TZS) *',
                  hintText: 'Enter amount to deposit',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _calculateFee(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount < 1000) {
                    return 'Minimum deposit is TZS 1,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Note (Optional)
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'Add a note for this deposit',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
                maxLength: 300,
              ),
              const SizedBox(height: 24),

              // Fee Preview
              if (_showFeePreview && _feePreview != null) ...[
                _buildFeeBreakdown(_feePreview!),
                const SizedBox(height: 24),
              ],

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fees are automatically calculated and deducted from your deposit amount',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Deposit Button
              BlocBuilder<PotsBloc, PotsState>(
                builder: (context, state) {
                  final isLoading = state is PotLoading;
                  return ElevatedButton(
                    onPressed: _showFeePreview && !isLoading
                        ? _confirmAndDeposit
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _feePreview != null
                                ? 'Deposit TZS ${_formatAmount(_feePreview!.netAmount)}'
                                : 'Enter Amount',
                            style: const TextStyle(fontSize: 16),
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

  Widget _buildFeeBreakdown(FeeCalculation fee, {bool isDialog = false}) {
    return Card(
      elevation: isDialog ? 0 : 2,
      color: isDialog ? Colors.grey[50] : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDialog ? BorderSide(color: Colors.grey[300]!) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Fee Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildFeeRow('Gross Amount', fee.amount),
            const SizedBox(height: 8),
            _buildFeeRow(
              'Transaction Fee',
              fee.fee,
              subtitle:
                  '${fee.feePercentage}% + TZS ${_formatAmount(fee.fixedFee)}',
              isNegative: true,
            ),
            const Divider(height: 16),
            _buildFeeRow(
              'Net Amount',
              fee.netAmount,
              isBold: true,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(
    String label,
    double amount, {
    String? subtitle,
    bool isNegative = false,
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isBold ? 16 : 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          '${isNegative ? '- ' : ''}TZS ${_formatAmount(amount)}',
          style: TextStyle(
            fontSize: isBold ? 18 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? (isNegative ? Colors.red : Colors.black87),
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount.round());
  }
}
