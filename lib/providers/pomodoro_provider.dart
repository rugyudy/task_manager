import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PomodoroMode { work, breakTime }

class PomodoroState {
  const PomodoroState({
    required this.mode,
    required this.remaining,
    required this.running,
    required this.completedSessions,
  });

  static const workDuration = Duration(minutes: 25);
  static const breakDuration = Duration(minutes: 5);

  final PomodoroMode mode;
  final Duration remaining;
  final bool running;
  final int completedSessions;

  PomodoroState copyWith({Duration? remaining, bool? running}) => PomodoroState(
        mode: mode,
        remaining: remaining ?? this.remaining,
        running: running ?? this.running,
        completedSessions: completedSessions,
      );
}

/// 集中作業用のポモドーロタイマー（25分作業 / 5分休憩）。
/// アプリ内でグローバルに1つだけ動作し、ホーム画面上の配置を変えても状態は保持される。
class PomodoroNotifier extends Notifier<PomodoroState> {
  Timer? _timer;

  @override
  PomodoroState build() {
    ref.onDispose(() => _timer?.cancel());
    return const PomodoroState(
      mode: PomodoroMode.work,
      remaining: PomodoroState.workDuration,
      running: false,
      completedSessions: 0,
    );
  }

  void start() {
    if (state.running) return;
    state = state.copyWith(running: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(running: false);
  }

  void reset() {
    _timer?.cancel();
    state = PomodoroState(
      mode: state.mode,
      remaining: state.mode == PomodoroMode.work
          ? PomodoroState.workDuration
          : PomodoroState.breakDuration,
      running: false,
      completedSessions: state.completedSessions,
    );
  }

  void _tick() {
    if (state.remaining.inSeconds <= 1) {
      final nextMode = state.mode == PomodoroMode.work ? PomodoroMode.breakTime : PomodoroMode.work;
      final completed =
          state.mode == PomodoroMode.work ? state.completedSessions + 1 : state.completedSessions;
      state = PomodoroState(
        mode: nextMode,
        remaining:
            nextMode == PomodoroMode.work ? PomodoroState.workDuration : PomodoroState.breakDuration,
        running: true,
        completedSessions: completed,
      );
      return;
    }
    state = state.copyWith(remaining: state.remaining - const Duration(seconds: 1));
  }
}

final pomodoroProvider = NotifierProvider<PomodoroNotifier, PomodoroState>(PomodoroNotifier.new);
