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

  /// Closes the database. Used by tests; the app itself never closes it.
  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
}
