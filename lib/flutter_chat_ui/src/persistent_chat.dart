import 'package:flutter/material.dart';
import 'package:ngerekrut/data/data.dart';
import 'package:ngerekrut/flutter_chat_core/flutter_chat_core.dart';

import 'chat.dart';
import 'utils/typedefs.dart';

/// A wrapper around [Chat] that automatically initializes and manages
/// a [DuckDBChatController] for persistent chat storage.
///
/// This widget handles the entire database initialization lifecycle,
/// making it easy to add DuckDB-powered chat to your app with minimal setup.
///
/// Example usage:
/// ```dart
/// PersistentChat(
///   currentUserId: 'user_123',
///   resolveUser: (userId) async => getUserFromApi(userId),
///   onMessageSend: (message) async => sendMessageToBackend(message),
/// )
/// ```
///
/// The widget will:
/// 1. Initialize DuckDB database on first build
/// 2. Create [DuckDBChatController] with persistent storage
/// 3. Load existing messages from database
/// 4. Display a loading indicator while initializing
/// 5. Show the chat UI once ready
/// 6. Properly dispose resources when removed
class PersistentChat extends StatefulWidget {
  /// The ID of the currently logged-in user.
  final UserID currentUserId;

  /// Callback to resolve a [User] object from a [UserID].
  final ResolveUserCallback resolveUser;

  /// Callback triggered when the user attempts to send a message.
  /// If not provided, messages are only saved locally.
  final OnMessageSendCallback? onMessageSend;

  /// Callback triggered when a message is tapped.
  final OnMessageTapCallback? onMessageTap;

  /// Callback triggered when a message is long-pressed.
  final OnMessageLongPressCallback? onMessageLongPress;

  /// Callback triggered when a message is right-clicked (secondary tapped).
  final OnMessageSecondaryTapCallback? onMessageSecondaryTap;

  /// Callback triggered when the attachment button in the composer is tapped.
  final OnAttachmentTapCallback? onAttachmentTap;

  /// Collection of custom builder functions for UI components.
  final Builders? builders;

  /// The visual theme for the chat UI.
  final ChatTheme? theme;

  /// Background color for the main chat container.
  final Color? backgroundColor;

  /// Decoration for the main chat container.
  final Decoration? decoration;

  /// Date format for displaying message timestamps.
  final DateFormat? timeFormat;

  /// Custom database path. If null, uses default platform-specific path.
  final String? databasePath;

  /// Number of messages to load initially.
  final int initialMessageLimit;

  /// Optional loading builder to customize the loading state.
  final Widget Function(BuildContext, double progress)? loadingBuilder;

  /// Optional error builder to customize the error state.
  final Widget Function(BuildContext, Object error)? errorBuilder;

