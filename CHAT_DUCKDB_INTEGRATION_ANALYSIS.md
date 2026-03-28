# Integrasi Chat Core Models dengan dart_duckdb

## Analisis Model

### 1. Struktur Model Chat Core

#### **Message** (Sealed Class - Union Types)
- **TextMessage**: Pesan teks dengan link preview
- **TextStreamMessage**: Pesan teks streaming (placeholder)
- **ImageMessage**: Pesan gambar dengan metadata (thumbhash, blurhash, dimensions)
- **FileMessage**: Pesan file dengan MIME type
- **VideoMessage**: Pesan video
- **AudioMessage**: Pesan audio dengan waveform
- **SystemMessage**: Pesan sistem
- **CustomMessage**: Pesan custom dengan metadata dinamis
- **UnsupportedMessage**: Fallback untuk tipe tidak dikenal

**Field Umum Message:**
- `id` (MessageID = String)
- `authorId` (UserID = String)
- `replyToMessageId` (nullable)
- Timestamps: `createdAt`, `deletedAt`, `failedAt`, `sentAt`, `deliveredAt`, `seenAt`, `updatedAt`, `editedAt`
- `reactions` (Map<String, List<UserID>>)
- `pinned` (bool)
- `metadata` (Map<String, dynamic>)
- `status` (MessageStatus enum)

#### **User**
- `id` (UserID = String)
- `name` (nullable)
- `imageSource` (nullable)
- `createdAt` (DateTime)
- `metadata` (Map<String, dynamic>)

#### **LinkPreviewData** (Nested)
- `link` (String)
- `description` (nullable)
- `image` (ImagePreviewData - nested)
- `title` (nullable)

#### **ImagePreviewData**
- `url` (String)
- `width` (double)
- `height` (double)

---

## Strategi Integrasi dengan dart_duckdb

### Opsi 1: Normalized Schema (Recommended untuk Query Complex)

#### Schema Design

```sql
-- Users table
CREATE TABLE users (
    id VARCHAR PRIMARY KEY,
    name VARCHAR,
    image_source VARCHAR,
    created_at BIGINT, -- Epoch milliseconds
    metadata JSON
);

-- Messages table (base fields only)
CREATE TABLE messages (
    id VARCHAR PRIMARY KEY,
    type VARCHAR NOT NULL, -- 'text', 'image', 'file', etc.
    author_id VARCHAR NOT NULL,
    reply_to_message_id VARCHAR,
    created_at BIGINT,
    deleted_at BIGINT,
    failed_at BIGINT,
    sent_at BIGINT,
    delivered_at BIGINT,
    seen_at BIGINT,
    updated_at BIGINT,
    edited_at BIGINT,
    pinned BOOLEAN DEFAULT FALSE,
    status VARCHAR, -- 'delivered', 'error', 'seen', 'sending', 'sent'
    FOREIGN KEY (author_id) REFERENCES users(id)
);

-- Text messages specific fields
CREATE TABLE text_messages (
    message_id VARCHAR PRIMARY KEY,
    text TEXT,
    link_preview_data JSON,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
);

-- Text stream messages
CREATE TABLE text_stream_messages (
    message_id VARCHAR PRIMARY KEY,
    stream_id VARCHAR NOT NULL,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
);

-- Image messages
CREATE TABLE image_messages (
    message_id VARCHAR PRIMARY KEY,
    source VARCHAR NOT NULL,
    text TEXT,
    thumbhash VARCHAR,
    blurhash VARCHAR,
    width DOUBLE,
    height DOUBLE,
    size BIGINT,
    has_overlay BOOLEAN,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
);

-- File messages
CREATE TABLE file_messages (
    message_id VARCHAR PRIMARY KEY,
    source VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    size BIGINT,
    mime_type VARCHAR,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
);

-- Video messages
CREATE TABLE video_messages (
    message_id VARCHAR PRIMARY KEY,
    source VARCHAR NOT NULL,
    text TEXT,
    name VARCHAR,
    size BIGINT,
    width DOUBLE,
    height DOUBLE,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
);

-- Audio messages
CREATE TABLE audio_messages (
    message_id VARCHAR PRIMARY KEY,
    source VARCHAR NOT NULL,
    duration BIGINT NOT NULL, -- Duration in milliseconds
    text TEXT,
    size BIGINT,
    waveform JSON, -- Array of doubles
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
);

-- System messages
CREATE TABLE system_messages (
    message_id VARCHAR PRIMARY KEY,
    text TEXT NOT NULL,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE
);

-- Reactions (normalized for querying)
CREATE TABLE reactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id VARCHAR NOT NULL,
    reaction_key VARCHAR NOT NULL,
    user_id VARCHAR NOT NULL,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Indexes for performance
CREATE INDEX idx_messages_author ON messages(author_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
CREATE INDEX idx_messages_status ON messages(status);
CREATE INDEX idx_reactions_message ON reactions(message_id);
CREATE INDEX idx_users_name ON users(name);
```

