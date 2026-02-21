import 'package:flutter_bloc/flutter_bloc.dart';

import 'coaching_event.dart';
import 'coaching_state.dart';

class CoachingBloc extends Bloc<CoachingEvent, CoachingState> {
  CoachingBloc() : super(const CoachingInitial()) {
    on<CoachingStarted>((event, emit) {});
  }
}
