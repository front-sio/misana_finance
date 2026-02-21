import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/coaching_repository.dart';
import 'meeting_event.dart';
import 'meeting_state.dart';

class MeetingBloc extends Bloc<MeetingEvent, MeetingState> {
  final CoachingRepository repo;
  RtcEngine? _engine;

  MeetingBloc(this.repo) : super(meetingInitial) {
    on<RequestMeetingToken>(_onRequestToken);
    on<JoinMeeting>(_onJoin);
    on<LeaveMeeting>(_onLeave);
    on<ToggleMute>(_onToggleMute);
    on<ToggleSpeaker>(_onToggleSpeaker);
  }

  Future<void> _onRequestToken(RequestMeetingToken event, Emitter<MeetingState> emit) async {
    emit(state.copyWith(phase: MeetingPhase.loading, message: null));
    try {
      final token = await repo.requestMeetingToken(bookingId: event.bookingId);
      emit(state.copyWith(phase: MeetingPhase.ready, token: token));
      add(const JoinMeeting());
    } catch (e) {
      emit(state.copyWith(phase: MeetingPhase.error, message: e.toString()));
    }
  }

  Future<void> _onJoin(JoinMeeting event, Emitter<MeetingState> emit) async {
    final token = state.token;
    if (token == null) {
      emit(state.copyWith(phase: MeetingPhase.error, message: 'Missing meeting token.'));
      return;
    }

    try {
      _engine ??= createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(appId: token.appId));
      await _engine!.enableAudio();
      await _engine!.setChannelProfile(ChannelProfileType.channelProfileCommunication);
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.setEnableSpeakerphone(state.speakerOn);

      await _engine!.joinChannel(
        token: token.token,
        channelId: token.channelName,
        uid: token.uid,
        options: const ChannelMediaOptions(),
      );

      emit(state.copyWith(phase: MeetingPhase.joined));
    } catch (e) {
      emit(state.copyWith(phase: MeetingPhase.error, message: e.toString()));
    }
  }

  Future<void> _onLeave(LeaveMeeting event, Emitter<MeetingState> emit) async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;
      emit(state.copyWith(phase: MeetingPhase.left));
    } catch (e) {
      emit(state.copyWith(phase: MeetingPhase.error, message: e.toString()));
    }
  }

  Future<void> _onToggleMute(ToggleMute event, Emitter<MeetingState> emit) async {
    final next = !state.muted;
    await _engine?.muteLocalAudioStream(next);
    emit(state.copyWith(muted: next));
  }

  Future<void> _onToggleSpeaker(ToggleSpeaker event, Emitter<MeetingState> emit) async {
    final next = !state.speakerOn;
    await _engine?.setEnableSpeakerphone(next);
    emit(state.copyWith(speakerOn: next));
  }

  @override
  Future<void> close() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {}
    _engine = null;
    return super.close();
  }
}
