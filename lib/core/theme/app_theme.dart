// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Brand palette
class BrandPalette {
  // Main brand colors
  static const Color orange = Color(0xFFED702E); // Primary (brand orange)
  static const Color purple = Color(0xFF9E27B4); // Secondary (brand purple)
  static const Color white = Color(0xFFFFFFFF);

  // Neutrals
  static const Color black = Color(0xFF111111);
  static const Color gray600 = Color(0xFF5F5F5F);
  static const Color gray300 = Color(0xFFE3E3E3);
}

/// App-wide brand extensions (e.g., gradients)
@immutable
class BrandTheme extends ThemeExtension<BrandTheme> {
  final Gradient headerGradient;
  final Gradient headerGradientDark;

  const BrandTheme({
    required this.headerGradient,
    required this.headerGradientDark,
  });

  @override
  BrandTheme copyWith({
    Gradient? headerGradient,
    Gradient? headerGradientDark,
  }) {
    return BrandTheme(
      headerGradient: headerGradient ?? this.headerGradient,
      headerGradientDark: headerGradientDark ?? this.headerGradientDark,
    );
  }

  @override
  ThemeExtension<BrandTheme> lerp(ThemeExtension<BrandTheme>? other, double t) {
    if (other is! BrandTheme) return this;
    return BrandTheme(
      headerGradient:
          _safeLerpLinearGradient(headerGradient, other.headerGradient, t),
      headerGradientDark:
          _safeLerpLinearGradient(headerGradientDark, other.headerGradientDark, t),
    );
  }

  static Gradient _safeLerpLinearGradient(
      Gradient a, Gradient b, double t) {
    if (a is LinearGradient && b is LinearGradient) {
      final colors = <Color>[];
      final len = a.colors.length;
      for (var i = 0; i < len; i++) {
        final ca = a.colors[i];
        final cb = b.colors[i % b.colors.length];
        colors.add(Color.lerp(ca, cb, t)!);
      }
      return LinearGradient(
        begin: a.begin,
        end: a.end,
        colors: colors,
        stops: a.stops,
        tileMode: a.tileMode,
        transform: a.transform,
      );
    }
    return a;
  }
}

/// Build LIGHT theme with fixed brand colors (no hue shifts)
ThemeData buildAppTheme() {
  const orange = BrandPalette.orange;
  const purple = BrandPalette.purple;

  final lightScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: orange,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFB899), // softer orange container
    onPrimaryContainer: BrandPalette.black,

    secondary: purple,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE1BEE7), // softer purple container
    onSecondaryContainer: BrandPalette.black,

    tertiary: Color(0xFFFFA94D), // accent orange tone
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFE0B2),
    onTertiaryContainer: BrandPalette.black,

    error: Color(0xFFB00020),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: BrandPalette.black,

    background: BrandPalette.white,
    onBackground: BrandPalette.black,

    surface: BrandPalette.white,
    onSurface: BrandPalette.black,
    surfaceVariant: Color(0xFFF4F4F4),
    onSurfaceVariant: BrandPalette.gray600,

    outline: Color(0xFFBDBDBD),
    outlineVariant: BrandPalette.gray300,
    shadow: Colors.black12,
    scrim: Colors.black54,
    inverseSurface: Color(0xFF303030),
    onInverseSurface: Colors.white,
    inversePrimary: orange,
  );

  const brandExtension = BrandTheme(
    headerGradient: LinearGradient(
      colors: [
        BrandPalette.orange,
        Color(0xFFFF9960), // lighter orange
        BrandPalette.purple,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradientDark: LinearGradient(
      colors: [
        Color(0xFFBF5320), // darkened orange
        BrandPalette.purple,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  OutlineInputBorder noBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: BorderSide.none,
      );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    extensions: const [brandExtension],
    colorScheme: lightScheme,
    scaffoldBackgroundColor: lightScheme.background,

    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: lightScheme.background,
      foregroundColor: lightScheme.onBackground,
      titleTextStyle: TextStyle(
        color: lightScheme.onBackground,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: lightScheme.onBackground),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightScheme.surfaceVariant,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      hintStyle: TextStyle(
        color: lightScheme.onSurfaceVariant,
        fontWeight: FontWeight.normal,
      ),
      border: noBorder(),
      enabledBorder: noBorder(),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: BorderSide(color: lightScheme.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: BorderSide(color: lightScheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: BorderSide(color: lightScheme.error, width: 1.2),
      ),
      disabledBorder: noBorder(),
      prefixIconColor: lightScheme.primary,
      suffixIconColor: lightScheme.primary,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: lightScheme.primary,
        foregroundColor: lightScheme.onPrimary,
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightScheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: lightScheme.primary, width: 1.2),
        foregroundColor: lightScheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: lightScheme.secondary,
      foregroundColor: lightScheme.onSecondary,
      elevation: 0,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: lightScheme.secondaryContainer.withOpacity(0.25),
      selectedColor: lightScheme.secondaryContainer,
      labelStyle: TextStyle(color: lightScheme.onSecondaryContainer),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: lightScheme.secondary.withOpacity(0.3)),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightScheme.inverseSurface,
      contentTextStyle: TextStyle(color: lightScheme.onInverseSurface),
      behavior: SnackBarBehavior.floating,
      elevation: 2,
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: lightScheme.primary,
      linearTrackColor: lightScheme.primary.withOpacity(0.2),
      circularTrackColor: lightScheme.primary.withOpacity(0.2),
    ),

    dividerTheme: DividerThemeData(
      color: lightScheme.outlineVariant,
      thickness: 1,
      space: 24,
    ),

    iconTheme: IconThemeData(color: lightScheme.onSurface),

    cardTheme: CardThemeData(
      color: lightScheme.surface,
      surfaceTintColor: lightScheme.surface,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: lightScheme.surface,
      modalBackgroundColor: lightScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: lightScheme.surface,
      surfaceTintColor: lightScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      titleTextStyle: TextStyle(
        color: lightScheme.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
      contentTextStyle: TextStyle(color: lightScheme.onSurfaceVariant),
    ),

    listTileTheme: ListTileThemeData(
      iconColor: lightScheme.primary,
      textColor: lightScheme.onSurface,
      subtitleTextStyle: TextStyle(color: lightScheme.onSurfaceVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: lightScheme.onPrimary,
      unselectedItemColor: lightScheme.onPrimary.withOpacity(0.7),
      backgroundColor: lightScheme.primary,
      selectedIconTheme: const IconThemeData(size: 28),
      unselectedIconTheme: const IconThemeData(size: 24),
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
