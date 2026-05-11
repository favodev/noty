import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:noty/features/feed/domain/notification_item.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class NotificationArchiveImportResult {
  const NotificationArchiveImportResult({required this.items});

  final List<NotificationItem> items;
  int get count => items.length;
}

class NotificationArchiveService {
  static const int _schemaVersion = 1;

  Future<String> exportAndShare(List<NotificationItem> notifications) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(directory.path, 'noty-export-$timestamp.json'));

    final payload = <String, Object?>{
      'app': 'noty',
      'schemaVersion': _schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'notifications': notifications.map((item) => item.toJson()).toList(),
    };

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: 'application/json')],
        subject: 'Exportaci?n de Noty',
        text: 'Historial local exportado desde Noty.',
      ),
    );

    return file.path;
  }

  Future<NotificationArchiveImportResult?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      withData: false,
    );

    final path = result?.files.single.path;
    if (path == null) {
      return null;
    }

    final raw = await File(path).readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('El archivo no tiene un formato v?lido.');
    }

    if (decoded['app'] != 'noty') {
      throw const FormatException('Este archivo no parece ser una exportaci?n de Noty.');
    }

    final notifications = decoded['notifications'];
    if (notifications is! List) {
      throw const FormatException('La exportaci?n no contiene notificaciones.');
    }

    final items = notifications
        .whereType<Map>()
        .map((json) => NotificationItem.fromJson(Map<String, Object?>.from(json)))
        .toList();

    return NotificationArchiveImportResult(items: items);
  }
}
