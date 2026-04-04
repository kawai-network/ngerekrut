import 'dart:convert';

import 'package:objectbox/objectbox.dart';

import '../../../flutter_chat_core/src/models/user.dart';
import '../../../flutter_chat_core/src/utils/typedefs.dart';
import '../entities/objectbox_store_provider.dart';
import '../entities/user_entity.dart';
import '../../objectbox.g.dart';

/// Repository for managing [User] persistence operations using ObjectBox.
///
/// Provides CRUD operations and query methods for users stored in ObjectBox.
class ObjectBoxUserRepository {
  /// Creates a [ObjectBoxUserRepository] instance.
  ObjectBoxUserRepository();

  /// Gets the UserEntity box.
  Box<UserEntity> get _box => ObjectBoxStoreProvider.userBox;

  /// Inserts a new user into the database.
  Future<void> insertUser(User user) async {
    final entity = _toEntity(user);
    _box.put(entity);
  }

  /// Updates an existing user in the database.
  Future<void> updateUser(User user) async {
    final existingEntity = _getByUserId(user.id.toString());
    if (existingEntity == null) {
      throw StateError('User with id ${user.id} not found');
    }

    final entity = _toEntity(user);
    entity.id = existingEntity.id;
    _box.put(entity);
  }

  /// Upserts a user (insert or update).
  Future<void> upsertUser(User user) async {
    final entity = _toEntity(user);
    final existing = _getByUserId(user.id.toString());
    if (existing != null) {
      entity.id = existing.id;
    }
    _box.put(entity);
  }

  /// Deletes a user by ID.
  Future<void> deleteUser(UserID id) async {
    final existing = _getByUserId(id.toString());
    if (existing != null) {
      _box.remove(existing.id);
    }
  }

  /// Gets a user by ID.
  Future<User?> getUserById(UserID id) async {
    final entity = _getByUserId(id.toString());
    if (entity == null) return null;
    return _toModel(entity);
  }

  /// Gets all users.
  Future<List<User>> getAllUsers({int limit = 100}) async {
    final all = _box.getAll();
    all.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    return all.take(limit).map(_toModel).toList();
  }

  /// Gets users by IDs.
  Future<List<User>> getUsersByIds(List<UserID> ids) async {
    if (ids.isEmpty) return [];
    final results = <User>[];
    for (final id in ids) {
      final user = await getUserById(id);
      if (user != null) results.add(user);
    }
    return results;
  }

  /// Searches users by name.
  Future<List<User>> searchUsers(String query, {int limit = 50}) async {
    final all = _box.getAll();
    final queryLower = query.toLowerCase();
    final filtered = all
        .where((u) => (u.name ?? '').toLowerCase().contains(queryLower))
        .take(limit)
        .toList();
    return filtered.map(_toModel).toList();
  }

  /// Gets user count.
  Future<int> getUserCount() async {
    return _box.count();
  }

  /// Upserts multiple users.
  Future<void> upsertUsers(List<User> users) async {
    for (final user in users) {
      await upsertUser(user);
    }
  }

  /// Deletes multiple users.
  Future<void> deleteUsers(List<UserID> ids) async {
    for (final id in ids) {
      await deleteUser(id);
    }
  }

  /// Gets user by userId string using ObjectBox query.
  UserEntity? _getByUserId(UserID userId) {
    return _box.query(UserEntity_.userId.equals(userId)).build().findFirst();
  }

  /// Converts User model to UserEntity.
  UserEntity _toEntity(User user) {
    return UserEntity(
      userId: user.id.toString(),
      name: user.name,
      imageSource: user.imageSource,
      createdAt: user.createdAt?.millisecondsSinceEpoch ?? 0,
      metadataJson: user.metadata != null ? jsonEncode(user.metadata) : null,
    );
  }

  /// Converts UserEntity to User model.
  User _toModel(UserEntity entity) {
    final metadataJson = entity.metadataJson;
    return User(
      id: entity.userId,
      name: entity.name,
      imageSource: entity.imageSource,
      createdAt: entity.createdAt > 0
          ? DateTime.fromMillisecondsSinceEpoch(entity.createdAt)
          : null,
      metadata: metadataJson != null
          ? jsonDecode(metadataJson) as Map<String, dynamic>
          : null,
    );
  }
}
