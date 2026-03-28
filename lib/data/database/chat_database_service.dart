import 'dart:convert';

import 'package:dart_duckdb/dart_duckdb.dart';

/// Service class for managing DuckDB database connection and operations.
class ChatDatabaseService {
  late Database _db;
  late Connection _connection;
  final String _dbPath;
  bool _isOpen = false;

  /// Creates a [ChatDatabaseService] instance.
  /// 
  /// [dbPath] is the path to the database file. If not provided,
  /// an in-memory database will be used.
  ChatDatabaseService({String? dbPath}) : _dbPath = dbPath ?? ':memory:';

  /// Initializes the database connection and runs migrations.
  Future<void> initialize() async {
    if (_isOpen) return;

    try {
      // Open the database using the duckdb singleton
      _db = await duckdb.open(_dbPath);
      
      // Create a connection
      _connection = await duckdb.connect(_db);
      _isOpen = true;

      // Enable JSON extension
      await _connection.execute('INSTALL json;');
      await _connection.execute('LOAD json;');

      // Run migrations
      await _runMigrations();
    } catch (e) {
      _isOpen = false;
      rethrow;
    }
  }

  /// Runs database migrations.
  Future<void> _runMigrations() async {
    // Check current version
    try {
      final checkResult = await _connection.query(
        'SELECT version FROM schema_version',
      );
      if (checkResult.rowCount > 0) {
        final row = checkResult.fetchOne();
        if (row != null) {
          return; // Already migrated
        }
      }
    } catch (_) {
      // Table doesn't exist yet, proceed with migration
    }

    await _migrateV1();
  }

  /// Migration V1: Initial schema creation
  Future<void> _migrateV1() async {
    await _connection.execute('BEGIN TRANSACTION');

    try {
      // Create schema version table
      await _connection.execute('''
        CREATE TABLE schema_version (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          version INTEGER NOT NULL
        )
      ''');

      // Users table
      await _connection.execute('''
        CREATE TABLE users (
          id VARCHAR PRIMARY KEY,
          name VARCHAR,
          image_source VARCHAR,
          created_at BIGINT,
          metadata JSON
        )
      ''');

      // Messages table (base fields - hybrid approach)
      await _connection.execute('''
        CREATE TABLE messages (
          id VARCHAR PRIMARY KEY,
          type VARCHAR NOT NULL,
          author_id VARCHAR NOT NULL,
          reply_to_message_id VARCHAR,
          created_at BIGINT,
          deleted_at BIGINT,
          failed_at BIGINT,
          sent_at BIGINT,
          delivered_at BIGINT,
          seen_at BIGINT,
          updated_at BIGINT,
          pinned BOOLEAN DEFAULT FALSE,
          status VARCHAR,
          text_content TEXT,
          media_source VARCHAR,
          media_metadata JSON,
          custom_metadata JSON,
          FOREIGN KEY (author_id) REFERENCES users(id)
        )
      ''');

      // Reactions table (normalized for querying)
      await _connection.execute('''
        CREATE TABLE reactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          message_id VARCHAR NOT NULL,
          reaction_key VARCHAR NOT NULL,
          user_id VARCHAR NOT NULL,
          FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      ''');

      // Create indexes for performance
      await _connection.execute('CREATE INDEX idx_messages_author ON messages(author_id)');
      await _connection.execute('CREATE INDEX idx_messages_created ON messages(created_at DESC)');
      await _connection.execute('CREATE INDEX idx_messages_status ON messages(status)');
      await _connection.execute('CREATE INDEX idx_messages_type ON messages(type)');
      await _connection.execute('CREATE INDEX idx_reactions_message ON reactions(message_id)');
      await _connection.execute('CREATE INDEX idx_reactions_user ON reactions(user_id)');
      await _connection.execute('CREATE INDEX idx_users_name ON users(name)');

      // Set schema version
      await _connection.execute('INSERT INTO schema_version (id, version) VALUES (1, 1)');

      await _connection.execute('COMMIT');
    } catch (e) {
      await _connection.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Executes a SQL query and returns the result.
  Future<ResultSet> execute(String sql, [List<dynamic>? params]) async {
    if (!_isOpen) {
      throw StateError('Database is not open. Call initialize() first.');
    }
    
    if (params == null || params.isEmpty) {
      return await _connection.query(sql);
    }
    
    // Use prepared statement for parameterized queries
    final stmt = await _connection.prepare(sql);
    try {
      stmt.bindParams(params);
      return await stmt.execute();
    } finally {
      await stmt.dispose();
    }
  }

  /// Executes a SQL query that doesn't return results.
  Future<void> executeVoid(String sql, [List<dynamic>? params]) async {
    if (params == null || params.isEmpty) {
      await _connection.execute(sql);
    } else {
      final stmt = await _connection.prepare(sql);
      try {
        stmt.bindParams(params);
        await stmt.execute();
      } finally {
        await stmt.dispose();
      }
    }
  }

  /// Runs a transaction with the given callback.
  /// 
  /// If the callback throws an exception, the transaction will be rolled back.
  /// Otherwise, the transaction will be committed.
  Future<T> runTransaction<T>(Future<T> Function() callback) async {
    await executeVoid('BEGIN TRANSACTION');
    try {
      final result = await callback();
      await executeVoid('COMMIT');
      return result;
    } catch (e) {
      await executeVoid('ROLLBACK');
      rethrow;
    }
  }

  /// Closes the database connection.
  Future<void> close() async {
    if (!_isOpen) return;
    
    await _connection.dispose();
    await _db.dispose();
    _isOpen = false;
  }

  /// Returns true if the database is open.
  bool get isOpen => _isOpen;

  /// Returns the underlying Database instance.
  /// 
  /// Use with caution - direct access bypasses safety checks.
  Database get db => _db;

  /// Returns the current Connection instance.
  Connection get connection => _connection;

  /// Helper method to convert DateTime to epoch milliseconds.
  static int? dateTimeToEpoch(DateTime? dateTime) {
    return dateTime?.millisecondsSinceEpoch;
  }

  /// Helper method to convert epoch milliseconds to DateTime.
  static DateTime? epochToDateTime(int? epoch) {
    return epoch != null ? DateTime.fromMillisecondsSinceEpoch(epoch) : null;
  }

  /// Helper method to encode a value to JSON string.
  static String? encodeJson(dynamic value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  /// Helper method to decode a JSON string to a map.
  static Map<String, dynamic>? decodeJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  /// Converts a ResultSet row to a Map with column names as keys.
  static Map<String, dynamic> rowToMap(List<Object?> row, List<String> columnNames) {
    final map = <String, dynamic>{};
    for (var i = 0; i < row.length; i++) {
      map[columnNames[i]] = row[i];
    }
    return map;
  }

  /// Converts all rows of a ResultSet to a list of Maps with column names as keys.
  static List<Map<String, dynamic>> rowsToMaps(List<List<Object?>> rows, List<String> columnNames) {
    return rows.map((row) => rowToMap(row, columnNames)).toList();
  }
}
