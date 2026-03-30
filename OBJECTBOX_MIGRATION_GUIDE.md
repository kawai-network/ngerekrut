# ObjectBox Migration Guide

This guide explains how to migrate from DuckDB to ObjectBox in your Flutter chat application.

## Why ObjectBox?

ObjectBox 4.0+ provides:
- ✅ **Single database** for both regular data and vector search (HNSW)
- ✅ **Production-ready** stability (not experimental)
- ✅ **Type-safe** object-oriented API (no SQL queries)
- ✅ **ACID transactions**
- ✅ **Cross-platform** support (iOS, Android, Desktop)
- ✅ **Vector search** with HNSW index for semantic search/RAG
- ✅ **High performance** (native code, not SQLite wrapper)

## Migration Steps

### 1. Update Dependencies

**Remove DuckDB:**
```yaml
# Remove this
dart_duckdb:
  git:
    url: https://github.com/yharby/duckdb-dart.git
    ref: main
```

**Add ObjectBox:**
```yaml
dependencies:
  objectbox: ^4.0.3
  objectbox_flutter_libs: ^4.0.3

dev_dependencies:
  build_runner: ^2.10.4
```

### 2. Initialize ObjectBox

Replace DuckDB initialization with ObjectBox:

**Before (DuckDB):**
```dart
import 'package:ngerekrut/data/data.dart';

final dbPath = await DatabasePathProvider.getDatabasePath();
final database = ChatDatabaseService(dbPath: dbPath);
await database.initialize();
```

**After (ObjectBox):**
```dart
import 'package:ngerekrut/data/objectbox/objectbox.dart';

await ObjectBoxStoreProvider.initialize();
```

### 3. Update Repositories

**Before (DuckDB):**
```dart
final controller = DuckDBChatController(
  messageRepository: MessageRepository(database),
  userRepository: UserRepository(database),
);
```

**After (ObjectBox):**
```dart
final controller = ObjectBoxChatController(
  messageRepository: ObjectBoxMessageRepository(),
  userRepository: ObjectBoxUserRepository(),
);
```

### 4. Update Chat Screens

**Before (DuckDB):**
```dart
import 'package:ngerekrut/data/controllers/duckdb_chat_controller.dart';

late DuckDBChatController _chatController;

@override
void initState() {
  super.initState();
  _initController();
}

Future<void> _initController() async {
  final dbPath = await DatabasePathProvider.getDatabasePath();
  final database = ChatDatabaseService(dbPath: dbPath);
  await database.initialize();
  
  _chatController = DuckDBChatController(
    messageRepository: MessageRepository(database),
    userRepository: UserRepository(database),
  );
  
  await _chatController.loadMessages();
}
```

**After (ObjectBox):**
```dart
import 'package:ngerekrut/data/objectbox/objectbox.dart';

late ObjectBoxChatController _chatController;

@override
void initState() {
  super.initState();
  _initController();
}

Future<void> _initController() async {
  // Initialize ObjectBox (only once per app lifecycle)
  await ObjectBoxStoreProvider.initialize();
  
  _chatController = ObjectBoxChatController(
    messageRepository: ObjectBoxMessageRepository(),
    userRepository: ObjectBoxUserRepository(),
  );
  
  await _chatController.loadMessages();
}
```

### 5. Run Code Generation

ObjectBox requires code generation for entities:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

This will generate `objectbox.g.dart` file needed for compilation.

## Vector Search (Semantic Search)

ObjectBox includes built-in vector search using HNSW index. Here's how to use it:

### 1. Compute Embeddings

You need to compute embeddings for your messages. You can use:
- Cloud APIs (OpenAI, Cohere, etc.)
- On-device models (TensorFlow Lite, ONNX Runtime)
- `mobile_rag_engine` package for on-device embeddings

```dart
// Example: Compute embedding for a message
Future<List<double>> computeEmbedding(String text) async {
  // Replace with your embedding model
  // Example using a hypothetical embedding service
  final response = await embeddingService.embed(text);
  return response.vector; // List<double> with 768 dimensions
}
```

### 2. Store Embeddings

```dart
// Store embedding for a message
final embedding = await computeEmbedding(messageText);
await _chatController.updateMessageEmbedding(messageId, embedding);
```

### 3. Semantic Search

```dart
// Search by meaning, not keywords
final queryVector = await computeEmbedding("What's the weather?");
final results = await _chatController.searchByVector(
  queryVector,
  limit: 10,
  minSimilarity: 0.7, // Filter by similarity threshold
);

// Results include similarity scores
for (final (message, score) in results) {
  // Access text content based on message type
  if (message is TextMessage) {
    print('Message: ${message.text}, Score: $score');
  }
}
```