#### Keuntungan:
- ✅ Query yang fleksibel (filter by type, status, author, date range)
- ✅ Storage efisien (no duplication)
- ✅ Referential integrity dengan foreign keys
- ✅ Mudah agregasi dan analytics
- ✅ Indexing optimal untuk performa

#### Kekurangan:
- ❌ Requires multiple JOINs untuk retrieve full message
- ❌ More complex schema management

---

### Opsi 2: Denormalized JSON Storage (Simpler)

#### Schema Design

```sql
-- Messages dengan JSON payload
CREATE TABLE messages (
    id VARCHAR PRIMARY KEY,
    type VARCHAR NOT NULL,
    author_id VARCHAR NOT NULL,
    author_name VARCHAR,
    created_at BIGINT,
    sent_at BIGINT,
    status VARCHAR,
    content JSON NOT NULL, -- Full message data as JSON
    metadata JSON
);

-- Users
CREATE TABLE users (
    id VARCHAR PRIMARY KEY,
    data JSON NOT NULL -- Full user object as JSON
);

-- Indexes
CREATE INDEX idx_messages_type ON messages(type);
CREATE INDEX idx_messages_author ON messages(author_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
```

#### Contoh JSON content untuk TextMessage:
```json
{
  "text": "Hello world",
  "linkPreviewData": {
    "link": "https://example.com",
    "title": "Example",
    "description": "Description",
    "image": {"url": "...", "width": 100, "height": 100}
  },
  "reactions": {"👍": ["user1", "user2"]},
  "pinned": false
}
```

#### Keuntungan:
- ✅ Simple schema
- ✅ Single query untuk retrieve
- ✅ Flexible untuk schema changes
- ✅ Easy serialization/deserialization

#### Kekurangan:
- ❌ Tidak bisa query field dalam JSON secara efisien
- ❌ Data duplication (author info di setiap message)
- ❌ Sulit untuk analytics/aggregation
- ❌ No type safety untuk nested fields

---

### Opsi 3: Hybrid Approach (Recommended)

Kombinasi normalized untuk fields yang sering di-query + JSON untuk payload spesifik:

```sql
CREATE TABLE messages (
    id VARCHAR PRIMARY KEY,
    type VARCHAR NOT NULL,
    author_id VARCHAR NOT NULL,
    reply_to_message_id VARCHAR,
    created_at BIGINT,
    sent_at BIGINT,
    seen_at BIGINT,
    status VARCHAR,
    pinned BOOLEAN DEFAULT FALSE,
    -- Type-specific payload as JSON
    text_content TEXT, -- For text messages
    media_source VARCHAR, -- For image/file/video/audio
    media_metadata JSON, -- Type-specific media metadata
    custom_metadata JSON
);
```

---

## Implementasi Repository Layer

### Structure Rekomendasi

```
lib/
├── data/
│   ├── database/
│   │   ├── chat_database.dart       # DuckDB connection & initialization
│   │   ├── migrations/
│   │   │   └── v1_initial.dart      # Schema migrations
│   │   └── tables/
│   │       ├── messages_table.dart  # Table definitions
│   │       └── users_table.dart
│   ├── repositories/
│   │   ├── message_repository.dart  # CRUD operations
│   │   └── user_repository.dart
│   └── mappers/
│       ├── message_mapper.dart      # Message ↔ DB row mapping
│       └── user_mapper.dart
└── domain/
    └── models/ (flutter_chat_core models)
```

