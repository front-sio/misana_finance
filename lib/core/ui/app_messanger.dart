import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> appMessengerKey = GlobalKey<ScaffoldMessengerState>();

class AppMessenger {
  static String? _lastMsg;
  static DateTime? _lastAt;

  static const _dedupWindow = Duration(milliseconds: 1500);

  static bool _shouldShow(String msg) {
    final now = DateTime.now();
    if (_lastMsg == msg && _lastAt != null && now.difference(_lastAt!) < _dedupWindow) {
      return false;
    }
    _lastMsg = msg;
    _lastAt = now;
    return true;
  }

  static void _show(
    String msg, {
    Color? bg,
    Color fg = Colors.white,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (msg.trim().isEmpty) return;
    if (!_shouldShow(msg)) return;

    final messenger = appMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg ?? Colors.black87,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: duration,
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: fg),
                const SizedBox(width: 10),
              ],
              Expanded(child: Text(msg, style: TextStyle(color: fg))),
            ],
          ),
          action: SnackBarAction(label: 'OK', textColor: fg, onPressed: () {}),
        ),
      );
  }

  static void success(String msg) =>
      _show(msg, bg: Colors.green.shade700, icon: Icons.check_circle_outline);
  static void info(String msg) => _show(msg, bg: Colors.blue.shade700, icon: Icons.info_outline);
  static void warn(String msg) =>
      _show(msg, bg: Colors.amber.shade800, icon: Icons.warning_amber_outlined);
  static void error(String msg) => _show(msg, bg: Colors.red.shade700, icon: Icons.error_outline);
}