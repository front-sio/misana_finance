import 'package:equatable/equatable.dart';

abstract class MeetingEvent extends Equatable {
  const MeetingEvent();

  @override
  List<Object?> get props => [];
}

class RequestMeetingToken extends MeetingEvent {
  final String bookingId;
  final bool asCoach;
  const RequestMeetingToken(this.bookingId, {this.asCoach = false});

  @override
  List<Object?> get props => [bookingId, asCoach];
}

class JoinMeeting extends MeetingEvent {
  const JoinMeeting();
}

class LeaveMeeting extends MeetingEvent {
  const LeaveMeeting();
}

class ToggleMute extends MeetingEvent {
  const ToggleMute();
}

class ToggleSpeaker extends MeetingEvent {
  const ToggleSpeaker();
}