### Contoh Implementation (Hybrid Approach)

#### Message Repository Interface

```dart
abstract class MessageRepository {
  Future<void> insertMessage(Message message);
  Future<void> updateMessage(Message message);
  Future<void> deleteMessage(MessageID id);
  Future<Message?> getMessageById(MessageID id);
  Future<List<Message>> getMessagesByAuthor(UserID authorId, {
    int limit = 50,
    DateTime? before,
  });
  Future<List<Message>> searchMessages(String query);
  Future<void> addReaction(MessageID messageId, UserID userId, String reaction);
  Future<void> removeReaction(MessageID messageId, UserID userId, String reaction);
}
```

#### Message Mapper

```dart
class MessageMapper {
  Message toMessage(Map<String, dynamic> row, Map<String, dynamic>? payload) {
    final type = row['type'] as String;
    
    switch (type) {
      case 'text':
        return Message.text(
          id: row['id'] as MessageID,
          authorId: row['author_id'] as UserID,
          replyToMessageId: row['reply_to_message_id'] as MessageID?,
          createdAt: _epochToDateTime(row['created_at'] as int?),
          sentAt: _epochToDateTime(row['sent_at'] as int?),
          status: _parseStatus(row['status'] as String?),
          text: payload?['text'] as String,
          linkPreviewData: payload?['linkPreviewData'] != null
              ? LinkPreviewData.fromJson(payload!['linkPreviewData'])
              : null,
        );
      case 'image':
        return Message.image(
          id: row['id'] as MessageID,
          authorId: row['author_id'] as UserID,
          source: payload?['source'] as String,
          width: (payload?['width'] as num?)?.toDouble(),
          height: (payload?['height'] as num?)?.toDouble(),
          // ... map other fields
        );
      // ... handle other types
    }
  }

  Map<String, dynamic> toRow(Message message) {
    return {
      'id': message.id,
      'type': _getTypeName(message),
      'author_id': message.authorId,
      'reply_to_message_id': message.replyToMessageId,
      'created_at': _dateTimeToEpoch(message.createdAt),
      'sent_at': _dateTimeToEpoch(message.sentAt),
      'status': message.status?.name,
      'pinned': message.pinned ?? false,
    };
  }

  Map<String, dynamic> toPayload(Message message) {
    return message.when(
      text: (text: _) => {'text': message.text, 'linkPreviewData': message.linkPreviewData?.toJson()},
      image: (source: _, width: _, height: _, ...) => {'source': source, 'width': width, ...},
      // ... other types
    );
  }
}
```

#### Database Service

```dart
class ChatDatabaseService {
  late final DuckDB _db;
  final String _dbPath;

  ChatDatabaseService(this._dbPath);

  Future<void> initialize() async {
    _db = await DuckDB.open(_dbPath);
    
    // Enable JSON extension if needed
    await _db.execute('INSTALL json;');
    await _db.execute('LOAD json;');
    
    // Run migrations
    await _runMigrations();
  }

  Future<void> insertMessage(Message message) async {
    final mapper = MessageMapper();
    final row = mapper.toRow(message);
    final payload = mapper.toPayload(message);

    await _db.execute('''
      INSERT INTO messages (id, type, author_id, created_at, status, content)
      VALUES (?, ?, ?, ?, ?, ?)
    ''', [
      row['id'],
      row['type'],
      row['author_id'],
      row['created_at'],
      row['status'],
      jsonEncode(payload),
    ]);
  }

  Future<List<Message>> getMessages({
    UserID? authorId,
    MessageStatus? status,
    int limit = 50,
    DateTime? before,
  }) async {
    final conditions = <String>[];
    final params = <dynamic>[];

    if (authorId != null) {
      conditions.add('author_id = ?');
      params.add(authorId);
    }

    if (status != null) {
      conditions.add('status = ?');
      params.add(status.name);
    }

    if (before != null) {
      conditions.add('created_at < ?');
      params.add(_dateTimeToEpoch(before));
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await _db.execute('''
      SELECT * FROM messages
      $whereClause
      ORDER BY created_at DESC
      LIMIT ?
    ''', [...params, limit]);

    return result.rows
        .map((row) => MessageMapper().fromRow(row))
        .toList();
  }

  Future<void> dispose() async {
    await _db.close();
  }
}
```

