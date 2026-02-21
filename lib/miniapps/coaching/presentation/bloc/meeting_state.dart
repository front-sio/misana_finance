import 'package:equatable/equatable.dart';
import '../../data/models.dart';

enum MeetingPhase { initial, loading, ready, joined, left, error }

class MeetingState extends Equatable {
  final MeetingPhase phase;
  final MeetingToken? token;
  final bool muted;
  final bool speakerOn;
  final String? message;

  const MeetingState({
    required this.phase,
    this.token,
    this.muted = false,
    this.speakerOn = true,
    this.message,
  });

  MeetingState copyWith({
    MeetingPhase? phase,
    MeetingToken? token,
    bool? muted,
    bool? speakerOn,
    String? message,
  }) {
    return MeetingState(
      phase: phase ?? this.phase,
      token: token ?? this.token,
      muted: muted ?? this.muted,
      speakerOn: speakerOn ?? this.speakerOn,
      message: message,
    );
  }

  @override
  List<Object?> get props => [phase, token, muted, speakerOn, message];
}

const MeetingState meetingInitial = MeetingState(phase: MeetingPhase.initial);
