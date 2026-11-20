import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../db/database_helper.dart';
import '../models/app_settings.dart';
import '../models/focus_task.dart';
import '../models/session_record.dart';
import '../models/timer_phase.dart';
import 'focus_timer.dart';
import 'notification_service.dart';

/// The single source of truth for the timer screen.
///
/// Owns the [FocusTimer] state machine, persists every change to SQLite,
/// logs finished sessions, fires the end-of-session alert, and restores a
/// running timer after the app was killed.
class TimerController extends ChangeNotifier {
  TimerController({
    DatabaseHelper? db,
    NotificationService? notifications,
  })  : _db = db ?? DatabaseHelper.instance,
        _notifications = notifications ?? NotificationService() {
    _timer = FocusTimer(
      settings: _settings,
      onPhaseFinished: _onPhaseFinished,
    );
  }

  final DatabaseHelper _db;
  final NotificationService _notifications;
  late final FocusTimer _timer;

  AppSettings _settings = AppSettings();
  List<FocusTask> tasks = [];
  FocusTask? currentTask;
  List<SessionRecord> recentSessions = [];

  bool _initialized = false;
  bool get initialized => _initialized;

  Timer? _ticker;

  // --- Read-only views of the timer state -----------------------------

  TimerPhase get phase => _timer.phase;
  TimerStatus get status => _timer.status;
  int get totalSeconds => _timer.totalSeconds;
  int get remainingSeconds => _timer.remainingSeconds;
  double get progress => _timer.progress;
  int get completedInCycle => _timer.completedInCycle;
  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isIdle => status == TimerStatus.idle;

  AppSettings get settings => _settings;

  /// Loads settings, tasks and history, then restores a saved timer.
  Future<void> init() async {
    if (_initialized) return;
    _settings = await _db.getSettings();
    _timer.settings = _settings;
    tasks = await _db.getAllTasks();
    recentSessions = await _db.getRecentSessions(limit: 50);
    await _notifications.init();
    await _restoreSavedTimer();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _initialized = true;
    notifyListeners();
  }

