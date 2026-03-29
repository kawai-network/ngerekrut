# 🦆 DuckDB Integration dengan flutter_chat_core

## ✅ SELESAI - Integrasi Lengkap!

Saya telah membuat **DuckDBChatController** yang menghubungkan `flutter_chat_core` dengan `data` layer (DuckDB).

---

## 📁 File Yang Dibuat

```
lib/data/
├── controllers/
│   └── duckdb_chat_controller.dart    # ⭐ JEMBATAN UTAMA
├── example_integration.dart           # Contoh penggunaan lengkap
└── ... (file sebelumnya)
```

---

## 🔗 Cara Integrasi

### `flutter_chat_core` TIDAK otomatis menggunakan DuckDB

Anda perlu **mengganti controller** yang digunakan di aplikasi:

### Sebelum (In-Memory):
```dart
// ❌ Data hilang saat app restart
final controller = InMemoryChatController();
```

### Sesudah (DuckDB Persistent):
```dart
// ✅ Data tetap ada saat app restart
final controller = DuckDBChatController(
  messageRepository: MessageRepository(database),
  userRepository: UserRepository(database),
);
```

---

## 📖 Panduan Lengkap

### 1. Initialize Database & Controller

```dart
import 'package:ngerekrut/data/data.dart';

Future<DuckDBChatController> initializeApp() async {
  // 1. Dapatkan path database
  final dbPath = await DatabasePathProvider.getDatabasePath();

  // 2. Buat dan initialize database
  final database = ChatDatabaseService(dbPath: dbPath);
  await database.initialize();

  // 3. Buat repositories
  final messageRepo = MessageRepository(database);
  final userRepo = UserRepository(database);

  // 4. Buat controller dengan DuckDB
  final chatController = DuckDBChatController(
    messageRepository: messageRepo,
    userRepository: userRepo,
  );

  // 5. Load messages dari database
  await chatController.loadMessages(limit: 50);

  return chatController;
}
```

---

### 2. Gunakan di Flutter Widget

```dart
class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  DuckDBChatController? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _controller = await initializeApp();
    
    // Listen untuk update UI
    _controller!.operationsStream.listen((operation) {
      setState(() {}); // Rebuild UI saat ada perubahan
    });
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return CircularProgressIndicator();
    }

    return ListView.builder(
      itemCount: _controller!.messages.length,
      itemBuilder: (context, index) {
        final message = _controller!.messages[index];
        return MessageTile(message: message);
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
```

---

### 3. Kirim Pesan (Otomatis Tersimpan ke DuckDB)

```dart
// Sama seperti InMemoryChatController!
final message = Message.text(
  id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
  authorId: currentUserId,
  text: 'Hello, World!',
  createdAt: DateTime.now(),
  status: MessageStatus.sent,
);

await _controller!.insertMessage(message);
// ✅ Otomatis tersimpan ke DuckDB!
```

---

### 4. Load Older Messages (Pagination)

```dart
// Saat user scroll ke atas untuk load more
Future<void> _loadOlderMessages() async {
  final oldestMessage = _controller!.messages.first;
  final before = oldestMessage.createdAt;
  
  if (before != null) {
    final olderMessages = await _controller!.loadOlderMessages(
      before: before,
      limit: 20,
    );
    // ✅ Otomatis update UI
  }
}
```

---

### 5. Fitur Lengkap yang Tersedia

```dart
// ✅ CRUD Messages
await _controller.insertMessage(message);
await _controller.insertAllMessages(messages);
await _controller.updateMessage(oldMessage, newMessage);
await _controller.removeMessage(message);

// ✅ Load Messages
await _controller.loadMessages(limit: 50);
await _controller.loadOlderMessages(before: date, limit: 20);

// ✅ Search
final results = await _controller.searchMessages('keyword');

// ✅ Reactions
await _controller.addReaction(messageId, userId, '👍');
await _controller.removeReaction(messageId, userId, '👍');

// ✅ Users
await _controller.saveUser(user);
final user = await _controller.getUser(userId);
await _controller.loadUsers();

// ✅ Statistics
final stats = await _controller.getMessageStats();
final pinned = await _controller.getPinnedMessages();
```

---

## 🎯 Perbedaan InMemory vs DuckDB Controller

