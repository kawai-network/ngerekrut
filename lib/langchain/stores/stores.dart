/// Key-value store abstractions for LangChain.
library;

export 'encoder_backed.dart';
export 'file_system_stub.dart' if (dart.library.io) 'file_system_io.dart';
export 'in_memory.dart';

/// {@template base_store}
/// Base interface for a key-value store.
/// {@endtemplate}
abstract interface class BaseStore<K, V> {
  /// {@macro base_store}
  const BaseStore();

  /// Gets a list of values for the given keys.
  Future<List<V?>> get(List<K> keys);

  /// Sets the key-value pairs.
  Future<void> set(List<(K, V)> keyValuePairs);

  /// Deletes the values for the given keys.
  Future<void> delete(List<K> keys);

  /// Yields keys from the store.
  ///
  /// This is useful for iterating over all keys in the store.
  Stream<K> yieldKeys({String? prefix});
}
