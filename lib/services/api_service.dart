import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../screens/login_screen.dart';

class ApiService {
  // final String baseUrl = "http://10.0.2.2:5000"; // For local emulator
  final String baseUrl = "https://savings-app.up.railway.app";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ---------------- Token Management ----------------
  Future<void> setToken(String token) async {
    await _storage.write(key: "token", value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: "token");
  }

  Future<String> getUserId() async {
    final token = await getToken();
    if (token == null) throw Exception("Token not found");
    final parts = token.split(".");
    if (parts.length != 3) throw Exception("Invalid token");

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic> payloadMap = jsonDecode(decoded);
    return payloadMap['id'];
  }

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // ---------------- Authentication ----------------
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await setToken(data['token']);
      return Map<String, dynamic>.from(data['user']);
    } else {
      throw Exception(data['error'] ?? "Registration failed");
    }
  }

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"identifier": identifier, "password": password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await setToken(data['token']);
      return Map<String, dynamic>.from(data['user']);
    } else {
      throw Exception(data['error'] ?? "Login failed");
    }
  }

  // ---------------- Profile ----------------
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse("$baseUrl/auth/profile"),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data['user']);
    } else {
      try {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? "Failed to fetch profile");
      } catch (_) {
        throw Exception("Failed to fetch profile: ${response.body}");
      }
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String street,
    required String ward,
    required String city,
    required String country,
    required String postalCode,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/auth/update-profile"),
      headers: await _headers(),
      body: jsonEncode({
        "name": name,
        "phone": phone,
        "email": email,
        "street": street,
        "ward": ward,
        "city": city,
        "country": country,
        "postal_code": postalCode
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['user']);
    } else {
      throw Exception(data['error'] ?? "Failed to update profile");
    }
  }

  // ---------------- PIN and Password Management ----------------
  Future<void> addPin({required String newPin}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/add-pin"),
      headers: await _headers(),
      body: jsonEncode({"newPin": newPin}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? "Failed to add PIN");
    }
  }

  Future<void> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/change-pin"),
      headers: await _headers(),
      body: jsonEncode({"oldPin": oldPin, "newPin": newPin}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? "Failed to change PIN");
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/change-password"),
      headers: await _headers(),
      body: jsonEncode({
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? "Failed to change password");
    }
  }

  // ---------------- Accounts ----------------
  Future<List<Map<String, dynamic>>> getAccounts() async {
    final response = await http.get(
      Uri.parse("$baseUrl/accounts"),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data['error'] ?? "Failed to fetch accounts");
    }
  }

  Future<Map<String, dynamic>> createAccount(
    String phone, {
    int target = 0,
    String planType = "goal",
    String planNote = "",
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/accounts"),
      headers: await _headers(),
      body: jsonEncode({
        "phone": phone,
        "targetAmount": target,
        "planType": planType,
        "planNote": planNote,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception(data['error'] ?? "Failed to create account");
    }
  }

  // ---------------- Transactions ----------------
  Future<Map<String, dynamic>> deposit(
    String accountId,
    int amount,
    String note,
    String method,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/transactions/$accountId/deposit"),
      headers: await _headers(),
      body: jsonEncode({"amount": amount, "note": note, "method": method}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['error'] ?? "Deposit failed");
  }

  Future<Map<String, dynamic>> withdraw(
    String accountId,
    int amount,
    String note,
    String pin,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/transactions/$accountId/withdraw"),
      headers: await _headers(),
      body: jsonEncode({"amount": amount, "note": note, "pin": pin}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['error'] ?? "Withdrawal failed");
  }

  // ---------------- PIN Verification ----------------
  Future<bool> verifyPin(String pin) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/verify-pin"),
      headers: await _headers(),
      body: jsonEncode({"pin": pin}),
    );

    if (response.statusCode == 200) return true;
    final data = jsonDecode(response.body);
    throw Exception(data['error'] ?? "PIN verification failed");
  }

  // ---------------- Pots ----------------
  Future<List<Map<String, dynamic>>> getPots() async {
    final response = await http.get(
      Uri.parse("$baseUrl/pots"),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data['error'] ?? "Failed to fetch pots");
    }
  }



   // ✅ Create a new pot under an account
  Future<Map<String, dynamic>> createPot(
    String accountId, {
    required String name,
    int? target,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/accounts/$accountId/pots"),
      headers: await _headers(),
      body: jsonEncode({
        "name": name,
        if (target != null) "target": target,
      }),
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to create pot: ${res.body}");
    }
  }

  // ✅ Deposit into a pot
  Future<Map<String, dynamic>> depositToPot(
    String accountId,
    String potId,
    int amount,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/accounts/$accountId/pots/$potId/deposit"),
      headers: await _headers(),
      body: jsonEncode({"amount": amount}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to deposit into pot: ${res.body}");
    }
  }

  // ✅ Withdraw from a pot
  Future<Map<String, dynamic>> withdrawFromPot(
    String accountId,
    String potId,
    int amount,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/accounts/$accountId/pots/$potId/withdraw"),
      headers: await _headers(),
      body: jsonEncode({"amount": amount}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to withdraw from pot: ${res.body}");
    }
  }

  // ---------------- Logout ----------------
  Future<void> logout(BuildContext context) async {
    await _storage.delete(key: "token");
    await _storage.delete(key: "user");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
