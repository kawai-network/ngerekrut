# ngerekrut

Flutter recruiter/jobseeker app with:
- `libsql_dart` for shared business data
- `ObjectBox` for local chat and recruiter artifacts

## Quickstart

1. Install dependencies
```bash
flutter pub get
```

2. Generate code
```bash
dart run build_runner build --delete-conflicting-outputs
```

This regenerates files such as `lib/objectbox.g.dart` and JSON/Freezed outputs.

3. Run the app
```bash
flutter run --flavor recruiter -t lib/main_recruiter.dart
```

## Storage Architecture

- `libsql_dart`
  - `job_postings`
  - `job_applications`
  - `saved_jobs`
  - `candidates`
- `ObjectBox`
  - chat sessions/messages
  - shortlist cache
  - scorecards
  - interview guides

## ObjectBox Setup

Initialize ObjectBox once at app startup for local-only data:

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

- Shared recruiter/jobseeker data via LibSQL/Turso
- Persistent local chat storage via ObjectBox
- Local recruiter artifacts via ObjectBox
- In-memory cache for UI speed
- Reactions and pagination
- Optional vector search with HNSW index (see `lib/objectbox/objectbox/message_entity.dart`)

## Useful Files

- `lib/objectbox/data.dart` – entrypoint for data layer exports
- `lib/objectbox/controllers/objectbox_chat_controller.dart` – persistence-backed controller
- `lib/objectbox/repositories/objectbox_message_repository.dart` – message queries, vector search helpers
- `lib/objectbox/example_objectbox_usage.dart` – end-to-end usage examples
