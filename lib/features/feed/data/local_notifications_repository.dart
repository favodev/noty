import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:noty/features/feed/domain/notification_item.dart';

class LocalNotificationsRepository {
  LocalNotificationsRepository({String databaseName = 'noty.db'})
    : _databaseName = databaseName;

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
    final rows = await database.query(_tableName, orderBy: 'received_at DESC');

    return rows.map(_fromMap).toList();
  }

  Future<void> upsert(NotificationItem item) async {
    final database = await _db;
    final existingRows = await database.query(
      _tableName,
      columns: const <String>['is_unread', 'media_path'],
      where: 'id = ?',
      whereArgs: <Object?>[item.id],
      limit: 1,
    );
    final shouldPreserveReadState =
        existingRows.isNotEmpty && existingRows.first['is_unread'] == 0;
    final previousMediaPath = existingRows.isEmpty
        ? null
        : existingRows.first['media_path']?.toString();

    await database.insert(
      _tableName,
      _toMap(
        shouldPreserveReadState
            ? NotificationItem(
                id: item.id,
                appPackage: item.appPackage,
                appName: item.appName,
                title: item.title,
                body: item.body,
                receivedAt: item.receivedAt,
                isUnread: false,
                mediaPath: item.mediaPath,
                mediaType: item.mediaType,
                mediaMimeType: item.mediaMimeType,
                mediaSizeBytes: item.mediaSizeBytes,
              )
            : item,
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (previousMediaPath != null &&
        previousMediaPath != item.mediaPath &&
        previousMediaPath.trim().isNotEmpty) {
      await _deleteMediaFiles(<Map<String, Object?>>[
        <String, Object?>{'media_path': previousMediaPath},
      ]);
    }
  }

  Future<void> importMany(List<NotificationItem> items) async {
    if (items.isEmpty) {
      return;
    }

    final database = await _db;
    final batch = database.batch();

    for (final item in items) {
      batch.insert(
        _tableName,
        _toMap(item),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> deleteItem(String id) async {
    final database = await _db;
    final rows = await database.query(
      _tableName,
      columns: const <String>['media_path'],
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    await database.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    await _deleteMediaFiles(rows);
  }

  Future<void> markAsRead(String id) async {
    final database = await _db;
    await database.update(
      _tableName,
      {'is_unread': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAll() async {
    final database = await _db;
    final rows = await database.query(
      _tableName,
      columns: const <String>['media_path'],
    );
    await database.delete(_tableName);
    await _deleteMediaFiles(rows);
  }

  Future<void> seedIfEmpty(List<NotificationItem> seedItems) async {
    if (seedItems.isEmpty) {
      return;
    }

    final existingCount = await _count();
    if (existingCount > 0) {
      return;
    }

    await importMany(seedItems);
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
      version: 5,
      onCreate: (database, _) async {
        await database.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            app_package TEXT NOT NULL DEFAULT '',
            app_name TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            received_at INTEGER NOT NULL,
            is_unread INTEGER NOT NULL,
            media_path TEXT,
            media_type TEXT,
            media_mime_type TEXT,
            media_size_bytes INTEGER
          )
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await database.execute('''
            CREATE TABLE ${_tableName}_local_only (
              id TEXT PRIMARY KEY,
              app_package TEXT NOT NULL DEFAULT '',
              app_name TEXT NOT NULL,
              title TEXT NOT NULL,
              body TEXT NOT NULL,
              received_at INTEGER NOT NULL,
              is_unread INTEGER NOT NULL,
              media_path TEXT,
              media_type TEXT,
              media_mime_type TEXT,
              media_size_bytes INTEGER
            )
          ''');
          await database.execute('''
            INSERT OR REPLACE INTO ${_tableName}_local_only
              (id, app_package, app_name, title, body, received_at, is_unread,
               media_path, media_type, media_mime_type, media_size_bytes)
            SELECT id, '', app_name, title, body, received_at, is_unread,
                   NULL, NULL, NULL, NULL
            FROM $_tableName
          ''');
          await database.execute('DROP TABLE $_tableName');
          await database.execute(
            'ALTER TABLE ${_tableName}_local_only RENAME TO $_tableName',
          );
          return;
        }
        if (oldVersion >= 3 && oldVersion < 4) {
          await database.execute(
            "ALTER TABLE $_tableName ADD COLUMN app_package TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 5) {
          await database.execute(
            "ALTER TABLE $_tableName ADD COLUMN media_path TEXT",
          );
          await database.execute(
            "ALTER TABLE $_tableName ADD COLUMN media_type TEXT",
          );
          await database.execute(
            "ALTER TABLE $_tableName ADD COLUMN media_mime_type TEXT",
          );
          await database.execute(
            "ALTER TABLE $_tableName ADD COLUMN media_size_bytes INTEGER",
          );
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
      appPackage: row['app_package'] as String? ?? '',
      appName: row['app_name']! as String,
      title: row['title']! as String,
      body: row['body']! as String,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(
        row['received_at']! as int,
      ),
      isUnread: (row['is_unread']! as int) == 1,
      mediaPath: row['media_path'] as String?,
      mediaType: row['media_type'] as String?,
      mediaMimeType: row['media_mime_type'] as String?,
      mediaSizeBytes: row['media_size_bytes'] as int?,
    );
  }

  Map<String, Object?> _toMap(NotificationItem item) {
    return <String, Object?>{
      'id': item.id,
      'app_package': item.appPackage,
      'app_name': item.appName,
      'title': item.title,
      'body': item.body,
      'received_at': item.receivedAt.millisecondsSinceEpoch,
      'is_unread': item.isUnread ? 1 : 0,
      'media_path': item.mediaPath,
      'media_type': item.mediaType,
      'media_mime_type': item.mediaMimeType,
      'media_size_bytes': item.mediaSizeBytes,
    };
  }

  Future<void> _deleteMediaFiles(List<Map<String, Object?>> rows) async {
    final paths = rows
        .map((row) => row['media_path']?.toString().trim() ?? '')
        .where((path) => path.isNotEmpty)
        .toSet();

    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Best effort cleanup. The database operation should not fail because
        // a media file was already removed by Android or the user.
      }
    }
  }
}
