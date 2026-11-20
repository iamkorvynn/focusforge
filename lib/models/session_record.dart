import 'timer_phase.dart';

/// One recorded timer run. A session is written when a focus phase (or a
/// break) finishes, and also when the user abandons it early — the
/// `completed` flag tells the two apart for stats.
class SessionRecord {
  SessionRecord({
    this.id,
    this.taskId,
    required this.phase,
    required this.startedAt,
    required this.endedAt,
    required this.plannedSeconds,
    required this.actualSeconds,
    this.completed = true,
  });

  final int? id;
  final int? taskId;
  final TimerPhase phase;
  final DateTime startedAt;
  final DateTime endedAt;
  final int plannedSeconds;
  final int actualSeconds;
  final bool completed;

  /// Focus time actually spent, in whole minutes.
  int get focusMinutes => actualSeconds ~/ 60;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'phase': phase.storageKey,
      'started_at': startedAt.millisecondsSinceEpoch,
      'ended_at': endedAt.millisecondsSinceEpoch,
      'planned_seconds': plannedSeconds,
      'actual_seconds': actualSeconds,
      'completed': completed ? 1 : 0,
    };
  }

  factory SessionRecord.fromMap(Map<String, Object?> map) {
    return SessionRecord(
      id: map['id'] as int?,
      taskId: map['task_id'] as int?,
      phase: TimerPhaseLabel.fromStorageKey(
        (map['phase'] as String?) ?? 'focus',
      ),
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['started_at'] as int?) ?? 0,
      ),
      endedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['ended_at'] as int?) ?? 0,
      ),
      plannedSeconds: (map['planned_seconds'] as int?) ?? 0,
      actualSeconds: (map['actual_seconds'] as int?) ?? 0,
      completed: ((map['completed'] as int?) ?? 1) == 1,
    );
  }
}