  /// Creates a persistent chat widget with DuckDB storage.
  const PersistentChat({
    super.key,
    required this.currentUserId,
    required this.resolveUser,
    this.onMessageSend,
    this.onMessageTap,
    this.onMessageLongPress,
    this.onMessageSecondaryTap,
    this.onAttachmentTap,
    this.builders,
    this.theme,
    this.backgroundColor,
    this.decoration,
    this.timeFormat,
    this.databasePath,
    this.initialMessageLimit = 50,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  State<PersistentChat> createState() => _PersistentChatState();
}

class _PersistentChatState extends State<PersistentChat> {
  DuckDBChatController? _controller;
  Object? _error;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      setState(() {
        _loadingProgress = 0.2;
      });

      // Step 1: Get database path
      final dbPath = widget.databasePath ??
          await DatabasePathProvider.getDatabasePath();

      setState(() {
        _loadingProgress = 0.4;
      });

      // Step 2: Initialize database
      final database = ChatDatabaseService(dbPath: dbPath);
      await database.initialize();

      setState(() {
        _loadingProgress = 0.6;
      });

      // Step 3: Create repositories
      final messageRepository = MessageRepository(database);
      final userRepository = UserRepository(database);

      setState(() {
        _loadingProgress = 0.8;
      });

      // Step 4: Create controller
      _controller = DuckDBChatController(
        messageRepository: messageRepository,
        userRepository: userRepository,
      );

      // Step 5: Load messages
      await _controller!.loadMessages(limit: widget.initialMessageLimit);

      setState(() {
        _loadingProgress = 1.0;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing
    if (_controller == null) {
      if (_error != null) {
        return widget.errorBuilder?.call(context, _error!) ??
            _buildErrorWidget(_error!);
      }

      return widget.loadingBuilder?.call(context, _loadingProgress) ??
          _buildLoadingWidget(_loadingProgress);
    }

    // Chat is ready, display the actual chat UI
    return Chat(
      currentUserId: widget.currentUserId,
      resolveUser: widget.resolveUser,
      chatController: _controller!,
      builders: widget.builders,
      theme: widget.theme,
      backgroundColor: widget.backgroundColor,
      decoration: widget.decoration,
      timeFormat: widget.timeFormat,
      onMessageSend: widget.onMessageSend,
      onMessageTap: widget.onMessageTap,
      onMessageLongPress: widget.onMessageLongPress,
      onMessageSecondaryTap: widget.onMessageSecondaryTap,
      onAttachmentTap: widget.onAttachmentTap,
    );
  }

  Widget _buildLoadingWidget(double progress) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(value: progress),
            const SizedBox(height: 16),
            Text(
              'Loading chat...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load chat',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _loadingProgress = 0.0;
                  });
                  _initializeDatabase();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// A mixin that provides DuckDB persistence capabilities to any widget
/// that uses a [ChatController].
///
/// This is useful when you want to add persistence to an existing widget
/// that already manages its own controller.
mixin DuckDBPersistenceMixin<T extends StatefulWidget> on State<T> {
  /// The DuckDB chat controller. Null until initialized.
  DuckDBChatController? _persistenceController;
  bool _isInitialized = false;

  /// Initializes the DuckDB persistence layer.
  ///
  /// Call this in your widget's [State.initState] method.
  @protected
  Future<void> initializePersistence({
    String? databasePath,
    int messageLimit = 50,
  }) async {
    if (_isInitialized) return;

    final dbPath = databasePath ??
        await DatabasePathProvider.getDatabasePath();

    final database = ChatDatabaseService(dbPath: dbPath);
    await database.initialize();

    _persistenceController = DuckDBChatController(
      messageRepository: MessageRepository(database),
      userRepository: UserRepository(database),
    );

    await _persistenceController!.loadMessages(limit: messageLimit);
    _isInitialized = true;
  }

  /// Gets the persistence controller, throwing an error if not initialized.
  @protected
  DuckDBChatController get persistenceController {
    if (!_isInitialized || _persistenceController == null) {
      throw StateError(
        'DuckDB persistence not initialized. '
        'Call initializePersistence() first.',
      );
    }
    return _persistenceController!;
  }

  /// Checks if persistence is initialized.
  bool get isPersistenceInitialized => _isInitialized;

  /// Cleans up persistence resources.
  ///
  /// Call this in your widget's [State.dispose] method.
  @override
  @mustCallSuper
  void dispose() {
    _persistenceController?.dispose();
    super.dispose();
  }
}

/// Extension to easily wrap any chat widget with DuckDB persistence.
extension PersistentChatExtension on Widget {
  /// Wraps this widget with [PersistentChat] functionality.
  ///
  /// This is useful when you have a custom chat widget that you want
  /// to make persistent without modifying its internals.
  Widget withDuckDBPersistence({
    required UserID currentUserId,
    required ResolveUserCallback resolveUser,
    OnMessageSendCallback? onMessageSend,
    OnMessageTapCallback? onMessageTap,
    OnMessageLongPressCallback? onMessageLongPress,
    OnMessageSecondaryTapCallback? onMessageSecondaryTap,
    OnAttachmentTapCallback? onAttachmentTap,
    Builders? builders,
    ChatTheme? theme,
    Color? backgroundColor,
    Decoration? decoration,
    DateFormat? timeFormat,
    String? databasePath,
    int initialMessageLimit = 50,
  }) {
    return PersistentChat(
      currentUserId: currentUserId,
      resolveUser: resolveUser,
      onMessageSend: onMessageSend,
      onMessageTap: onMessageTap,
      onMessageLongPress: onMessageLongPress,
      onMessageSecondaryTap: onMessageSecondaryTap,
      onAttachmentTap: onAttachmentTap,
      builders: builders,
      theme: theme,
      backgroundColor: backgroundColor,
      decoration: decoration,
      timeFormat: timeFormat,
      databasePath: databasePath,
      initialMessageLimit: initialMessageLimit,
      // Note: The original widget is replaced by PersistentChat
    );
  }
}
