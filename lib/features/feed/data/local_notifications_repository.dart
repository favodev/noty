import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:noty/features/feed/domain/notification_item.dart';

class LocalNotificationsRepository {
  LocalNotificationsRepository({
    String databaseName = 'noty.db',
  }) : _databaseName = databaseName;

  static const String _tableName = 'notifications';

  final String _databaseName;
  Database? _database;

  Future<void> initialize() async {
    _database ??= await _openDatabase();
  }

  Future<void> dispose() async {
    final database = _database;
    if (database == null) {
      return;
    }

    await database.close();
    _database = null;
  }

  Future<List<NotificationItem>> getAll() async {
    final database = await _db;
    final rows = await database.query(
      _tableName,
      orderBy: 'received_at DESC',
    );

    return rows.map(_fromMap).toList();
  }

  Future<void> upsert(NotificationItem item) async {
    final database = await _db;
    await database.insert(
      _tableName,
      _toMap(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> seedIfEmpty(List<NotificationItem> seedItems) async {
    if (seedItems.isEmpty) {
      return;
    }

    final existingCount = await _count();
    if (existingCount > 0) {
      return;
    }

    final database = await _db;
    final batch = database.batch();

    for (final item in seedItems) {
      batch.insert(
        _tableName,
        _toMap(item),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<Database> get _db async {
    await initialize();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, _databaseName);

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (database, _) async {
        await database.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            app_name TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            received_at INTEGER NOT NULL,
            is_unread INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> _count() async {
    final database = await _db;
    final result = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM $_tableName'),
    );

    return result ?? 0;
  }

  NotificationItem _fromMap(Map<String, Object?> row) {
    return NotificationItem(
      id: row['id']! as String,
      appName: row['app_name']! as String,
      title: row['title']! as String,
      body: row['body']! as String,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(row['received_at']! as int),
      isUnread: (row['is_unread']! as int) == 1,
    );
  }

  Map<String, Object?> _toMap(NotificationItem item) {
    return <String, Object?>{
      'id': item.id,
      'app_name': item.appName,
      'title': item.title,
      'body': item.body,
      'received_at': item.receivedAt.millisecondsSinceEpoch,
      'is_unread': item.isUnread ? 1 : 0,
    };
  }
}