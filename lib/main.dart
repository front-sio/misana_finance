import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:misana_finance_app/core/ui/app_messanger.dart';
import 'package:misana_finance_app/core/i18n/app_locales.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';
import 'package:misana_finance_app/shell/super_app_root.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  AppLocales.bootstrap(
    locale: 'en_US',
    currency: 'TZS',
    symbol: 'TSh',
    decimalDigits: 0,
  );

  runApp(
    BlocProvider(
      create: (_) => LocaleCubit(),
      child: const MisanaApp(),
    ),
  );
}

class MisanaApp extends StatelessWidget {
  const MisanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (ctx, locale) {
        return MaterialApp(
          scaffoldMessengerKey: appMessengerKey,
          title: 'Misana App',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          locale: locale,
          supportedLocales: const [
            Locale('sw', 'TZ'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: const SuperAppRoot(),
          builder: (context, child) {
            FlutterNativeSplash.remove();
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
