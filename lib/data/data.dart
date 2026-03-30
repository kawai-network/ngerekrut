/// Data layer for chat database functionality using ObjectBox.
///
/// ObjectBox provides:
/// - Fast object-oriented database storage
/// - Vector search capabilities via HNSW index
/// - ACID transactions
/// - Cross-platform support
library;

// ObjectBox store provider
export 'database/objectbox/objectbox_store_provider.dart';

// ObjectBox entities
export 'database/objectbox/entities.dart';

// ObjectBox repositories
export 'repositories/objectbox_message_repository.dart';
export 'repositories/objectbox_user_repository.dart';

// ObjectBox controller
export 'controllers/objectbox_chat_controller.dart';
