import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misana_finance_app/core/navigation/nav.dart';
import 'package:misana_finance_app/core/network/api_client.dart';
import 'package:misana_finance_app/core/network/websocket_service.dart';
import 'package:misana_finance_app/core/storage/token_storage.dart';
import 'package:misana_finance_app/auth/data/datasources/auth_remote_data_source.dart';
import 'package:misana_finance_app/auth/data/repositories/auth_repository_impl.dart';
import 'package:misana_finance_app/auth/domain/repositories/auth_repository.dart';
import 'package:misana_finance_app/auth/presentation/bloc/login/login_bloc.dart';
import 'package:misana_finance_app/auth/presentation/bloc/registration/registration_bloc.dart';
import 'package:misana_finance_app/auth/presentation/bloc/verification/verification_bloc.dart';
import 'package:misana_finance_app/auth/presentation/pages/devices_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/help_support_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/login_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/notifications_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/profile_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/register_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/security_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/sessions_page.dart';
import 'package:misana_finance_app/auth/presentation/pages/verify_account_page.dart';
import 'package:misana_finance_app/miniapps/finance/feature/onboarding/presentation/pages/onboarding_page.dart';
import 'package:misana_finance_app/auth/session/auth_cubit.dart';
import 'package:misana_finance_app/auth/session/auth_state.dart';
import 'package:misana_finance_app/miniapps/finance/feature/splash/presentation/pages/splash_page.dart';

import 'super_app_shell.dart';

class SuperAppRoot extends StatefulWidget {
  const SuperAppRoot({super.key});

  @override
  State<SuperAppRoot> createState() => _SuperAppRootState();
}

class _SuperAppRootState extends State<SuperAppRoot> {
  bool? _seenOnboarding;

  late final TokenStorage _tokenStorage;
  late final ApiClient _apiClient;
  late final WebSocketService _wsService;
  late final AuthRepository _authRepo;

  @override
  void initState() {
    super.initState();
    _tokenStorage = TokenStorage();

    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://misana-backend-misanaapi-h3pnbw-4233c5-138-68-41-254.traefik.me/api/v1',
    );

    _apiClient = ApiClient(baseUrl: baseUrl, tokenStorage: _tokenStorage);
    _wsService = WebSocketService(baseUrl: baseUrl, tokenStorage: _tokenStorage);

    final authRemote = AuthRemoteDataSource(_apiClient);
    _authRepo = AuthRepositoryImpl(authRemote, storage: _tokenStorage);

    _loadOnboardingState();
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
    final seenOnboarding = _seenOnboarding;
    if (seenOnboarding == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: _authRepo),
        RepositoryProvider<WebSocketService>.value(value: _wsService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthCubit(
              storage: _tokenStorage,
              authRepo: _authRepo,
              wsService: _wsService,
            ),
          ),
          BlocProvider(create: (_) => RegistrationBloc(_authRepo)),
          BlocProvider(create: (_) => VerificationBloc(_authRepo)),
          BlocProvider(create: (_) => LoginBloc(_authRepo)),
        ],
        child: SuperAppNavigator(
          initialRoute: seenOnboarding ? '/splash' : '/onboarding',
        ),
      ),
    );
  }
}

class SuperAppNavigator extends StatelessWidget {
  final String initialRoute;

  const SuperAppNavigator({super.key, required this.initialRoute});

  bool _isAuthFree(String name) {
    return name == '/onboarding' ||
        name == '/splash' ||
        name == '/login' ||
        name == '/register' ||
        name == '/verify';
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: appNavigatorKey,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        Widget page;
        switch (name) {
          case '/onboarding':
            page = const OnboardingPage();
            break;
          case '/splash':
            page = const SplashPage();
            break;
          case '/login':
            page = const LoginPage();
            break;
          case '/register':
            page = const RegisterPage();
            break;
          case '/verify':
            page = const VerifyAccountPage(usernameOrEmail: '');
            break;
          case '/security':
            page = const SecurityPage();
            break;
          case '/sessions':
            page = const SessionsPage();
            break;
          case '/devices':
            page = const DevicesPage();
            break;
          case '/notifications':
            page = const NotificationsPage();
            break;
          case '/help-support':
            page = const HelpSupportPage();
            break;
          case '/profile/edit':
            page = const ProfilePage();
            break;
          case '/home':
          default:
            page = const SuperAppShell();
            break;
        }

        final guardedPage = _isAuthFree(name) ? page : _AuthGate(child: page);
        return MaterialPageRoute(settings: settings, builder: (_) => guardedPage);
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  final Widget child;

  const _AuthGate({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (prev, curr) =>
          prev.checking != curr.checking || prev.authenticated != curr.authenticated,
      builder: (context, state) {
        if (state.checking) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!state.authenticated) {
          return const LoginPage();
        }
        return child;
      },
    );
  }
}
