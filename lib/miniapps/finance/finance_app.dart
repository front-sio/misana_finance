import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misana_finance_app/core/navigation/nav.dart';
import 'package:misana_finance_app/core/network/api_client.dart';
import 'package:misana_finance_app/core/network/websocket_service.dart';
import 'package:misana_finance_app/core/storage/token_storage.dart';

import 'package:misana_finance_app/auth/session/auth_cubit.dart';
import 'package:misana_finance_app/auth/data/datasources/auth_remote_data_source.dart';
import 'package:misana_finance_app/auth/data/repositories/auth_repository_impl.dart';
import 'package:misana_finance_app/auth/domain/repositories/auth_repository.dart';
import 'package:misana_finance_app/auth/presentation/bloc/login/login_bloc.dart';
import 'package:misana_finance_app/auth/presentation/bloc/registration/registration_bloc.dart';
import 'package:misana_finance_app/auth/presentation/bloc/verification/verification_bloc.dart';
import 'package:misana_finance_app/auth/presentation/pages/login_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/register_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/verify_account_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/notifications_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/security_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/sessions_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/devices_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/help_support_page.dart';

import 'feature/home/presentation/bloc/home_bloc.dart';
import 'feature/home/presentation/pages/home_page.dart' as home_ui;
import 'feature/home/data/datasources/home_remote_data_source.dart';
import 'feature/home/data/repositories/home_repository_impl.dart';
import 'feature/home/domain/home_repository.dart';

import 'feature/kyc/data/datasources/kyc_remote_data_source.dart';
import 'feature/kyc/data/repositories/kyc_repository_impl.dart';
import 'feature/kyc/domain/kyc_repository.dart';
import 'feature/kyc/presentation/bloc/kyc_bloc.dart';
import 'feature/kyc/presentation/pages/kyc_verification_page.dart';

import 'feature/account/data/datasources/account_remote_data_source.dart';
import 'feature/account/data/repositories/account_repository_impl.dart';
import 'feature/account/domain/account_repository.dart';

import 'feature/pots/data/datasources/pots_remote_data_source.dart';
import 'feature/pots/data/repositories/pots_repository_impl.dart';
import 'feature/pots/domain/pots_repository.dart';
import 'feature/pots/presentation/pages/pot_create_page.dart';

import 'feature/payments/data/datasources/payments_remote_data_source.dart';
import 'feature/payments/data/repositories/payments_repository_impl.dart';
import 'feature/payments/domain/payments_repository.dart';
import 'feature/payments/presentation/pages/deposit_page.dart';
import 'feature/payments/presentation/pages/transactions_page.dart';

import 'feature/splash/presentation/pages/splash_page.dart';
import 'feature/onboarding/presentation/pages/onboarding_page.dart'
    as onboarding;

class FinanceApp extends StatefulWidget {
  final bool embedded;
  final bool useParentAuthCubit;
  final String? initialRoute;

  const FinanceApp({
    super.key,
    this.embedded = false,
    this.useParentAuthCubit = false,
    this.initialRoute,
  });

  const FinanceApp.embedded({super.key})
    : embedded = true,
      useParentAuthCubit = true,
      initialRoute = '/home';

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> {
  bool? _seenOnboarding;

  late final TokenStorage _tokenStorage;
  late final ApiClient _apiClient;
  late final WebSocketService _wsService;

  late final AuthRepository _authRepo;
  late final HomeRepository _homeRepo;
  late final KycRepository _kycRepo;
  late final AccountRepository _accountRepo;
  late final PotsRepository _potsRepo;
  late final PaymentsRepository _paymentsRepo;

  @override
  void initState() {
    super.initState();
    _tokenStorage = TokenStorage();

    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue:
          'http://misana-backend-misanaapi-h3pnbw-4233c5-138-68-41-254.traefik.me/api/v1',
    );

    _apiClient = ApiClient(baseUrl: baseUrl, tokenStorage: _tokenStorage);
    _wsService = WebSocketService(
      baseUrl: baseUrl,
      tokenStorage: _tokenStorage,
    );

    final authRemote = AuthRemoteDataSource(_apiClient);
    _authRepo = AuthRepositoryImpl(authRemote, storage: _tokenStorage);

    final homeRemote = HomeRemoteDataSource(_apiClient);
    _homeRepo = HomeRepositoryImpl(homeRemote);

    final kycRemote = KycRemoteDataSource(_apiClient);
    _kycRepo = KycRepositoryImpl(kycRemote);

    _accountRepo = AccountRepositoryImpl(AccountRemoteDataSource(_apiClient));
    _potsRepo = PotsRepositoryImpl(PotsRemoteDataSource(_apiClient));
    _paymentsRepo = PaymentsRepositoryImpl(
      PaymentsRemoteDataSource(_apiClient),
    );

    if (widget.embedded || widget.initialRoute != null) {
      _seenOnboarding = true;
    } else {
      _loadOnboardingState();
    }
  }

