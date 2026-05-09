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

  Future<void> deleteAll() async {
    final database = await _db;
    await database.delete(_tableName);
  }

  Future<List<NotificationItem>> getPendingSync({int limit = 50}) async {
    final database = await _db;
    final rows = await database.query(
      _tableName,
      where: 'sync_state IN (?, ?)',
      whereArgs: const <String>[NotificationSyncState.pending, NotificationSyncState.error],
      orderBy: 'received_at ASC',
      limit: limit,
    );

    return rows.map(_fromMap).toList();
  }

  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    final database = await _db;
    final batch = database.batch();

    for (final id in ids) {
      batch.update(
        _tableName,
        <String, Object?>{
          'sync_state': NotificationSyncState.synced,
          'sync_error': null,
        },
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> markAsSyncFailed(String id, String errorMessage) async {
    final database = await _db;
    await database.rawUpdate(
      '''
      UPDATE $_tableName
      SET sync_state = ?,
          sync_error = ?,
          sync_attempts = sync_attempts + 1
      WHERE id = ?
      ''',
      <Object?>[
        NotificationSyncState.error,
        errorMessage,
        id,
      ],
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
      version: 2,
      onCreate: (database, _) async {
        await database.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            app_name TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            received_at INTEGER NOT NULL,
            is_unread INTEGER NOT NULL,
            sync_state TEXT NOT NULL DEFAULT '${NotificationSyncState.pending}',
            sync_attempts INTEGER NOT NULL DEFAULT 0,
            sync_error TEXT
          )
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            "ALTER TABLE $_tableName ADD COLUMN sync_state TEXT NOT NULL DEFAULT '${NotificationSyncState.pending}'",
          );
          await database.execute(
            'ALTER TABLE $_tableName ADD COLUMN sync_attempts INTEGER NOT NULL DEFAULT 0',
          );
          await database.execute('ALTER TABLE $_tableName ADD COLUMN sync_error TEXT');
        }
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
      syncState: (row['sync_state'] as String?) ?? NotificationSyncState.pending,
      syncAttempts: (row['sync_attempts'] as int?) ?? 0,
      syncError: row['sync_error'] as String?,
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
      'sync_state': item.syncState,
      'sync_attempts': item.syncAttempts,
      'sync_error': item.syncError,
    };
  }
}