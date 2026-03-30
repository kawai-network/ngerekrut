/// ObjectBox data layer exports.
///
/// This library provides ObjectBox-based repositories and controllers
/// for persistent chat storage with vector search capabilities.
library;

// Store provider
export '../database/objectbox/objectbox_store_provider.dart';

// Entities
export '../database/objectbox/entities.dart';

// Repositories
export '../repositories/objectbox_user_repository.dart';
export '../repositories/objectbox_message_repository.dart';

// Controllers
export '../controllers/objectbox_chat_controller.dart';
