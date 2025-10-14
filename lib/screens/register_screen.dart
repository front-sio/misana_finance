import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  String? gender;
  DateTime? dob;
  String countryCode = "255"; // default Tanzania
  bool acceptedTerms = false;
  bool isLoading = false;

  // Date picker for DOB
  Future<void> _pickDOB() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) setState(() => dob = picked);
  }

  // Normalize phone for backend
  String _normalizePhone(String phone) {
    phone = phone.trim();
    if (phone.startsWith('+')) phone = phone.substring(1);
    if (phone.startsWith('0')) phone = countryCode + phone.substring(1);
    return phone;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (gender == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select your gender")));
      return;
    }
    if (dob == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Pick your DOB")));
      return;
    }
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Accept terms & privacy policy")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final phoneNormalized = _normalizePhone(phoneCtrl.text);
      final user = await api.register({
        "name": nameCtrl.text.trim(),
        "phone": phoneNormalized,
        "email": emailCtrl.text.trim(),
        "username": usernameCtrl.text.trim(),
        "password": passwordCtrl.text.trim(),
        "gender": gender,
        "dob": DateFormat("yyyy-MM-dd").format(dob!),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Registration successful! Please login.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Registration failed: $e")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Icon(Icons.savings, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                const Text(
                  "Create Account",
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Fill in the details below to get started",
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 35),

                _buildField(nameCtrl, "Full Name", Icons.person,
                    validator: (v) => v!.isEmpty ? "Enter your name" : null),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButton<String>(
                        value: countryCode,
                        items: const [
                          DropdownMenuItem(value: "255", child: Text("+255")),
                          DropdownMenuItem(value: "256", child: Text("+256")),
                          DropdownMenuItem(value: "254", child: Text("+254")),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => countryCode = v);
                        },
                        underline: const SizedBox(),
                        dropdownColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(phoneCtrl, "Phone", Icons.phone,
                          keyboard: TextInputType.phone,
                          validator: (v) => v!.isEmpty ? "Enter phone number" : null),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildField(usernameCtrl, "Username", Icons.person,
                    keyboard: TextInputType.text,
                    validator: (v) => v!.isEmpty ? "Enter username" : null),
                const SizedBox(height: 16),

                _buildField(emailCtrl, "Email", Icons.email,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) => v!.contains("@") ? null : "Enter valid email"),
                const SizedBox(height: 16),


                _buildField(passwordCtrl, "Password", Icons.lock,
                    obscure: true,
                    validator: (v) =>
                        v!.length < 6 ? "Password must be 6+ chars" : null),
                const SizedBox(height: 20),

                // Gender selection
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Gender",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: ["male", "female"].map((g) {
                    final isSelected = gender == g;
                    return ChoiceChip(
                      label: Text(g),
                      selected: isSelected,
                      selectedColor: Colors.blue,
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87),
                      onSelected: (_) => setState(() => gender = g),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _pickDOB,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: "Date of Birth",
                        prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.blue.shade50.withOpacity(0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      controller: TextEditingController(
                        text: dob == null
                            ? ""
                            : DateFormat("dd MMM yyyy").format(dob!),
                      ),
                      validator: (v) => dob == null ? "Pick your DOB" : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Checkbox(
                        value: acceptedTerms,
                        onChanged: (v) => setState(() => acceptedTerms = v!),
                        activeColor: Colors.blue),
                    const Expanded(
                        child: Text("I agree to the Terms of Service and Privacy Policy"))
                  ],
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 5,
                    ),
                    child: isLoading
                        ? Lottie.asset("assets/loading.json", width: 50, height: 50)
                        : const Text(
                            "Register",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}