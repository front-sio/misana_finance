import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misana_finance_app/core/i18n/app_translations.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';

/// Service for handling app localization and translations
class LocalizationService {
  /// Get translation for a given key
  /// 
  /// [key] - The translation key to look up
  /// [context] - BuildContext to access current locale
  /// [fallback] - Optional fallback text if translation not found
  static String t(BuildContext context, String key, {String? fallback}) {
    final languageCode = context.read<LocaleCubit>().state.languageCode;
    return _translate(key, languageCode, fallback: fallback);
  }

  /// Get translation for a given key with direct language code
  /// 
  /// [key] - The translation key to look up
  /// [languageCode] - The language code ('sw' or 'en')
  /// [fallback] - Optional fallback text if translation not found
  static String _translate(String key, String languageCode, {String? fallback}) {
    return AppTranslations.translations[key]?[languageCode] ?? fallback ?? key;
  }

  /// Get current language code from context
  static String getCurrentLanguage(BuildContext context) {
    return context.read<LocaleCubit>().state.languageCode;
  }

  /// Check if current language is Swahili
  static bool isSwahili(BuildContext context) {
    return getCurrentLanguage(context) == 'sw';
  }

  /// Check if current language is English
  static bool isEnglish(BuildContext context) {
    return getCurrentLanguage(context) == 'en';
  }
}

/// Extension on BuildContext to provide easy access to translations
extension LocalizationExtension on BuildContext {
  /// Get translation for a given key
  String t(String key, {String? fallback}) {
    return LocalizationService.t(this, key, fallback: fallback);
  }

  /// Get current language code
  String get currentLanguage => LocalizationService.getCurrentLanguage(this);

  /// Check if current language is Swahili
  bool get isSwahili => LocalizationService.isSwahili(this);

  /// Check if current language is English
  bool get isEnglish => LocalizationService.isEnglish(this);
}
