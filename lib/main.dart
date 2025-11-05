import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:misana_finance_app/feature/home/presentation/bloc/home_bloc.dart';
import 'package:misana_finance_app/feature/kyc/data/repositories/kyc_repository_impl.dart';
import 'package:misana_finance_app/feature/splash/presentation/pages/splash_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:misana_finance_app/core/ui/app_messanger.dart';
import 'package:misana_finance_app/core/i18n/app_locales.dart';
import 'package:misana_finance_app/core/i18n/locale_cubit.dart';
import 'package:misana_finance_app/core/navigation/nav.dart';
import 'package:misana_finance_app/core/network/api_client.dart';
import 'package:misana_finance_app/core/storage/token_storage.dart';
import 'package:misana_finance_app/core/theme/app_theme.dart';

import 'feature/session/auth_cubit.dart';
import 'feature/auth/data/datasources/auth_remote_data_source.dart';
import 'feature/auth/data/repositories/auth_repository_impl.dart';
import 'feature/auth/domain/repositories/auth_repository.dart';
import 'feature/auth/presentation/bloc/login/login_bloc.dart';
import 'feature/auth/presentation/bloc/registration/registration_bloc.dart';
import 'feature/auth/presentation/bloc/verification/verification_bloc.dart';
import 'feature/auth/presentation/pages/login_page.dart';
import 'feature/auth/presentation/pages/register_page.dart';
import 'feature/auth/presentation/pages/verify_account_page.dart';

import 'feature/home/presentation/pages/home_page.dart' as home_ui;

import 'feature/home/data/datasources/home_remote_data_source.dart';
import 'feature/home/data/repositories/home_repository_impl.dart';
import 'feature/home/domain/home_repository.dart';

import 'feature/kyc/data/datasources/kyc_remote_data_source.dart';
import 'feature/kyc/domain/kyc_repository.dart';
import 'feature/kyc/presentation/bloc/kyc_bloc.dart';
import 'feature/kyc/presentation/bloc/kyc_event.dart';
import 'feature/kyc/presentation/pages/kyc_verification_page.dart';

import 'feature/savings/data/datasources/savings_remote_data_source.dart';
import 'feature/savings/data/repositories/savings_repository_impl.dart';
import 'feature/savings/domain/savings_repository.dart';

import 'feature/account/data/datasources/account_remote_data_source.dart';
import 'feature/account/data/repositories/account_repository_impl.dart';
import 'feature/account/domain/account_repository.dart';

import 'feature/pots/data/datasources/pots_remote_data_source.dart';
import 'feature/pots/data/repositories/pots_repository_impl.dart';
import 'feature/pots/domain/pots_repository.dart';
import 'feature/pots/presentation/pages/pots_list_page.dart';
import 'feature/pots/presentation/pages/pot_create_page.dart';

import 'feature/payments/data/datasources/payments_remote_data_source.dart';
import 'feature/payments/data/repositories/payments_repository_impl.dart';
import 'feature/payments/domain/payments_repository.dart';
import 'feature/payments/presentation/pages/deposit_page.dart';
import 'feature/payments/presentation/pages/transactions_page.dart';

import 'package:misana_finance_app/feature/onboarding/presentation/pages/onboarding_page.dart' as onboarding;

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

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  final baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://misana.stebofarm.co.tz',
  );

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(baseUrl: baseUrl, tokenStorage: tokenStorage);

  final authRemote = AuthRemoteDataSource(apiClient);
  final AuthRepository authRepo = AuthRepositoryImpl(authRemote, storage: tokenStorage);

  final homeRemote = HomeRemoteDataSource(apiClient);
  final HomeRepository homeRepo = HomeRepositoryImpl(homeRemote);

  final kycRemote = KycRemoteDataSource(apiClient);
  final KycRepository kycRepo = KycRepositoryImpl(kycRemote);

  final savingsRemote = SavingsRemoteDataSource(apiClient);
  final SavingsRepository savingsRepo = SavingsRepositoryImpl(savingsRemote);

  final AccountRepository accountRepo = AccountRepositoryImpl(AccountRemoteDataSource(apiClient));

  final PotsRepository potsRepo = PotsRepositoryImpl(PotsRemoteDataSource(apiClient));

  final PaymentsRepository paymentsRepo = PaymentsRepositoryImpl(PaymentsRemoteDataSource(apiClient));

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HomeRepository>.value(value: homeRepo),
        RepositoryProvider<KycRepository>.value(value: kycRepo),
        RepositoryProvider<SavingsRepository>.value(value: savingsRepo),
        RepositoryProvider<AccountRepository>.value(value: accountRepo),
        RepositoryProvider<PotsRepository>.value(value: potsRepo),
        RepositoryProvider<PaymentsRepository>.value(value: paymentsRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => LocaleCubit()),
          BlocProvider(create: (_) => AuthCubit(storage: tokenStorage, authRepo: authRepo)),
          BlocProvider(create: (_) => RegistrationBloc(authRepo)),
          BlocProvider(create: (_) => VerificationBloc(authRepo)),
          BlocProvider(create: (_) => LoginBloc(authRepo)),
          BlocProvider(
            create: (ctx) => HomeBloc(
              RepositoryProvider.of<HomeRepository>(ctx),
            ),
          ),
        ],
        child: MisanaApp(initialRoute: seenOnboarding ? '/splash' : '/onboarding'),
      ),
    ),
  );
}

class MisanaApp extends StatelessWidget {
  final String initialRoute;
  const MisanaApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (ctx, locale) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          scaffoldMessengerKey: appMessengerKey,
          title: 'Misana Finance',
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
          initialRoute: initialRoute,
          routes: {
            '/onboarding': (_) => const onboarding.OnboardingPage(),
            '/splash': (_) => const SplashPage(),
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/verify': (_) => const VerifyAccountPage(usernameOrEmail: ''),
            '/home': (_) => const home_ui.HomePage(),
            '/kyc': (routeCtx) {
              return BlocProvider(
                create: (_) => KycBloc(RepositoryProvider.of<KycRepository>(routeCtx)),
                child: const KycVerificationPage(),
              );
            },
            '/pots': (routeCtx) => PotsListPage(repo: RepositoryProvider.of<PotsRepository>(routeCtx)),
            '/pots/new': (routeCtx) => PotCreatePage(repo: RepositoryProvider.of<PotsRepository>(routeCtx)),
            '/deposit': (routeCtx) => DepositPage(
                  paymentsRepo: RepositoryProvider.of<PaymentsRepository>(routeCtx),
                  potsRepo: RepositoryProvider.of<PotsRepository>(routeCtx),
                ),
            '/transactions': (routeCtx) =>
                TransactionsPage(repo: RepositoryProvider.of<PaymentsRepository>(routeCtx)),
          },
          builder: (context, child) {
            FlutterNativeSplash.remove();
            return child!;
          },
        );
      },
    );
  }
}