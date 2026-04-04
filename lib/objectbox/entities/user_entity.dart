import 'package:objectbox/objectbox.dart';

/// ObjectBox entity for User.
@Entity()
class UserEntity {
  int id;

  @Unique(onConflict: ConflictStrategy.replace)
  String userId;

  String? name;
  String? imageSource;
  int createdAt;
  String? metadataJson;

  UserEntity({
    this.id = 0,
    required this.userId,
    this.name,
    this.imageSource,
    this.createdAt = 0,
    this.metadataJson,
  });
}
