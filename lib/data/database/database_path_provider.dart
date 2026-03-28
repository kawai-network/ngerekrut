import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Provides database path configuration for Flutter applications.
class DatabasePathProvider {
  /// The name of the database file.
  static const String databaseName = 'chat.db';

  /// Gets the full path to the database file.
  /// 
  /// On mobile platforms (iOS/Android), this uses the application documents directory.
  /// On desktop platforms (Windows/macOS/Linux), this uses the application data directory.
  /// On web platforms, this returns null as DuckDB web is not supported in this implementation.
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
        // DuckDB web support would require a different implementation
        return null;
      
      case DatabasePlatform.unknown:
        // Fallback to documents directory
        try {
          final dir = await getApplicationDocumentsDirectory();
          return path.join(dir.path, databaseName);
        } catch (_) {
          return null;
        }
    }
  }

  /// Gets the database directory path (without the filename).
  static Future<String?> getDatabaseDirectory() async {
    final fullPath = await getDatabasePath();
    if (fullPath == null) return null;
    return path.dirname(fullPath);
  }

  /// Checks if the database file exists.
  static Future<bool> databaseExists() async {
    final dbPath = await getDatabasePath();
    if (dbPath == null) return false;
    return File(dbPath).exists();
  }

  /// Deletes the database file.
  /// 
  /// Use with caution - this will permanently delete all data.
  static Future<void> deleteDatabase() async {
    final dbPath = await getDatabasePath();
    if (dbPath != null) {
      final file = File(dbPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// Gets the current platform.
  static DatabasePlatform _getPlatform() {
    if (Platform.isAndroid) return DatabasePlatform.android;
    if (Platform.isIOS) return DatabasePlatform.ios;
    if (Platform.isWindows) return DatabasePlatform.windows;
    if (Platform.isLinux) return DatabasePlatform.linux;
    if (Platform.isMacOS) return DatabasePlatform.macOS;
    
    // Check for web (dart:io is not available on web, but if we reach here...)
    // This is a fallback for completeness
    return DatabasePlatform.unknown;
  }
}

/// Enum representing supported platforms.
enum DatabasePlatform {
  android,
  ios,
  windows,
  macOS,
  linux,
  web,
  unknown,
}
