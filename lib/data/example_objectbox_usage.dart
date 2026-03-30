/// Complete example of using ObjectBox with flutter_chat_core.
///
/// This example demonstrates:
/// 1. Initialize ObjectBox database
/// 2. Create ObjectBoxChatController
/// 3. Send and receive messages
/// 4. Vector search (semantic search)
/// 5. Reactions and other features
library;

import 'package:flutter/material.dart';
import '../data/objectbox/objectbox.dart';
import '../flutter_chat_core/src/models/message.dart';
import '../flutter_chat_core/src/models/user.dart';

/// Initialize ObjectBox and create controller
Future<ObjectBoxChatController> initializeChatController() async {
  // 1. Initialize ObjectBox (call once at app startup)
  await ObjectBoxStoreProvider.initialize();

  // 2. Create repositories
  final messageRepository = ObjectBoxMessageRepository();
  final userRepository = ObjectBoxUserRepository();

  // 3. Create controller
  final controller = ObjectBoxChatController(
    messageRepository: messageRepository,
    userRepository: userRepository,
  );

  // 4. Load existing messages
  await controller.loadMessages(limit: 50);

  return controller;
}

/// Example Flutter widget using ObjectBoxChatController
class ObjectBoxChatExample extends StatefulWidget {
  const ObjectBoxChatExample({super.key});

  @override
  State<ObjectBoxChatExample> createState() => _ObjectBoxChatExampleState();
}

class _ObjectBoxChatExampleState<StatefulWidget>
    extends State<ObjectBoxChatExample> {
  ObjectBoxChatController? _controller;
  final User _currentUser = const User(
    id: 'user1',
    name: 'John Doe',
  );

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    _controller = await initializeChatController();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ObjectBox Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _controller!.messages.length,
              itemBuilder: (context, index) {
                final message = _controller!.messages.reversed.toList()[index];
                return ListTile(
                  title: Text((message as TextMessage).text),
                  subtitle: Text('By: ${message.authorId}'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onSubmitted: (text) => _sendMessage(text),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // Handle send
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (_controller == null) return;

    final message = Message.text(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: _currentUser.id,
      text: text,
      createdAt: DateTime.now(),
    );

    await _controller!.insertMessage(message);
  }
}

/// Example: Vector Search (Semantic Search)
class VectorSearchExample {
  final ObjectBoxChatController _controller;

  VectorSearchExample(this._controller);

  /// Search messages by meaning, not keywords
  Future<void> semanticSearch() async {
    // Example: Compute embedding (replace with your embedding model)
    final queryVector = await _computeEmbedding('What is the weather?');

    // Search by vector
    final results = await _controller.searchByVector(
      queryVector,
      limit: 10,
      minSimilarity: 0.7, // Only show results with 70%+ similarity
    );

    // Results include similarity scores
    for (final (message, score) in results) {
      print('Message: ${(message as TextMessage).text}');
      print('Similarity: $score');
    }
  }

  /// Find messages similar to a given message
  Future<void> findSimilarMessages(String messageId) async {
    final similar = await _controller.getSimilarMessages(
      messageId,
      limit: 5,
    );

    print('Similar messages:');
    for (final message in similar) {
      print('- ${(message as TextMessage).text}');
    }
  }

  /// Batch compute embeddings for all messages
  Future<void> computeAllEmbeddings() async {
    // Get messages without embeddings
    final messagesToEmbed =
        await _controller.getMessagesWithoutEmbedding(limit: 100);

    print('Computing embeddings for ${messagesToEmbed.length} messages...');

    // Compute and store embeddings
    for (final message in messagesToEmbed) {
      final text = (message as TextMessage).text;
      final embedding = await _computeEmbedding(text);
      await _controller.updateMessageEmbedding(message.id, embedding);
    }

    print('Done!');
  }

  /// Example embedding computation
  /// Replace this with actual embedding model (e.g., ONNX, TensorFlow Lite, or API)
  Future<List<double>> _computeEmbedding(String text) async {
    // TODO: Replace with actual embedding computation
    // Options:
    // 1. Use mobile_rag_engine for on-device embeddings
    // 2. Use ONNX Runtime with a sentence-transformers model
    // 3. Call cloud API (OpenAI, Cohere, etc.)

    // Placeholder: Return random vector (NOT FOR PRODUCTION!)
    return List.generate(768, (index) => (index % 100) / 100);
  }
}

/// Minimal app wrapper for running the example.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ObjectBox Chat',
      home: ObjectBoxChatExample(),
    );
  }
}

/// Example: Using ObjectBox in main.dart
class MainExample {
  static Future<void> initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize ObjectBox
    await ObjectBoxStoreProvider.initialize();

    // Now you can use ObjectBoxChatController anywhere in your app
    runApp(const MyApp());
  }
}

/// Example: Global chat controller singleton
class ChatService {
  static late ObjectBoxChatController _chatController;

  static Future<void> initialize() async {
    await ObjectBoxStoreProvider.initialize();

    _chatController = ObjectBoxChatController(
      messageRepository: ObjectBoxMessageRepository(),
      userRepository: ObjectBoxUserRepository(),
    );

    // Load recent messages
    await _chatController.loadMessages(limit: 50);
  }

  static ObjectBoxChatController get chatController => _chatController;
}

/// Example: Reaction handling
class ReactionExample {
  final ObjectBoxChatController _controller;

  ReactionExample(this._controller);

  /// Add a reaction to a message
  Future<void> addReaction(String messageId, String userId) async {
    await _controller.addReaction(messageId, userId, '👍');
  }

  /// Remove a reaction
  Future<void> removeReaction(String messageId, String userId) async {
    await _controller.removeReaction(messageId, userId, '👍');
  }
}

/// Example: Search and pagination
class SearchExample {
  final ObjectBoxChatController _controller;

  SearchExample(this._controller);

  /// Search by text
  Future<List<Message>> searchText(String query) async {
    return await _controller.searchMessages(query, limit: 20);
  }

  /// Get pinned messages
  Future<List<Message>> getPinned() async {
    return await _controller.getPinnedMessages(limit: 10);
  }

  /// Load older messages (pagination)
  Future<List<Message>> loadOlderMessages() async {
    if (_controller.messages.isEmpty) return [];

    final oldestMessage = _controller.messages.first;
    return await _controller.loadOlderMessages(
      before: oldestMessage.createdAt!,
      limit: 20,
    );
  }
}
