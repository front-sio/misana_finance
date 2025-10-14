import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:misana_finance_app/core/format/ammount_formatter.dart';


class AppLocales {
  static const Locale defaultLocale = Locale('sw', 'TZ');

  static const supportedLocales = <Locale>[
    Locale('sw', 'TZ'),
    Locale('en', 'US'),
  ];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// Call once before runApp to lock default locale/currency for intl.
  static void bootstrap({
    String locale = 'sw_TZ',
    String currency = 'TZS',
    String symbol = 'TSh',
    int decimalDigits = 0,
  }) {
    Intl.defaultLocale = locale;
    CurrencyDefaults.configure(
      localeCode: locale,
      currencyCode: currency,
      currencySymbol: symbol,
      decimals: decimalDigits,
    );
  }
}