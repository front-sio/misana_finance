import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DepositScreen extends StatefulWidget {
  final String accountId;

  const DepositScreen({super.key, required this.accountId});

  @override
  DepositScreenState createState() => DepositScreenState();
}

class DepositScreenState extends State<DepositScreen> {
  final ApiService api = ApiService();

  int _currentStep = 0;
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  String? _selectedAccountId;
  String? _selectedPaymentMethod;
  bool _isLoading = false;

  List<Map<String, dynamic>> _accounts = [];
  final List<String> _paymentMethods = ['M-Pesa', 'Tigo Pesa', 'Airtel Money'];

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.accountId;
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    try {
      final accounts = await api.getAccounts();
      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        if (!_accounts.any((acc) => acc['id'] == _selectedAccountId)) {
          _selectedAccountId =
              _accounts.isNotEmpty ? _accounts[0]['id'] : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load accounts: $e")),
      );
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep += 1);
    } else {
      _confirmDeposit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep -= 1);
  }

  Future<void> _confirmDeposit() async {
    final amountText = _amountController.text.trim();
    final pin = _pinController.text.trim();

    if (amountText.isEmpty ||
        _selectedAccountId == null ||
        pin.isEmpty ||
        _selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all steps")),
      );
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid amount")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Verify PIN
      final verified = await api.verifyPin(pin);
      if (!verified) throw Exception("Invalid PIN");

      // Step 2: Deposit
      await api.deposit(
        _selectedAccountId!,
        amount,
        "Deposit via $_selectedPaymentMethod",
        _selectedPaymentMethod!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Deposit of TZS $amount via $_selectedPaymentMethod successful!"),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deposit failed: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text("Amount"),
        content: TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Enter amount",
            prefixIcon: const Icon(Icons.money, color: Colors.blue),
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: const Text("Select Account"),
        content: _accounts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: _accounts.map((acc) {
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: RadioListTile<String>(
                      value: acc['id'],
                      groupValue: _selectedAccountId,
                      onChanged: (val) =>
                          setState(() => _selectedAccountId = val),
                      title: Text(acc['phone'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          'Balance: ${(acc['balance'] ?? 0).toStringAsFixed(2)} TZS'),
                      activeColor: Colors.blue.shade700,
                    ),
                  );
                }).toList(),
              ),
        isActive: _currentStep >= 1,
      ),
      Step(
        title: const Text("Enter PIN"),
        content: TextField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Enter PIN",
            prefixIcon: const Icon(Icons.lock, color: Colors.blue),
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        isActive: _currentStep >= 2,
      ),
      Step(
        title: const Text("Payment Method"),
        content: Column(
          children: _paymentMethods.map((method) {
            return RadioListTile<String>(
              value: method,
              groupValue: _selectedPaymentMethod,
              onChanged: (val) =>
                  setState(() => _selectedPaymentMethod = val),
              title: Text(method),
              activeColor: Colors.blue.shade700,
            );
          }).toList(),
        ),
        isActive: _currentStep >= 3,
      ),
      Step(
        title: const Text("Confirm"),
        content: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isLoading
              ? const Center(
                  key: ValueKey("loader"),
                  child: CircularProgressIndicator(color: Colors.blue),
                )
              : Column(
                  key: const ValueKey("confirm"),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Amount: ${_amountController.text} TZS",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        "Account: ${_accounts.firstWhere(
                                (a) => a['id'] == _selectedAccountId,
                                orElse: () => {'phone': 'Unknown'})['phone']}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Payment Method: $_selectedPaymentMethod",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text("PIN: ****",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text("Press 'Confirm' to complete the deposit."),
                  ],
                ),
        ),
        isActive: _currentStep >= 4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool confirmEnabled = !_isLoading &&
        _accounts.isNotEmpty &&
        _selectedAccountId != null &&
        _amountController.text.isNotEmpty &&
        _pinController.text.isNotEmpty &&
        _selectedPaymentMethod != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Deposit"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        steps: _buildSteps(),
        onStepContinue: _isLoading ? null : _nextStep,
        onStepCancel: _isLoading ? null : _prevStep,
        controlsBuilder: (context, details) {
          final isConfirmStep = _currentStep == 4;
          return Row(
            children: [
              ElevatedButton(
                onPressed: isConfirmStep && !confirmEnabled
                    ? null
                    : details.onStepContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isConfirmStep ? "Confirm" : "Next",
                    style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              if (_currentStep > 0 && !_isLoading)
                OutlinedButton(
                  onPressed: details.onStepCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    side: BorderSide(color: Colors.blue.shade700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Back"),
                ),
            ],
          );
        },
      ),
    );
  }
}
