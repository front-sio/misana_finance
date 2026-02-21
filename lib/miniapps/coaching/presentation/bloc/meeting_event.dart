import 'package:equatable/equatable.dart';

abstract class MeetingEvent extends Equatable {
  const MeetingEvent();

  @override
  List<Object?> get props => [];
}

class RequestMeetingToken extends MeetingEvent {
  final String bookingId;
  const RequestMeetingToken(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
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
