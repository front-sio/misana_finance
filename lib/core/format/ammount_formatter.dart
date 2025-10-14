import 'package:intl/intl.dart';

class CurrencyDefaults {
  static String locale = 'sw_TZ';
  static String currency = 'TZS';
  static String symbol = 'TSh';
  static int decimalDigits = 0;

  static void configure({
    String? localeCode,
    String? currencyCode,
    String? currencySymbol,
    int? decimals,
  }) {
    if (localeCode != null) locale = localeCode;
    if (currencyCode != null) currency = currencyCode;
    if (currencySymbol != null) symbol = currencySymbol;
    if (decimals != null) decimalDigits = decimals;
    Intl.defaultLocale = locale;
    _NumberCache.clear();
  }
}

class AmountFormatter {
  static String money(
    num? value, {
    String? locale,
    String? currency,
    String? symbol,
    int? decimalDigits,
    bool withSymbol = true,
    bool compact = false,
    bool removeTrailingZeros = true,
  }) {
    final v = (value ?? 0).toDouble();
    final loc = locale ?? CurrencyDefaults.locale;
    final sym = withSymbol ? (symbol ?? CurrencyDefaults.symbol) : '';
    final digits = decimalDigits ?? CurrencyDefaults.decimalDigits;

    if (compact) {
      final f = _NumberCache.compactCurrency(loc, sym, digits);
      return f.format(v);
    }
    final f = withSymbol
        ? _NumberCache.currency(loc, sym, digits)
        : _NumberCache.decimal(loc, digits);

    var s = f.format(v);
    if (removeTrailingZeros && digits > 0) {
      final decSep = NumberFormat('.', loc).symbols.DECIMAL_SEP;
      final regex = RegExp(RegExp.escape(decSep) + r'0+$');
      s = s.replaceAll(regex, '');
    }
    return s;
  }

  static String number(
    num? value, {
    String? locale,
    int? decimalDigits,
    bool compact = false,
  }) {
    final v = (value ?? 0).toDouble();
    final loc = locale ?? CurrencyDefaults.locale;
    final digits = decimalDigits ?? CurrencyDefaults.decimalDigits;

    if (compact) {
      final f = _NumberCache.compactDecimal(loc, digits);
      return f.format(v);
    }
    final f = _NumberCache.decimal(loc, digits);
    return f.format(v);
  }
}

class _NumberCache {
  static final Map<String, NumberFormat> _currency = {};
  static final Map<String, NumberFormat> _decimal = {};
  static final Map<String, NumberFormat> _compactCurrency = {};
  static final Map<String, NumberFormat> _compactDecimal = {};

  static NumberFormat currency(String locale, String symbol, int digits) {
    final key = '$locale|$symbol|$digits';
    return _currency.putIfAbsent(
      key,
      () => NumberFormat.currency(locale: locale, symbol: symbol, decimalDigits: digits),
    );
  }

  static NumberFormat decimal(String locale, int digits) {
    final key = '$locale|$digits';
    return _decimal.putIfAbsent(
      key,
      () => NumberFormat.decimalPattern(locale)
        ..minimumFractionDigits = digits
        ..maximumFractionDigits = digits,
    );
  }

  static NumberFormat compactCurrency(String locale, String symbol, int digits) {
    final key = '$locale|$symbol|$digits|compactC';
    return _compactCurrency.putIfAbsent(
      key,
      () => NumberFormat.compactCurrency(locale: locale, symbol: symbol, decimalDigits: digits),
    );
  }

  static NumberFormat compactDecimal(String locale, int digits) {
    final key = '$locale|$digits|compactD';
    return _compactDecimal.putIfAbsent(
      key,
      () => NumberFormat.compact(locale: locale)
        ..minimumFractionDigits = digits
        ..maximumFractionDigits = digits,
    );
  }

  static void clear() {
    _currency.clear();
    _decimal.clear();
    _compactCurrency.clear();
    _compactDecimal.clear();
  }
}

extension AmountFormatNumX on num {
  String tzs({
    bool withSymbol = true,
    bool compact = false,
    int? decimals,
    String? locale,
  }) {
    return AmountFormatter.money(
      this,
      withSymbol: withSymbol,
      compact: compact,
      decimalDigits: decimals,
      locale: locale,
    );
  }
}