  Future<void> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final overrideRoute = widget.initialRoute;
    final seenOnboarding = _seenOnboarding;
    if (overrideRoute == null && seenOnboarding == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final seenOnboardingValue = seenOnboarding ?? false;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HomeRepository>.value(value: _homeRepo),
        RepositoryProvider<KycRepository>.value(value: _kycRepo),
        RepositoryProvider<WebSocketService>.value(value: _wsService),
        RepositoryProvider<AccountRepository>.value(value: _accountRepo),
        RepositoryProvider<PotsRepository>.value(value: _potsRepo),
        RepositoryProvider<PaymentsRepository>.value(value: _paymentsRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          if (!widget.useParentAuthCubit)
            BlocProvider(
              create: (_) => AuthCubit(
                storage: _tokenStorage,
                authRepo: _authRepo,
                wsService: _wsService,
              ),
            ),
          if (!widget.useParentAuthCubit)
            BlocProvider(create: (_) => RegistrationBloc(_authRepo)),
          if (!widget.useParentAuthCubit)
            BlocProvider(create: (_) => VerificationBloc(_authRepo)),
          if (!widget.useParentAuthCubit)
            BlocProvider(create: (_) => LoginBloc(_authRepo)),
          BlocProvider(create: (_) => KycBloc(_kycRepo)),
          BlocProvider(
            create: (ctx) =>
                HomeBloc(RepositoryProvider.of<HomeRepository>(ctx)),
          ),
        ],
        child: FinanceNavigator(
          initialRoute:
              overrideRoute ??
              (seenOnboardingValue ? '/splash' : '/onboarding'),
          navigatorKey: widget.embedded ? null : appNavigatorKey,
          embedded: widget.embedded,
        ),
      ),
    );
  }
}

class FinanceNavigator extends StatefulWidget {
  final String initialRoute;
  final GlobalKey<NavigatorState>? navigatorKey;
  final bool embedded;

  const FinanceNavigator({
    super.key,
    required this.initialRoute,
    this.navigatorKey,
    this.embedded = false,
  });

  @override
  State<FinanceNavigator> createState() => _FinanceNavigatorState();
}

class _FinanceNavigatorState extends State<FinanceNavigator> {
  late final GlobalKey<NavigatorState> _localNavKey =
      GlobalKey<NavigatorState>();

  GlobalKey<NavigatorState> get _navKey => widget.navigatorKey ?? _localNavKey;

  @override
  Widget build(BuildContext context) {
    final nestedNavigator = Navigator(
      key: _navKey,
      initialRoute: widget.initialRoute,
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        switch (name) {
          case '/onboarding':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const onboarding.OnboardingPage(),
            );
          case '/splash':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SplashPage(),
            );
          case '/login':
            if (widget.embedded) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const _SuperLoginRedirect(),
              );
            }
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const LoginPage(),
            );
          case '/register':
            if (widget.embedded) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const _SuperLoginRedirect(),
              );
            }
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const RegisterPage(),
            );
          case '/verify':
            if (widget.embedded) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const _SuperLoginRedirect(),
              );
            }
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const VerifyAccountPage(usernameOrEmail: ''),
            );
          case '/home':
            return MaterialPageRoute(
              settings: settings,
              builder: (routeCtx) {
                final args = settings.arguments;
                final tab = (args is Map && args['tab'] is int)
                    ? args['tab'] as int
                    : 0;
                return home_ui.HomePage(initialIndex: tab);
              },
            );
          case '/kyc':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const KycVerificationPage(),
            );
          case '/pots':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => home_ui.HomePage(initialIndex: 1),
            );
          case '/pots/new':
            return MaterialPageRoute(
              settings: settings,
              builder: (routeCtx) => PotCreatePage(
                repo: RepositoryProvider.of<PotsRepository>(routeCtx),
              ),
            );
          case '/deposit':
            return MaterialPageRoute(
              settings: settings,
              builder: (routeCtx) => DepositPage(
                paymentsRepo: RepositoryProvider.of<PaymentsRepository>(
                  routeCtx,
                ),
                potsRepo: RepositoryProvider.of<PotsRepository>(routeCtx),
              ),
            );
          case '/transactions':
            return MaterialPageRoute(
              settings: settings,
              builder: (routeCtx) => TransactionsPage(
                repo: RepositoryProvider.of<PaymentsRepository>(routeCtx),
              ),
            );
          case '/notifications':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const NotificationsPage(),
            );
          case '/security':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SecurityPage(),
            );
          case '/sessions':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SessionsPage(),
            );
          case '/devices':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const DevicesPage(),
            );
          case '/help-support':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const HelpSupportPage(),
            );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashPage(),
        );
      },
    );

    if (!widget.embedded) {
      return nestedNavigator;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        final nav = _navKey.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
          return;
        }
        Navigator.of(context, rootNavigator: true).maybePop();
      },
      child: nestedNavigator,
    );
  }
}

class _SuperLoginRedirect extends StatefulWidget {
  const _SuperLoginRedirect();

  @override
  State<_SuperLoginRedirect> createState() => _SuperLoginRedirectState();
}

class _SuperLoginRedirectState extends State<_SuperLoginRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/login', (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
