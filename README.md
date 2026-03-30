# ngerekrut

Flutter chat app with ObjectBox persistence and optional vector search.

## Quickstart

1. Install dependencies
```bash
flutter pub get
```

2. Generate ObjectBox code
```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `lib/objectbox.g.dart`.

3. Run the app
```bash
flutter run
```

## ObjectBox Setup

Initialize ObjectBox once at app startup:

```dart
import 'package:ngerekrut/data/objectbox/objectbox.dart';

await ObjectBoxStoreProvider.initialize();

final controller = ObjectBoxChatController(
  messageRepository: ObjectBoxMessageRepository(),
  userRepository: ObjectBoxUserRepository(),
);

await controller.loadMessages(limit: 50);
```

## Features

- Persistent chat storage via ObjectBox
- In-memory cache for UI speed
- Reactions and pagination
- Optional vector search with HNSW index (see `lib/data/database/objectbox/message_entity.dart`)

## Useful Files

- `lib/data/objectbox/objectbox.dart` – entrypoint for ObjectBox exports
- `lib/data/controllers/objectbox_chat_controller.dart` – persistence-backed controller
- `lib/data/repositories/objectbox_message_repository.dart` – message queries, vector search helpers
- `lib/data/example_objectbox_usage.dart` – end-to-end usage examples
