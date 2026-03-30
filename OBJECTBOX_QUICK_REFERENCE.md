# ObjectBox Quick Reference

## Setup

```bash
# Install dependencies
flutter pub get

# Generate ObjectBox code
dart run build_runner build --delete-conflicting-outputs
```

## Initialization

```dart
import 'package:ngerekrut/data/objectbox/objectbox.dart';

// In main.dart or app initialization
await ObjectBoxStoreProvider.initialize();

// Create controller
final controller = ObjectBoxChatController(
  messageRepository: ObjectBoxMessageRepository(),
  userRepository: ObjectBoxUserRepository(),
);

// Load messages
await controller.loadMessages(limit: 50);
```

## Basic Operations

### Send Message
```dart
final message = Message.text(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  authorId: userId,
  text: 'Hello!',
  createdAt: DateTime.now(),
);
await controller.insertMessage(message);
```

### Update Message
```dart
await controller.updateMessage(oldMessage, newMessage);
```

### Delete Message
```dart
await controller.removeMessage(message);
```

### Load Messages
```dart
// Initial load
await controller.loadMessages(limit: 50);

// Load older (pagination)
await controller.loadOlderMessages(
  before: oldestMessage.createdAt!,
  limit: 20,
);
```

### Users
```dart
// Save user
await controller.saveUser(user);

// Get user
final user = await controller.getUser(userId);

// Load all users
final users = await controller.loadUsers(limit: 100);
```

### Reactions
```dart
// Add reaction
await controller.addReaction(messageId, userId, '👍');

// Remove reaction
await controller.removeReaction(messageId, userId, '👍');
```

## Vector Search (Semantic Search)

### Store Embedding
```dart
// Compute embedding (using your embedding model)
final embedding = await computeEmbedding(messageText);

// Store in database
await controller.updateMessageEmbedding(messageId, embedding);
```

### Search by Vector
```dart
// Compute query vector
final queryVector = await computeEmbedding("What's the weather?");

// Search
final results = await controller.searchByVector(
  queryVector,
  limit: 10,
  minSimilarity: 0.7, // Optional: filter by similarity
);

// Results include similarity scores
for (final (message, score) in results) {
  print('Message: ${(message as TextMessage).text}');
  print('Similarity: $score');
}
```

### Find Similar Messages
```dart
final similar = await controller.getSimilarMessages(
  messageId,
  limit: 5,
);
```

### Batch Embedding
```dart
// Get messages without embeddings
final messages = await controller.getMessagesWithoutEmbedding(limit: 100);

// Compute and store
for (final message in messages) {
  final text = (message as TextMessage).text;
  final embedding = await computeEmbedding(text);
  await controller.updateMessageEmbedding(message.id, embedding);
}
```

## Search & Query

### Text Search
```dart
final results = await controller.searchMessages('keyword', limit: 20);
```

### Pinned Messages
```dart
final pinned = await controller.getPinnedMessages(limit: 10);
```

### Statistics
```dart
final stats = await controller.getMessageStats();
// Returns: {'TextMessage': 100, 'ImageMessage': 25, ...}
```

## Advanced

### Get Messages by Author
```dart
final messages = await controller.loadMessages(
  authorId: userId,
  limit: 50,
);
```

### Get Messages by Status
```dart
final pendingMessages = await messageRepository.getMessagesByStatus(
  MessageStatus.sending,
  limit: 50,
);
```

### Get Messages in Date Range
```dart
final messages = await messageRepository.getMessagesInRange(
  after: DateTime.now().subtract(Duration(days: 7)),
  before: DateTime.now(),
  limit: 100,
);
```

### Batch Insert
```dart
final messages = [message1, message2, message3];
await controller.insertAllMessages(messages);
```

## Repository Direct Access

```dart
final messageRepo = ObjectBoxMessageRepository();
final userRepo = ObjectBoxUserRepository();

// Direct repository operations
await messageRepo.insertMessage(message);
await userRepo.upsertUser(user);
await messageRepo.addReaction(messageId, userId, '❤️');
```

## Cleanup

```dart
// Dispose controller when done
controller.dispose();

// Close database (on app exit) - synchronous
ObjectBoxStoreProvider.close();
```

## Common Patterns

### Chat Screen Initialization
```dart
class _ChatScreenState extends State<ChatScreen> {
  late ObjectBoxChatController _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ObjectBoxStoreProvider.initialize();
    
    _controller = ObjectBoxChatController(
      messageRepository: ObjectBoxMessageRepository(),
      userRepository: ObjectBoxUserRepository(),
    );
    
    await _controller.loadMessages(limit: 50);
    
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Listen to Operations
```dart
_controller.operationsStream.listen((operation) {
  // React to changes
  switch (operation.type) {
    case ChatOperationType.insert:
      print('Message inserted at ${operation.index}');
      break;
    case ChatOperationType.update:
      print('Message updated');
      break;
    case ChatOperationType.remove:
      print('Message removed');
      break;
  }
});
```

### Get Messages for UI
```dart
// Get all messages (chronological order)
final messages = controller.messages;

// Get messages in reverse (newest first)
final reversed = controller.messages.reversed.toList();
```

## Tips

1. **Always initialize ObjectBox before creating controller**
2. **Use `loadMessages()` to populate cache on screen init**
3. **Use `insertAllMessages()` for batch inserts (better performance)**
4. **Call `dispose()` when done with controller**
5. **Vector search requires embeddings to be computed separately**
6. **Use `minSimilarity` to filter low-quality matches**
7. **Batch embedding computation for better performance**

## Troubleshooting

### Missing objectbox.g.dart
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Build errors
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Check if initialized
```dart
if (ObjectBoxStoreProvider.isInitialized) {
  // Safe to use ObjectBox
}
```
