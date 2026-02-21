import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:misana_finance_app/core/navigation/nav.dart';
import 'package:misana_finance_app/core/network/api_client.dart';
import 'package:misana_finance_app/core/storage/token_storage.dart';

import 'coaching_routes.dart';
import 'data/coaching_remote_data_source.dart';
import 'data/coaching_repository_impl.dart';
import 'domain/coaching_repository.dart';
import 'presentation/bloc/booking_bloc.dart';
import 'presentation/bloc/coaches_bloc.dart';
import 'presentation/bloc/meeting_bloc.dart';
import 'presentation/bloc/payment_bloc.dart';
import 'presentation/bloc/slots_bloc.dart';
import 'presentation/pages/coaching_home_page.dart';
import 'presentation/pages/topic_details_page.dart';
import 'presentation/pages/pick_slot_page.dart';
import 'presentation/pages/checkout_page.dart';
import 'presentation/pages/payment_status_page.dart';
import 'presentation/pages/booking_details_page.dart';
import 'presentation/pages/audio_call_page.dart';
import 'data/models.dart';

class CoachingApp extends StatefulWidget {
  final bool embedded;
  final String initialRoute;
  final GlobalKey<NavigatorState>? navigatorKey;

  const CoachingApp({
    super.key,
    this.embedded = false,
    this.initialRoute = CoachingRoutes.home,
    this.navigatorKey,
  });

  const CoachingApp.embedded({
    super.key,
    this.initialRoute = CoachingRoutes.home,
  }) : embedded = true,
       navigatorKey = null;

  @override
  State<CoachingApp> createState() => _CoachingAppState();
}

class _CoachingAppState extends State<CoachingApp> {
  late final TokenStorage _tokenStorage;
  late final ApiClient _apiClient;
  late final CoachingRepository _repo;

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
    _repo = CoachingRepositoryImpl(CoachingRemoteDataSource(_apiClient));
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [RepositoryProvider<CoachingRepository>.value(value: _repo)],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CoachesBloc(_repo)),
          BlocProvider(create: (_) => SlotsBloc(_repo)),
          BlocProvider(create: (_) => BookingBloc(_repo)),
          BlocProvider(create: (_) => PaymentBloc(_repo)),
          BlocProvider(create: (_) => MeetingBloc(_repo)),
        ],
        child: CoachingNavigator(
          initialRoute: widget.initialRoute,
          embedded: widget.embedded,
          navigatorKey: widget.embedded
              ? null
              : (widget.navigatorKey ?? appNavigatorKey),
        ),
      ),
    );
  }
}

class CoachingNavigator extends StatefulWidget {
  final String initialRoute;
  final GlobalKey<NavigatorState>? navigatorKey;
  final bool embedded;

  const CoachingNavigator({
    super.key,
    this.initialRoute = CoachingRoutes.home,
    this.navigatorKey,
    this.embedded = false,
  });

  @override
  State<CoachingNavigator> createState() => _CoachingNavigatorState();
}

class _CoachingNavigatorState extends State<CoachingNavigator> {
  late final GlobalKey<NavigatorState> _localNavKey =
      GlobalKey<NavigatorState>();

  GlobalKey<NavigatorState> get _navKey => widget.navigatorKey ?? _localNavKey;

  @override
  Widget build(BuildContext context) {
    final nestedNavigator = Navigator(
      key: _navKey,
      initialRoute: widget.initialRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case CoachingRoutes.home:
          case '/':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const CoachingHomePage(),
            );
          case CoachingRoutes.topic:
            final topic = settings.arguments;
            if (topic is! Topic) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const CoachingHomePage(),
              );
            }
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => TopicDetailsPage(topic: topic),
            );
          case CoachingRoutes.slots:
            final topic = settings.arguments;
            if (topic is! Topic) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const CoachingHomePage(),
              );
            }
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => PickSlotPage(topic: topic),
            );
          case CoachingRoutes.checkout:
            final args = settings.arguments;
            if (args is! Map<String, dynamic> ||
                args['topic'] is! Topic ||
                args['slot'] is! AvailabilitySlot) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const CoachingHomePage(),
              );
            }
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => CheckoutPage(
                topic: args['topic'] as Topic,
                slot: args['slot'] as AvailabilitySlot,
              ),
            );
          case CoachingRoutes.payment:
            final args = settings.arguments;
            if (args is! Map<String, dynamic> ||
                args['bookingId'] is! String ||
                args['phoneNumber'] is! String) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const CoachingHomePage(),
              );
            }
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => PaymentStatusPage(
                bookingId: args['bookingId'] as String,
                phoneNumber: args['phoneNumber'] as String,
              ),
            );
          case CoachingRoutes.booking:
            final bookingId = settings.arguments;
            if (bookingId is! String) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const CoachingHomePage(),
              );
            }
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => BookingDetailsPage(bookingId: bookingId),
            );
          case CoachingRoutes.call:
            final bookingId = settings.arguments;
            if (bookingId is! String) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const CoachingHomePage(),
              );
            }
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => AudioCallPage(bookingId: bookingId),
            );
          default:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const CoachingHomePage(),
            );
        }
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
