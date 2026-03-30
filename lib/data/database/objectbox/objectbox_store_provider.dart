import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';

import 'entities.dart';
import '../../../objectbox.g.dart';

/// Provider for ObjectBox store initialization.
class ObjectBoxStoreProvider {
  static Store? _store;
  static Future<void>? _initFuture;

  ObjectBoxStoreProvider._();

  static Future<void> initialize() async {
    if (_store != null) return;

    // Prevent race condition: only one initialization at a time
    _initFuture ??= (() async {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        _store = await openStore(directory: docsDir.path);
      } catch (_) {
        _initFuture = null;
        rethrow;
      } finally {
        if (_store == null) {
          _initFuture = null;
        }
      }
    })();

    await _initFuture;
  }

  static Store get store {
    if (_store == null) {
      throw StateError('ObjectBox not initialized. Call initialize() first.');
    }
    return _store!;
  }

  static Box<T> box<T>() => store.box<T>();

  static bool get isInitialized => _store != null;

  static void close() {
    if (_store != null) {
      _store!.close();
      _store = null;
      _initFuture = null;
    }
  }

  static Box<UserEntity> get userBox => box<UserEntity>();
  static Box<MessageEntity> get messageBox => box<MessageEntity>();
  static Box<ReactionEntity> get reactionBox => box<ReactionEntity>();
}