### 4. Find Similar Messages

```dart
// Find messages similar to a given message
final similarMessages = await _chatController.getSimilarMessages(
  messageId,
  limit: 5,
);
```

### 5. Batch Embedding

```dart
// Get messages without embeddings (for batch processing)
final messagesToEmbed = await _chatController.getMessagesWithoutEmbedding(
  limit: 100,
);

// Compute and store embeddings
for (final message in messagesToEmbed) {
  final text = (message as TextMessage).text;
  final embedding = await computeEmbedding(text);
  await _chatController.updateMessageEmbedding(message.id, embedding);
}
```

## Schema Comparison

### DuckDB Schema
```sql
CREATE TABLE messages (
  id VARCHAR PRIMARY KEY,
  type VARCHAR NOT NULL,
  author_id VARCHAR NOT NULL,
  -- ... many fields
  media_metadata JSON,
  custom_metadata JSON
)
```

### ObjectBox Entity
```dart
@Entity()
class MessageEntity {
  int id; // Auto-increment
  
  @Unique()
  String messageId; // Business key
  
  String type;
  String authorId;
  
  // Vector embedding for semantic search
  @Property(type: PropertyType.floatVector)
  @HnswIndex(dimensions: 768)
  List<double>? embedding;
  
  // ... other fields
}
```

## API Mapping

| DuckDB | ObjectBox |
|--------|-----------|
| `ChatDatabaseService.initialize()` | `ObjectBoxStoreProvider.initialize()` |
| `MessageRepository(database)` | `ObjectBoxMessageRepository()` |
| `UserRepository(database)` | `ObjectBoxUserRepository()` |
| `DuckDBChatController(...)` | `ObjectBoxChatController(...)` |
| N/A | `searchByVector()` - Semantic search |
| N/A | `getSimilarMessages()` - Find similar |
| N/A | `updateMessageEmbedding()` - Store embedding |

## Data Migration

If you have existing DuckDB data to migrate:

```dart
Future<void> migrateFromDuckDB() async {
  // 1. Initialize both databases
  final duckDb = ChatDatabaseService(dbPath: dbPath);
  await duckDb.initialize();
  
  await ObjectBoxStoreProvider.initialize();
  
  final objectBoxUserRepo = ObjectBoxUserRepository();
  final objectBoxMessageRepo = ObjectBoxMessageRepository();
  
  // 2. Migrate users
  final duckUsers = await UserRepository(duckDb).getAllUsers(limit: 10000);
  await objectBoxUserRepo.upsertUsers(duckUsers);
  
  // 3. Migrate messages
  final duckMessages = await MessageRepository(duckDb).getAllMessages(limit: 10000);
  await objectBoxMessageRepo.insertMessages(duckMessages);
  
  print('Migration complete: ${duckUsers.length} users, ${duckMessages.length} messages');
}
```

## Performance Tips

1. **Batch Operations**: Use `insertMessages()` instead of multiple `insertMessage()` calls
2. **Async Mode**: ObjectBox uses async write by default for better performance
3. **Vector Index**: HNSW index is automatic - just set the embedding property
4. **Lazy Loading**: Load only needed messages with `limit` parameter
5. **Indexing**: ObjectBox automatically indexes `@Unique()` and `@Index()` fields

## Troubleshooting

### Build Runner Errors

If you see errors running `build_runner`:

```bash
# Clean and rebuild
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Missing objectbox.g.dart

Make sure you've run the build runner. The file is generated at:
```text
lib/objectbox.g.dart
```

The import in `objectbox_store_provider.dart` should be:
```dart
import '../../objectbox.g.dart';
```

### Vector Dimension Mismatch

All embeddings must have the same dimension (default: 768). To change:

```dart
@Property(type: PropertyType.floatVector)
@HnswIndex(dimensions: 1536) // Change to match your embedding model
List<double>? embedding;
```

Then re-run build_runner.

## Next Steps

1. ✅ Run `flutter pub get`
2. ✅ Run `dart run build_runner build --delete-conflicting-outputs`
3. ✅ Update your initialization code
4. ✅ Test basic CRUD operations
5. ✅ (Optional) Implement vector search with embeddings

## Additional Resources

- [ObjectBox Documentation](https://objectbox.io/flutter-dart/)
- [ObjectBox Vector Search](https://objectbox.io/on-device-vector-database-for-dart-flutter/)
- [mobile_rag_engine](https://pub.dev/packages/mobile_rag_engine) - On-device embeddings
