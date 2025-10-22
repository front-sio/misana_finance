import 'dart:convert';

class JwtUtils {
  /// Returns the `sub` (subject) claim from a JWT access token, or null.
  static String? getSub(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = _base64UrlDecode(parts[1]);
      final map = json.decode(payload);
      final sub = (map['sub'] ?? '').toString();
      return sub.isNotEmpty ? sub : null;
    } catch (_) {
      return null;
    }
  }

  static String _base64UrlDecode(String input) {
    var normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    final padLen = (4 - normalized.length % 4) % 4;
    normalized += '=' * padLen;
    return utf8.decode(base64.decode(normalized));
  }
}