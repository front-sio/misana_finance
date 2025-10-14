import 'package:flutter/material.dart';

class UpdateProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const UpdateProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: user['name']);
    final phoneController = TextEditingController(text: user['phone']);
    final emailController = TextEditingController(text: user['email']);
    final streetController = TextEditingController(text: user['street']);
    final wardController = TextEditingController(text: user['ward']);
    final cityController = TextEditingController(text: user['city']);
    final countryController = TextEditingController(text: user['country']);
    final postalCodeController = TextEditingController(text: user['postalCode']);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Profile"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: streetController,
              decoration: const InputDecoration(labelText: "Street"),
            ),
            TextField(
              controller: wardController,
              decoration: const InputDecoration(labelText: "Ward"),
            ),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: "City"),
            ),
            TextField(
              controller: countryController,
              decoration: const InputDecoration(labelText: "Country"),
            ),
            TextField(
              controller: postalCodeController,
              decoration: const InputDecoration(labelText: "Postal Code"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement update API call
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile updated!")),
                );
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}
