import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;
  static const _dbName = 'studyflow.db';
  static const _dbVersion = 4;
  static bool _factoryReady = false;

  /// Call once before opening the database (required on web).
  static void ensureFactory() {
    if (_factoryReady) return;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
    _factoryReady = true;
  }

  Future<Database> get database async {
    ensureFactory();
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Web IndexedDB path is just the file name; mobile/desktop uses app data dir.
    final dbPath = kIsWeb ? _dbName : join(await getDatabasesPath(), _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        streak INTEGER NOT NULL DEFAULT 0,
        xp INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        code TEXT,
        color TEXT NOT NULL DEFAULT '#5B5FEF',
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        course_id INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        deadline TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'todo'
          CHECK (status IN ('todo', 'doing', 'done', 'overdue')),
        priority TEXT NOT NULL DEFAULT 'medium'
          CHECK (priority IN ('low', 'medium', 'high')),
        progress INTEGER NOT NULL DEFAULT 0
          CHECK (progress >= 0 AND progress <= 100),
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE flashcards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        course_id INTEGER,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        mastered INTEGER NOT NULL DEFAULT 0,
        interval_days INTEGER NOT NULL DEFAULT 1,
        ease_factor REAL NOT NULL DEFAULT 2.5,
        review_count INTEGER NOT NULL DEFAULT 0,
        next_review TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE srs_reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        flashcard_id INTEGER NOT NULL,
        correct INTEGER NOT NULL,
        reviewed_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (flashcard_id) REFERENCES flashcards (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        course_id INTEGER,
        duration_min INTEGER NOT NULL CHECK (duration_min > 0),
        type TEXT NOT NULL DEFAULT 'pomodoro'
          CHECK (type IN ('pomodoro', 'review', 'manual')),
        started_at TEXT NOT NULL,
        ended_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        badge_code TEXT NOT NULL,
        earned_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE (user_id, badge_code)
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        prompt_type TEXT NOT NULL,
        prompt_hash TEXT NOT NULL,
        response TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await _createNotificationsTable(db);
    await _createAiNotesTable(db);

    await db.execute(
      'CREATE INDEX idx_tasks_user_deadline ON tasks (user_id, deadline)',
    );
    await db.execute('CREATE INDEX idx_tasks_status ON tasks (status)');
    await db.execute(
      'CREATE INDEX idx_flashcards_next_review ON flashcards (next_review)',
    );
    await db.execute(
      'CREATE INDEX idx_study_sessions_user ON study_sessions (user_id, started_at)',
    );
    await db.execute('CREATE INDEX idx_courses_user ON courses (user_id)');
  }

  Future<void> _createNotificationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'info',
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications (user_id, created_at)',
    );
  }

  Future<void> _createAiNotesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        course_id INTEGER,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual'
          CHECK (source IN ('manual', 'chat', 'explain', 'study_plan', 'history', 'link')),
        tags TEXT NOT NULL DEFAULT '',
        is_pinned INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE SET NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_notes_user ON ai_notes (user_id, updated_at)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createNotificationsTable(db);
    }
    if (oldVersion < 3) {
      await _createAiNotesTable(db);
    }
    if (oldVersion < 4) {
      await _migrateAiNotesAllowLinkSource(db);
    }
  }

  /// SQLite cannot ALTER CHECK — rebuild ai_notes to allow source='link'.
  Future<void> _migrateAiNotesAllowLinkSource(Database db) async {
    await db.execute('ALTER TABLE ai_notes RENAME TO ai_notes_old');
    await db.execute('''
      CREATE TABLE ai_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        course_id INTEGER,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual'
          CHECK (source IN ('manual', 'chat', 'explain', 'study_plan', 'history', 'link')),
        tags TEXT NOT NULL DEFAULT '',
        is_pinned INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      INSERT INTO ai_notes (
        id, user_id, course_id, title, content, source, tags,
        is_pinned, created_at, updated_at
      )
      SELECT
        id, user_id, course_id, title, content, source, tags,
        is_pinned, created_at, updated_at
      FROM ai_notes_old
    ''');
    await db.execute('DROP TABLE ai_notes_old');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_notes_user ON ai_notes (user_id, updated_at)',
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