  Future<void> _restoreSavedTimer() async {
    final saved = await _db.getTimerState();
    if (saved == null) return;
    final phase = TimerPhaseLabel.fromStorageKey(
      (saved['phase'] as String?) ?? 'focus',
    );
    final taskId = saved['task_id'] as int?;
    if (taskId != null) {
      currentTask = tasks.where((t) => t.id == taskId).firstOrNull;
    }
    _timer.restore(
      savedPhase: phase,
      savedRemainingSeconds: (saved['remaining_seconds'] as int?) ?? 0,
      savedTotalSeconds: (saved['total_seconds'] as int?) ?? 0,
      savedIsRunning: ((saved['is_running'] as int?) ?? 0) == 1,
      savedEndsAt: saved['ends_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(saved['ends_at'] as int),
      savedTaskId: taskId,
      savedStartedAt: DateTime.fromMillisecondsSinceEpoch(
        (saved['started_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      savedCompletedInCycle: (saved['completed_in_cycle'] as int?) ?? 0,
    );
    // If the timer finished while the app was dead, restore() already fired
    // the phase-finished callback and logged it; nothing else to do here.
    await _persistTimerState();
  }

  void _onTick() {
    if (!isRunning) return;
    _timer.syncFromEndsAt(DateTime.now());
    notifyListeners();
  }

  // --- Timer controls -------------------------------------------------

  Future<void> start() async {
    _timer.taskId = currentTask?.id;
    _timer.start();
    await _persistTimerState();
    notifyListeners();
  }

  Future<void> pause() async {
    _timer.pause();
    await _persistTimerState();
    notifyListeners();
  }

  Future<void> reset() async {
    _timer.reset();
    await _persistTimerState();
    notifyListeners();
  }

  /// Ends the current phase early. A focus phase skipped after at least
  /// 60 seconds is logged as an incomplete session.
  Future<void> skip() async {
    final wasFocus = _timer.isFocusPhase;
    final elapsed = _timer.totalSeconds - _timer.remainingSeconds;
    final startedAt = _timer.startedAt;
    final taskId = currentTask?.id;
    _timer.skip();
    if (wasFocus && elapsed >= 60 && startedAt != null) {
      await _logSession(
        phase: TimerPhase.focus,
        startedAt: startedAt,
        plannedSeconds: _timer.totalSeconds,
        actualSeconds: elapsed,
        completed: false,
        taskId: taskId,
      );
    }
    await _persistTimerState();
    notifyListeners();
  }

  Future<void> selectPhase(TimerPhase newPhase) async {
    _timer.selectPhase(newPhase);
    await _persistTimerState();
    notifyListeners();
  }

  Future<void> selectTask(FocusTask? task) async {
    currentTask = task;
    _timer.taskId = task?.id;
    await _persistTimerState();
    notifyListeners();
  }

  Future<void> _persistTimerState() async {
    await _db.saveTimerState(
      phase: _timer.phase,
      remainingSeconds: _timer.remainingSeconds,
      totalSeconds: _timer.totalSeconds,
      endsAt: _timer.endsAt,
      isRunning: _timer.status == TimerStatus.running,
      taskId: currentTask?.id,
      startedAt: _timer.startedAt ?? DateTime.now(),
      completedInCycle: _timer.completedInCycle,
    );
  }

  // --- Phase completion -----------------------------------------------

  Future<void> _onPhaseFinished(TimerPhase phase, bool completed) async {
    if (!completed) {
      // Skipped phases are logged by skip() itself, not here.
      await _persistTimerState();
      notifyListeners();
      return;
    }
    final startedAt = _timer.lastFinishedStartedAt ?? DateTime.now();
    final planned = _timer.lastFinishedPlannedSeconds;
    final actual = _timer.lastFinishedActualSeconds;
    final taskId = _timer.lastFinishedTaskId;
    await _logSession(
      phase: phase,
      startedAt: startedAt,
      plannedSeconds: planned,
      actualSeconds: actual,
      completed: true,
      taskId: phase == TimerPhase.focus ? taskId : null,
    );
    await _notifications.showPhaseComplete(
      phase,
      sound: _settings.soundEnabled,
      vibrationEnabled: _settings.vibrationEnabled,
    );
    // Auto-start the next phase when the user asked for it.
    if (phase == TimerPhase.focus && _settings.autoStartBreaks) {
      await start();
      return;
    }
    if (phase != TimerPhase.focus && _settings.autoStartFocus) {
      await start();
      return;
    }
    await _persistTimerState();
    notifyListeners();
  }

  Future<void> _logSession({
    required TimerPhase phase,
    required DateTime startedAt,
    required int plannedSeconds,
    required int actualSeconds,
    required bool completed,
    int? taskId,
  }) async {
    final record = SessionRecord(
      taskId: taskId,
      phase: phase,
      startedAt: startedAt,
      endedAt: DateTime.now(),
      plannedSeconds: plannedSeconds,
      actualSeconds: actualSeconds,
      completed: completed,
    );
    await _db.insertSession(record);
    if (phase == TimerPhase.focus && completed && taskId != null) {
      await _db.addFocusTimeToTask(taskId, actualSeconds);
      tasks = await _db.getAllTasks();
    }
    recentSessions = await _db.getRecentSessions(limit: 50);
  }

  // --- Tasks ------------------------------------------------------------

  Future<void> addTask(String title, {String notes = ''}) async {
    const colors = <int>[
      0xFFEF6C00,
      0xFF2E7D32,
      0xFF1565C0,
      0xFF6A1B9A,
      0xFFC62828,
      0xFF00838F,
    ];
    final color = colors[tasks.length % colors.length];
    await _db.insertTask(FocusTask(title: title, notes: notes, colorValue: color));
    tasks = await _db.getAllTasks();
    notifyListeners();
  }

  Future<void> updateTask(FocusTask task) async {
    await _db.updateTask(task);
    if (currentTask?.id == task.id) currentTask = task;
    tasks = await _db.getAllTasks();
    notifyListeners();
  }

  Future<void> toggleTaskComplete(FocusTask task) async {
    await updateTask(task.copyWith(isCompleted: !task.isCompleted));
  }

  Future<void> deleteTask(FocusTask task) async {
    if (currentTask?.id == task.id) {
      currentTask = null;
      _timer.taskId = null;
    }
    await _db.deleteTask(task.id!);
    tasks = await _db.getAllTasks();
    await _persistTimerState();
    notifyListeners();
  }

  // --- Settings -----------------------------------------------------------

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    _timer.settings = newSettings;
    await _db.saveSettings(newSettings);
    if (isIdle) {
      _timer.reset();
      await _persistTimerState();
    }
    notifyListeners();
  }

  Future<void> requestNotificationPermission() async {
    await _notifications.requestPermission();
  }

  // --- Stats ---------------------------------------------------------------

  Future<int> totalFocusSeconds() => _db.getTotalFocusSeconds();

  Future<int> totalCompletedSessions() => _db.getTotalCompletedSessions();

  Future<List<SessionRecord>> focusSessionsBetween(
    DateTime from,
    DateTime to,
  ) =>
      _db.getFocusSessionsBetween(from, to);

  Future<void> clearHistory() async {
    await _db.clearAllSessions();
    recentSessions = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
