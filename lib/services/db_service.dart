import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/word.dart';
import '../models/topic.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('language_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create words table.
    // 'english' has a UNIQUE constraint and COLLATE NOCASE to enforce case-insensitive uniqueness.
    await db.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        english TEXT UNIQUE COLLATE NOCASE,
        turkish TEXT,
        phonetic TEXT,
        sync_status TEXT,
        created_at TEXT
      )
    ''');

    // Create cached topics table.
    await db.execute('''
      CREATE TABLE topics (
        id TEXT PRIMARY KEY,
        name TEXT,
        category TEXT,
        cached_at TEXT
      )
    ''');
  }

  // --- Word Operations ---

  /// Inserts a word. If the word already exists (violating the UNIQUE constraint),
  /// it quietly ignores it and returns -1 instead of throwing an exception.
  Future<int> insertWord(Word word) async {
    final db = await database;
    try {
      return await db.insert(
        'words',
        word.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      // Catch-all to ensure absolutely no crash or user-facing error is thrown
      return -1;
    }
  }

  Future<List<Word>> getWords() async {
    final db = await database;
    final maps = await db.query('words', orderBy: 'created_at DESC');
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<List<Word>> getPendingSyncWords() async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
    );
    return maps.map((map) => Word.fromMap(map)).toList();
  }

  Future<int> updateWord(Word word) async {
    final db = await database;
    return await db.update(
      'words',
      word.toMap(),
      where: 'id = ?',
      whereArgs: [word.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteWord(int id) async {
    final db = await database;
    return await db.delete(
      'words',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Topic Operations ---

  Future<int> insertTopic(Topic topic) async {
    final db = await database;
    return await db.insert(
      'topics',
      topic.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Topic>> getTopics() async {
    final db = await database;
    final maps = await db.query('topics');
    return maps.map((map) => Topic.fromMap(map)).toList();
  }

  Future<void> replaceTopics(List<Topic> newTopics) async {
    final db = await database;
    final batch = db.batch();
    
    // We overwrite/refresh by clearing old topics and batch-inserting the new ones
    batch.delete('topics');
    for (var topic in newTopics) {
      batch.insert('topics', topic.toMap());
    }
    
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
