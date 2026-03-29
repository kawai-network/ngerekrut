import '../../flutter_chat_core/src/models/user.dart';
import '../../flutter_chat_core/src/utils/typedefs.dart';
import '../database/chat_database_service.dart';

/// Mapper class for converting between [User] objects and database rows.
class UserMapper {
  /// Converts a [User] object to a database row map.
  Map<String, dynamic> toRow(User user) {
    return {
      'id': user.id,
      'name': user.name,
      'image_source': user.imageSource,
      'created_at': ChatDatabaseService.dateTimeToEpoch(user.createdAt),
      'metadata': ChatDatabaseService.encodeJson(user.metadata),
    };
  }

  /// Converts a database row map to a [User] object.
  User fromRow(Map<String, dynamic> row) {
    return User(
      id: row['id'] as UserID,
      name: row['name'] as String?,
      imageSource: row['image_source'] as String?,
      createdAt: ChatDatabaseService.epochToDateTime(row['created_at'] as int?),
      metadata: ChatDatabaseService.decodeJson(row['metadata'] as String?),
    );
  }

  /// Converts a list of [User] objects to a list of database row maps.
  List<Map<String, dynamic>> toRows(List<User> users) {
    return users.map(toRow).toList();
  }

  /// Converts a list of database row maps to a list of [User] objects.
  List<User> fromRows(List<Map<String, dynamic>> rows) {
    return rows.map(fromRow).toList();
  }
}
