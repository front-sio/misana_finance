import 'dart:async';

class Debouncer {
  final Duration duration;
  Timer? _timer;

  Debouncer(this.duration);

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}