import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/api_service.dart';

class WithdrawScreen extends StatefulWidget {
  final String accountId;
  const WithdrawScreen({super.key, required this.accountId});

  @override
  WithdrawScreenState createState() => WithdrawScreenState();
}

class WithdrawScreenState extends State<WithdrawScreen> {
  int _currentStep = 0;
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  String? _selectedAccount;
  String? _selectedAccountId;
  bool _isLoading = false;

  List<Map<String, dynamic>> accounts = [];
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getAccounts();
      setState(() {
        accounts = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load accounts: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep += 1);
    } else {
      _confirmWithdraw();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _confirmWithdraw() async {
    final amount = _amountController.text.trim();
    final pin = _pinController.text.trim();

    if (amount.isEmpty || _selectedAccountId == null || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all steps")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First verify PIN
      final verified = await _api.verifyPin(pin);
      if (!verified) {
        throw Exception("Invalid PIN");
      }

      // Then withdraw
      final response = await _api.withdraw(
        _selectedAccountId!,
        int.parse(amount),
        "Withdrawal",
        pin,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Withdrawal successful: ${response['message'] ?? ''}")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    } finally {
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
        content: accounts.isEmpty
            ? const Text("No accounts available")
            : Column(
                children: accounts.map((acc) {
                  final display = "${acc['name'] ?? 'Account'} - ${acc['phone'] ?? ''}";
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: RadioListTile<String>(
                      value: display,
                      groupValue: _selectedAccount,
                      onChanged: (val) {
                        setState(() {
                          _selectedAccount = val;
                          _selectedAccountId = acc["id"].toString();
                        });
                      },
                      title: Text(acc["name"] ?? "Account",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(acc["phone"] ?? ""),
                      activeColor: Colors.blue.shade700,
                    ),
                  );
                }).toList(),
              ),
        isActive: _currentStep >= 1,
      ),
      Step(
        title: const Text("PIN"),
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
        title: const Text("Confirm"),
        content: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isLoading
              ? Center(
                  key: ValueKey("loader"),
                  child: Lottie.asset('assets/loader.json', width: 100, height: 100),
                )
              : Column(
                  key: const ValueKey("confirm"),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Amount: ${_amountController.text}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Account: ${_selectedAccount ?? ''}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text("PIN: ****",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text("Press 'Confirm' to complete the withdrawal."),
                  ],
                ),
        ),
        isActive: _currentStep >= 3,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Withdraw"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && accounts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              steps: _buildSteps(),
              onStepContinue: _isLoading ? null : _nextStep,
              onStepCancel: _isLoading ? null : _prevStep,
              controlsBuilder: (context, details) {
                return Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_currentStep == 3 ? "Confirm" : "Next"),
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
