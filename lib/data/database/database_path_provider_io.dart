import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DatabasePathProvider {
  static const String databaseName = 'chat.db';

  static Future<String?> getDatabasePath() async {
    final platform = _getPlatform();

    switch (platform) {
      case DatabasePlatform.android:
      case DatabasePlatform.ios:
        final dir = await getApplicationDocumentsDirectory();
        return path.join(dir.path, databaseName);

      case DatabasePlatform.windows:
      case DatabasePlatform.macOS:
      case DatabasePlatform.linux:
        final dir = await getApplicationSupportDirectory();
        return path.join(dir.path, databaseName);

      case DatabasePlatform.web:
        return null;

      case DatabasePlatform.unknown:
        try {
          final dir = await getApplicationDocumentsDirectory();
          return path.join(dir.path, databaseName);
        } catch (_) {
          return null;
        }
    }
  }

  static Future<String?> getDatabaseDirectory() async {
    final fullPath = await getDatabasePath();
    if (fullPath == null) return null;
    return path.dirname(fullPath);
  }

  static Future<bool> databaseExists() async {
    final dbPath = await getDatabasePath();
    if (dbPath == null) return false;
    return File(dbPath).exists();
  }

  static Future<void> deleteDatabase() async {
    final dbPath = await getDatabasePath();
    if (dbPath != null) {
      final file = File(dbPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  static DatabasePlatform _getPlatform() {
    if (Platform.isAndroid) return DatabasePlatform.android;
    if (Platform.isIOS) return DatabasePlatform.ios;
    if (Platform.isWindows) return DatabasePlatform.windows;
    if (Platform.isLinux) return DatabasePlatform.linux;
    if (Platform.isMacOS) return DatabasePlatform.macOS;
    return DatabasePlatform.unknown;
  }
}

enum DatabasePlatform { android, ios, windows, macOS, linux, web, unknown }