---

## Considerations untuk Flutter Mobile

### 1. Path Management

```dart
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<String> getDatabasePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return path.join(dir.path, 'chat.db');
}
```

### 2. Migration Strategy

```dart
class DatabaseMigration {
  static const int currentVersion = 1;

  Future<void> migrate(DuckDB db, int fromVersion, int toVersion) async {
    if (fromVersion < 1) {
      await db.execute('''
        CREATE TABLE users (...);
        CREATE TABLE messages (...);
        -- ... other tables
      ''');
    }

    if (toVersion > 1) {
      // Future migrations
    }
  }
}
```

### 3. Transaction Support

```dart
Future<void> sendMessage(Message message, List<Attachment> attachments) async {
  await _db.execute('BEGIN TRANSACTION');
  try {
    await insertMessage(message);
    for (final attachment in attachments) {
      await insertAttachment(attachment);
    }
    await _db.execute('COMMIT');
  } catch (e) {
    await _db.execute('ROLLBACK');
    rethrow;
  }
}
```

### 4. Reactive Streams (Optional)

```dart
class MessageRepository {
  final _messageController = StreamController<List<Message>>.broadcast();

  Stream<List<Message>> get messagesStream => _messageController.stream;

  Future<void> insertMessage(Message message) async {
    await _db.execute(/* INSERT */);
    _messageController.add(await getAllMessages());
  }
}
```

---

## Query Examples

### Get Recent Messages with Author Info

```sql
SELECT 
    m.*,
    u.name as author_name,
    u.image_source as author_avatar
FROM messages m
LEFT JOIN users u ON m.author_id = u.id
WHERE m.deleted_at IS NULL
ORDER BY m.created_at DESC
LIMIT 50;
```

### Get Messages with Reactions

```sql
SELECT 
    m.*,
    json_group_array(json_object(
        'key', r.reaction_key,
        'user_id', r.user_id
    )) as reactions
FROM messages m
LEFT JOIN reactions r ON m.id = r.message_id
WHERE m.id = ?
GROUP BY m.id;
```

### Search Messages by Text

```sql
SELECT * FROM messages
WHERE type = 'text'
  AND text_content LIKE '%search query%'
  AND deleted_at IS NULL
ORDER BY created_at DESC;
```

### Get Message Statistics

```sql
SELECT 
    type,
    COUNT(*) as count,
    COUNT(CASE WHEN status = 'sent' THEN 1 END) as sent_count
FROM messages
WHERE created_at > ?
GROUP BY type;
```

---

## Rekomendasi Final

**Gunakan Hybrid Approach** dengan pertimbangan:

1. **Performance**: Index pada fields yang sering di-query (author_id, created_at, status)
2. **Flexibility**: JSON untuk payload spesifik message type
3. **Maintainability**: Schema yang tidak terlalu kompleks
4. **Query Capability**: Tetap bisa query fields penting tanpa parse JSON

### Next Steps:

1. ✅ Setup `dart_duckdb` (sudah selesai)
2. 📋 Design final schema berdasarkan use case spesifik
3. 🔧 Implement database service dengan migration support
4. 📦 Create repository layer dengan mapper
5. 🧪 Write integration tests
6. 📱 Test performance dengan large dataset
7. 🔒 Implement encryption jika perlu (sensitive chat data)

---

## References

- [dart_duckdb Documentation](https://github.com/yharby/duckdb-dart)
- [DuckDB SQL Syntax](https://duckdb.org/docs/sql/introduction)
- [Freezed Union Types](https://github.com/rrousselGit/freezed#union-types)
