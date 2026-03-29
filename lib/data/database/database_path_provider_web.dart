import 'package:path/path.dart' as path;

class DatabasePathProvider {
  static const String databaseName = 'chat.db';

  static Future<String?> getDatabasePath() async {
    return null;
  }

  static Future<String?> getDatabaseDirectory() async {
    final fullPath = await getDatabasePath();
    if (fullPath == null) return null;
    return path.dirname(fullPath);
  }

  static Future<bool> databaseExists() async {
    return false;
  }

  static Future<void> deleteDatabase() async {}
}

enum DatabasePlatform { web }