| Aspek | InMemoryChatController | DuckDBChatController |
|-------|----------------------|---------------------|
| **Storage** | RAM (volatile) | DuckDB file (persistent) |
| **Data setelah restart** | ❌ Hilang | ✅ Tetap ada |
| **API** | Sama persis | Sama persis |
| **Performance** | ⚡ Sangat cepat | ⚡ Cepat (dengan cache) |
| **File size** | 0 bytes | Sesuai data (compressed) |
| **Offline support** | ❌ Terbatas | ✅ Penuh |

---

## 📂 Struktur Data di DuckDB

```
chat.db
├── messages table
│   ├── id, type, author_id
│   ├── timestamps (created, sent, seen, etc.)
│   ├── status, pinned
│   ├── text_content
│   ├── media_source
│   ├── media_metadata (JSON)
│   └── custom_metadata (JSON)
├── users table
│   ├── id, name, image_source
│   ├── created_at
│   └── metadata (JSON)
└── reactions table
    ├── message_id
    ├── reaction_key (👍, ❤️, etc.)
    └── user_id
```

---

## 🚀 Migration dari InMemory ke DuckDB

### Step 1: Ganti Controller Initialization

```dart
// OLD:
// final controller = InMemoryChatController();

// NEW:
final controller = DuckDBChatController(
  messageRepository: MessageRepository(database),
  userRepository: UserRepository(database),
);
```

### Step 2: Load Existing Messages

```dart
// Tambahkan ini setelah create controller
await controller.loadMessages(limit: 50);
```

### Step 3: Selesai!

Tidak ada perubahan lain yang diperlukan. API-nya sama persis!

---

## 💡 Best Practices

### 1. Single Instance Pattern

```dart
class ChatService {
  static DuckDBChatController? _instance;

  static Future<DuckDBChatController> getInstance() async {
    if (_instance == null) {
      final db = ChatDatabaseService(
        dbPath: await DatabasePathProvider.getDatabasePath(),
      );
      await db.initialize();
      
      _instance = DuckDBChatController(
        messageRepository: MessageRepository(db),
        userRepository: UserRepository(db),
      );
      
      await _instance!.loadMessages();
    }
    return _instance!;
  }
}

// Usage:
final controller = await ChatService.getInstance();
```

### 2. Cleanup on Dispose

```dart
@override
void dispose() {
  _controller?.dispose();
  super.dispose();
}
```

### 3. Error Handling

```dart
try {
  await _controller.insertMessage(message);
} catch (e) {
  debugPrint('Failed to save message: $e');
  // Show error UI, retry, etc.
}
```

---

## 📊 Performance Tips

1. **Batch Insert**: Gunakan `insertAllMessages` untuk multiple messages
2. **Pagination**: Load messages secara bertahap (limit 20-50)
3. **Indexes**: Sudah dibuat otomatis untuk query umum
4. **Cache**: Controller maintain in-memory cache untuk fast access

---

## 🧪 Testing

```dart
void main() async {
  // Test dengan in-memory database
  final database = ChatDatabaseService(); // ':memory:'
  await database.initialize();
  
  final controller = DuckDBChatController(
    messageRepository: MessageRepository(database),
    userRepository: UserRepository(database),
  );
  
  // Test insert
  final message = Message.text(
    id: 'test_1',
    authorId: 'user_1',
    text: 'Test',
    createdAt: DateTime.now(),
  );
  await controller.insertMessage(message);
  
  // Test load
  await controller.loadMessages();
  assert(controller.messages.length == 1);
  
  // Cleanup
  controller.dispose();
}
```

---

## ✅ Checklist Integrasi

- [x] DuckDBChatController dibuat
- [x] API sama dengan InMemoryChatController
- [x] Auto-persist ke DuckDB
- [x] Load messages on init
- [x] Pagination support
- [x] Reaction support
- [x] User management
- [x] Search functionality
- [x] Example code lengkap
- [x] No compile errors

---

## 🎉 Kesimpulan

**`flutter_chat_core` sekarang otomatis menggunakan DuckDB** dengan cara:

1. Ganti `InMemoryChatController` → `DuckDBChatController`
2. Initialize database di awal
3. Call `loadMessages()` setelah create controller
4. **Selesai!** Semua operasi otomatis tersimpan ke DuckDB

API-nya **100% compatible**, jadi tidak perlu ubah code lain! 🚀
