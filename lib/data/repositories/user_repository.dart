import '../../flutter_chat_core/src/models/user.dart';
import '../../flutter_chat_core/src/utils/typedefs.dart';
import '../database/chat_database_service.dart';
import '../mappers/user_mapper.dart';

/// Repository for managing [User] persistence operations.
/// 
/// Provides CRUD operations and query methods for users stored in DuckDB.
class UserRepository {
  final ChatDatabaseService _database;
  final UserMapper _mapper;

  /// Creates a [UserRepository] instance.
  UserRepository(this._database) : _mapper = UserMapper();

  /// Inserts a new user into the database.
  Future<void> insertUser(User user) async {
    final row = _mapper.toRow(user);
    
    await _database.executeVoid('''
      INSERT INTO users (id, name, image_source, created_at, metadata)
      VALUES (?, ?, ?, ?, ?)
    ''', [
      row['id'],
      row['name'],
      row['image_source'],
      row['created_at'],
      row['metadata'],
    ]);
  }

  /// Updates an existing user in the database.
  Future<void> updateUser(User user) async {
    final row = _mapper.toRow(user);
    
    await _database.executeVoid('''
      UPDATE users SET
        name = ?,
        image_source = ?,
        created_at = ?,
        metadata = ?
      WHERE id = ?
    ''', [
      row['name'],
      row['image_source'],
      row['created_at'],
      row['metadata'],
      row['id'],
    ]);
  }

  /// Upserts a user (insert or update).
  Future<void> upsertUser(User user) async {
    final existing = await getUserById(user.id);
    if (existing != null) {
      await updateUser(user);
    } else {
      await insertUser(user);
    }
  }

  /// Deletes a user by ID.
  Future<void> deleteUser(UserID id) async {
    await _database.executeVoid('DELETE FROM users WHERE id = ?', [id]);
  }

  /// Gets a user by ID.
  Future<User?> getUserById(UserID id) async {
    final result = await _database.execute(
      'SELECT * FROM users WHERE id = ?',
      [id],
    );

    if (result.isEmpty) return null;

    return _mapper.fromRow(result.first);
  }

  /// Gets all users.
  Future<List<User>> getAllUsers({
    int limit = 100,
  }) async {
    final result = await _database.execute('''
      SELECT * FROM users
      ORDER BY name
      LIMIT ?
    ''', [limit]);

    return _mapper.fromRows(result);
  }

  /// Gets users by IDs.
  Future<List<User>> getUsersByIds(List<UserID> ids) async {
    if (ids.isEmpty) return [];

    final result = await _database.execute('''
      SELECT * FROM users
      WHERE id IN (${List.filled(ids.length, '?').join(',')})
    ''', ids);

    return _mapper.fromRows(result);
  }

  /// Searches users by name.
  Future<List<User>> searchUsers(
    String query, {
    int limit = 50,
  }) async {
    final result = await _database.execute('''
      SELECT * FROM users
      WHERE name LIKE ?
      ORDER BY name
      LIMIT ?
    ''', ['%$query%', limit]);

    return _mapper.fromRows(result);
  }

  /// Gets user count.
  Future<int> getUserCount() async {
    final result = await _database.execute('SELECT COUNT(*) as count FROM users');
    return result.first['count'] as int;
  }

  /// Inserts or updates multiple users in a transaction.
  Future<void> upsertUsers(List<User> users) async {
    await _database.runTransaction(() async {
      for (final user in users) {
        await upsertUser(user);
      }
    });
  }

  /// Deletes multiple users in a transaction.
  Future<void> deleteUsers(List<UserID> ids) async {
    await _database.runTransaction(() async {
      for (final id in ids) {
        await deleteUser(id);
      }
    });
  }
}
