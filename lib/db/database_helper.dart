import '../models/focus_task.dart';
import '../models/session_record.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite storage for FocusForge. Four tables:
///
/// * `tasks` — the user's study tasks.
/// * `sessions` — every finished (or abandoned) timer run.
/// * `settings` — a single row (id = 1) with the timer configuration.
/// * `timer_state` — a single row (id = 1) holding the live timer so it
///   survives the app being killed or the phone restarting.
///
/// The app starts with an empty database: no seed tasks, no demo sessions.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'focusforge.db';
  static const int _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    final db = _db;
    if (db != null) return db;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = await getDatabasesPath();
    return openDatabase(
      '$path/$_dbName',
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            notes TEXT NOT NULL DEFAULT '',
            color_value INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            total_focus_seconds INTEGER NOT NULL DEFAULT 0,
            completed_sessions INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER,
            phase TEXT NOT NULL,
            started_at INTEGER NOT NULL,
            ended_at INTEGER NOT NULL,
            planned_seconds INTEGER NOT NULL,
            actual_seconds INTEGER NOT NULL,
            completed INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY,
            focus_minutes INTEGER NOT NULL,
            short_break_minutes INTEGER NOT NULL,
            long_break_minutes INTEGER NOT NULL,
            sessions_before_long_break INTEGER NOT NULL,
            daily_goal_minutes INTEGER NOT NULL,
            daily_goal_sessions INTEGER NOT NULL,
            sound_enabled INTEGER NOT NULL,
            vibration_enabled INTEGER NOT NULL,
            auto_start_breaks INTEGER NOT NULL,
            auto_start_focus INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE timer_state (
            id INTEGER PRIMARY KEY,
            phase TEXT NOT NULL,
            remaining_seconds INTEGER NOT NULL,
            total_seconds INTEGER NOT NULL,
            ends_at INTEGER,
            is_running INTEGER NOT NULL,
            task_id INTEGER,
            started_at INTEGER NOT NULL,
            completed_in_cycle INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ------------------------------------------------------------------
  // Tasks
  // ------------------------------------------------------------------

  Future<int> insertTask(FocusTask task) async {
    final db = await database;
    return db.insert('tasks', task.toMap());
  }

  Future<List<FocusTask>> getAllTasks() async {
    final db = await database;
    final rows = await db.query(
      'tasks',
      orderBy: 'is_completed ASC, created_at DESC',
    );
    return rows.map(FocusTask.fromMap).toList();
  }

  Future<List<FocusTask>> getActiveTasks() async {
    final db = await database;
    final rows = await db.query(
      'tasks',
      where: 'is_completed = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return rows.map(FocusTask.fromMap).toList();
  }

  Future<FocusTask?> getTaskById(int id) async {
    final db = await database;
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return FocusTask.fromMap(rows.first);
  }

  Future<int> updateTask(FocusTask task) async {
    final db = await database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  /// Adds completed focus time to a task after a session ends.
  Future<void> addFocusTimeToTask(int taskId, int seconds) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE tasks
      SET total_focus_seconds = total_focus_seconds + ?,
          completed_sessions = completed_sessions + 1
      WHERE id = ?
      ''',
      [seconds, taskId],
    );
  }

  // ------------------------------------------------------------------
  // Sessions
  // ------------------------------------------------------------------

  Future<int> insertSession(SessionRecord session) async {
    final db = await database;
    return db.insert('sessions', session.toMap());
  }

  /// Most recent sessions first, newest at the top of the history list.
  Future<List<SessionRecord>> getRecentSessions({int limit = 100}) async {
    final db = await database;
    final rows = await db.query(
      'sessions',
      orderBy: 'ended_at DESC',
      limit: limit,
    );
    return rows.map(SessionRecord.fromMap).toList();
  }

  /// Completed focus sessions between two instants (inclusive).
  Future<List<SessionRecord>> getFocusSessionsBetween(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;
    final rows = await db.query(
      'sessions',
      where: 'phase = ? AND completed = 1 AND ended_at >= ? AND ended_at <= ?',
      whereArgs: [
        'focus',
        from.millisecondsSinceEpoch,
        to.millisecondsSinceEpoch,
      ],
      orderBy: 'ended_at ASC',
    );
    return rows.map(SessionRecord.fromMap).toList();
  }

  /// Total completed focus seconds across all time.
  Future<int> getTotalFocusSeconds() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT COALESCE(SUM(actual_seconds), 0) AS total FROM sessions "
      "WHERE phase = 'focus' AND completed = 1",
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  /// Number of completed focus sessions across all time.
  Future<int> getTotalCompletedSessions() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM sessions "
      "WHERE phase = 'focus' AND completed = 1",
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAllSessions() async {
    final db = await database;
    return db.delete('sessions');
  }

  /// Closes the database. Used by tests; the app itself never closes it.
  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
}
