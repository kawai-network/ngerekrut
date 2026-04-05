import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ngerekrut/objectbox_store_provider.dart';
import 'package:ngerekrut/flutter_chat_core/flutter_chat_core.dart';

import 'chat.dart';
import 'controllers/objectbox_chat_controller.dart';
import 'utils/typedefs.dart';

/// A wrapper around [Chat] that automatically initializes and manages
/// an [ObjectBoxChatController] for persistent chat storage.
///
/// This widget handles the entire database initialization lifecycle,
/// making it easy to add ObjectBox-powered chat to your app with minimal setup.
///
/// Features:
/// - ObjectBox persistence via LangChain ChatMessage
/// - Simple API with sessionId
/// - Automatic loading state management
/// - Error handling with customizable UI
class PersistentChat extends StatefulWidget {
  /// The ID of the currently logged-in user.
  final UserID currentUserId;

  /// Session ID untuk grouping messages.
  final String sessionId;

  /// Callback to resolve a [User] object from a [UserID].
  final ResolveUserCallback resolveUser;

  /// Callback triggered when the user attempts to send a message.
  final OnMessageSendCallback? onMessageSend;

  /// Callback triggered when a message is tapped.
  final OnMessageTapCallback? onMessageTap;

  /// Callback triggered when a message is long-pressed.
  final OnMessageLongPressCallback? onMessageLongPress;

  /// Callback triggered when a message is right-clicked.
  final OnMessageSecondaryTapCallback? onMessageSecondaryTap;

  /// Callback triggered when the attachment button is tapped.
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

  /// Number of messages to load initially.
  final int initialMessageLimit;

  /// Optional loading builder to customize the loading state.
  final Widget Function(BuildContext, double progress)? loadingBuilder;

  /// Optional error builder to customize the error state.
  final Widget Function(BuildContext, Object error)? errorBuilder;

  /// Creates a persistent chat widget with ObjectBox storage.
  const PersistentChat({
    super.key,
    required this.currentUserId,
    required this.sessionId,
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
    this.initialMessageLimit = 50,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  State<PersistentChat> createState() => _PersistentChatState();
}

class _PersistentChatState extends State<PersistentChat> {
  ObjectBoxChatController? _controller;
  Object? _error;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    ObjectBoxChatController? controller;
    try {
      if (!mounted) return;
      setState(() => _loadingProgress = 0.3);

      // Step 1: Initialize ObjectBox
      await ObjectBoxStoreProvider.initialize();

      if (!mounted) return;
      setState(() => _loadingProgress = 0.6);

      // Step 2: Create controller
      controller = ObjectBoxChatController(
        sessionId: widget.sessionId,
      );

      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _loadingProgress = 0.8);

      // Step 3: Load messages
      await controller.loadMessages(limit: widget.initialMessageLimit);

      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loadingProgress = 1.0;
        _error = null;
      });
    } catch (e) {
      controller?.dispose();
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      if (_error != null) {
        return widget.errorBuilder?.call(context, _error!) ??
            _buildErrorWidget(_error!);
      }
      return widget.loadingBuilder?.call(context, _loadingProgress) ??
          _buildLoadingWidget(_loadingProgress);
    }

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
    return Container(
      color: widget.backgroundColor ?? Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading messages... ${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    // Log full error for diagnostics
    if (kDebugMode) {
      debugPrint('Chat initialization error: $error');
    }

    return Container(
      color: widget.backgroundColor ?? Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[700]),
            const SizedBox(height: 16),
            Text(
              'Failed to load chat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                // Show user-friendly message in production
                kDebugMode ? error.toString() : 'Something went wrong. Please try again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _loadingProgress = 0.0;
                });
                _initializeController();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
