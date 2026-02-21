import 'package:flutter/material.dart';

class MeetingPage extends StatelessWidget {
  const MeetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting'),
      ),
      body: const Center(
        child: Text('Meeting placeholder (Agora audio will go here)'),
      ),
    );
  }
}
