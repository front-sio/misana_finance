import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/meeting_bloc.dart';
import '../bloc/meeting_event.dart';
import '../bloc/meeting_state.dart';

class AudioCallPage extends StatefulWidget {
  final String bookingId;

  const AudioCallPage({super.key, required this.bookingId});

  @override
  State<AudioCallPage> createState() => _AudioCallPageState();
}

class _AudioCallPageState extends State<AudioCallPage> {
  @override
  void initState() {
    super.initState();
    _startMeeting();
  }

  Future<void> _startMeeting() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;
    if (!mounted) return;
    context.read<MeetingBloc>().add(RequestMeetingToken(widget.bookingId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Call')),
      body: BlocBuilder<MeetingBloc, MeetingState>(
        builder: (context, state) {
          final message = _statusMessage(state);
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (state.phase == MeetingPhase.joined) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => context.read<MeetingBloc>().add(const ToggleMute()),
                        icon: Icon(state.muted ? Icons.mic_off : Icons.mic),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => context.read<MeetingBloc>().add(const ToggleSpeaker()),
                        icon: Icon(state.speakerOn ? Icons.volume_up : Icons.volume_off),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<MeetingBloc>().add(const LeaveMeeting());
                    Navigator.of(context).pop();
                  },
                  child: const Text('Leave Call'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusMessage(MeetingState state) {
    switch (state.phase) {
      case MeetingPhase.loading:
        return 'Requesting meeting token...';
      case MeetingPhase.ready:
        return 'Connecting to audio room...';
      case MeetingPhase.joined:
        return 'Connected. You are in the audio session.';
      case MeetingPhase.left:
        return 'Call ended.';
      case MeetingPhase.error:
        return state.message ?? 'Failed to start meeting.';
      case MeetingPhase.initial:
      default:
        return 'Preparing audio call...';
    }
  }
}
