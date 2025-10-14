import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/api_service.dart';

class ChangePinScreen extends StatefulWidget {
  final bool hasPin; // true if user already has a PIN
  const ChangePinScreen({super.key, required this.hasPin});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();

  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitPin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PINs do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.hasPin) {
        // Call change PIN endpoint
        await api.changePin(
          oldPin: _oldPinController.text,
          newPin: _newPinController.text,
        );
      } else {
        // Call add PIN endpoint
        await api.addPin(
          newPin: _newPinController.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.hasPin
              ? "PIN changed successfully"
              : "PIN added successfully"),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hasPin ? "Change PIN" : "Add PIN"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Top Illustration Art (PNG/SVG instead of Lottie loader)
            SizedBox(
              height: 180,
              child: Image.asset(
                'assets/illustrations/pin_art.png', // <-- replace with your illustration asset
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (widget.hasPin)
                    TextFormField(
                      controller: _oldPinController,
                      decoration: const InputDecoration(
                        labelText: "Old PIN",
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val == null || val.isEmpty ? "Enter old PIN" : null,
                    ),
                  if (widget.hasPin) const SizedBox(height: 12),
                  TextFormField(
                    controller: _newPinController,
                    decoration: const InputDecoration(
                      labelText: "New PIN",
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.length < 4
                        ? "Enter 4+ digit PIN"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPinController,
                    decoration: const InputDecoration(
                      labelText: "Confirm New PIN",
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    validator: (val) =>
                        val == null || val.isEmpty ? "Confirm PIN" : null,
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? Lottie.asset(
                          'assets/loader.json', // 🔹 loader only when submitting
                          width: 80,
                          height: 80,
                        )
                      : ElevatedButton(
                          onPressed: _submitPin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.hasPin ? "Save New PIN" : "Add PIN",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
