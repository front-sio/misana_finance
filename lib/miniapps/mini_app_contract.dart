import 'package:flutter/material.dart';

class MiniAppContract {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool comingSoon;
  final Widget Function() buildEntry;

  const MiniAppContract({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.comingSoon = false,
    required this.buildEntry,
  });
}
