import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:misana_finance_app/core/ui/app_messanger.dart';
import 'package:misana_finance_app/feature/home/presentation/bloc/home_bloc.dart';
import 'package:misana_finance_app/feature/splash/presentation/pages/splash_page.dart';
import 'core/i18n/app_locales.dart';
import 'core/i18n/locale_cubit.dart';
import 'core/navigation/nav.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';

// Auth + Session
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

// Home UI (aliased)
import 'feature/home/presentation/pages/home_page.dart' as home_ui;

// Home domain
import 'feature/home/data/datasources/home_remote_data_source.dart';
import 'feature/home/data/repositories/home_repository_impl.dart';
import 'feature/home/domain/home_repository.dart';

// KYC
import 'feature/kyc/data/datasources/kyc_remote_data_source.dart';
import 'feature/kyc/data/repositories/kyc_repository_impl.dart';
import 'feature/kyc/domain/kyc_repository.dart';
import 'feature/kyc/presentation/bloc/kyc_bloc.dart';
import 'feature/kyc/presentation/bloc/kyc_event.dart';
import 'feature/kyc/presentation/pages/kyc_verification_page.dart';

// Savings (legacy)
import 'feature/savings/data/datasources/savings_remote_data_source.dart';
import 'feature/savings/data/repositories/savings_repository_impl.dart';
import 'feature/savings/domain/savings_repository.dart';

// New: Account + Pots + Payments
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

void main() {
  AppLocales.bootstrap(
    locale: 'sw_TZ',
    currency: 'TZS',
    symbol: 'TSh',
    decimalDigits: 0,
  );

  final baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(baseUrl: baseUrl, tokenStorage: tokenStorage);

  // Auth
  final authRemote = AuthRemoteDataSource(apiClient);
  final AuthRepository authRepo = AuthRepositoryImpl(authRemote, storage: tokenStorage);

  // Home
  final homeRemote = HomeRemoteDataSource(apiClient);
  final HomeRepository homeRepo = HomeRepositoryImpl(homeRemote);

  // KYC
  final kycRemote = KycRemoteDataSource(apiClient);
  final KycRepository kycRepo = KycRepositoryImpl(kycRemote);

  // Savings (legacy)
  final savingsRemote = SavingsRemoteDataSource(apiClient);
  final SavingsRepository savingsRepo = SavingsRepositoryImpl(savingsRemote);

  // Account
  final AccountRepository accountRepo = AccountRepositoryImpl(AccountRemoteDataSource(apiClient));

  // Pots
  final PotsRepository potsRepo = PotsRepositoryImpl(PotsRemoteDataSource(apiClient));

  // Payments
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
        child: const MisanaApp(),
      ),
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
          initialRoute: '/splash',
          // Use the route's own BuildContext to resolve RepositoryProviders correctly
          routes: {
            '/splash': (_) => const SplashPage(),
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/verify': (_) => const VerifyAccountPage(usernameOrEmail: ''),
            '/home': (_) => const home_ui.HomePage(),

            // KYC
            '/kyc': (routeCtx) {
              final accountId = (routeCtx.read<AuthCubit>().state.user?['id'] ?? '').toString();
              return BlocProvider(
                create: (_) =>
                    KycBloc(RepositoryProvider.of<KycRepository>(routeCtx))
                      ..add(KycLoadStatus(accountId: accountId)),
                child: KycVerificationPage(accountId: accountId),
              );
            },

            // Pots & Payments
            '/pots': (routeCtx) => PotsListPage(repo: RepositoryProvider.of<PotsRepository>(routeCtx)),
            '/pots/new': (routeCtx) => PotCreatePage(repo: RepositoryProvider.of<PotsRepository>(routeCtx)),
            '/deposit': (routeCtx) => DepositPage(
                  paymentsRepo: RepositoryProvider.of<PaymentsRepository>(routeCtx),
                  potsRepo: RepositoryProvider.of<PotsRepository>(routeCtx),
                ),
            '/transactions': (routeCtx) =>
                TransactionsPage(repo: RepositoryProvider.of<PaymentsRepository>(routeCtx)),
          },
        );
      },
    );
  }
}