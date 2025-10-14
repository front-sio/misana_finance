import 'package:flutter/material.dart';

class SavingsStatusBadge extends StatelessWidget {
  final String status;
  const SavingsStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Hai';
        break;
      case 'pending':
        icon = Icons.pending_outlined;
        color = Colors.amber;
        label = 'Inasubiri';
        break;
      case 'closed':
        icon = Icons.lock_outline;
        color = Colors.red;
        label = 'Imefungwa';
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
        label = 'Haifahamiki';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}