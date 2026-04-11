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
flutter run --flavor recruiter -t lib/main_recruiter.dart
```

## ObjectBox Setup

Initialize ObjectBox once at app startup:

```dart
import 'package:ngerekrut/objectbox/objectbox.dart';

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
- Optional vector search with HNSW index (see `lib/objectbox/objectbox/message_entity.dart`)

## Useful Files

- `lib/objectbox/data.dart` – entrypoint for data layer exports
- `lib/objectbox/controllers/objectbox_chat_controller.dart` – persistence-backed controller
- `lib/objectbox/repositories/objectbox_message_repository.dart` – message queries, vector search helpers
- `lib/objectbox/example_objectbox_usage.dart` – end-to-end usage examples
