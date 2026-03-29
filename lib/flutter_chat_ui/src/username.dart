import 'package:flutter/material.dart';
import 'package:ngerekrut/flutter_chat_core/flutter_chat_core.dart';
import 'package:provider/provider.dart';

/// A widget that displays a user's name.
///
/// Fetches user data using the provided [userId] and [ResolveUserCallback].
/// Uses [UserCache] for efficient user data retrieval.
/// Displays the user's name if available, otherwise a placeholder.
class Username extends StatefulWidget {
  /// The ID of the user whose name is to be displayed.
  final UserID userId;

  /// Optional text style for the username.
  final TextStyle? style;

  /// Creates a username widget.
  const Username({super.key, required this.userId, this.style});

  @override
  State<Username> createState() => _UsernameState();
}

class _UsernameState extends State<Username> {
  Future<User?>? _userFuture;
  UserID? _lastUserId;
  ResolveUserCallback? _lastResolveUser;

  void _updateUserFuture(
    UserCache userCache,
    ResolveUserCallback resolveUser,
  ) {
    if (_userFuture == null ||
        _lastUserId != widget.userId ||
        _lastResolveUser != resolveUser) {
      _lastUserId = widget.userId;
      _lastResolveUser = resolveUser;
      _userFuture = userCache.getOrResolve(widget.userId, resolveUser);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resolveUser = context.read<ResolveUserCallback>();
    final userCache = context.read<UserCache>();
    _updateUserFuture(userCache, resolveUser);
  }

  @override
  void didUpdateWidget(covariant Username oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      final resolveUser = context.read<ResolveUserCallback>();
      final userCache = context.read<UserCache>();
      _updateUserFuture(userCache, resolveUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolveUser = context.read<ResolveUserCallback>();
    final userCache = context.watch<UserCache>();
    _updateUserFuture(userCache, resolveUser);

    // Try to get from cache synchronously first
    final cachedUser = userCache.getSync(widget.userId);

    if (cachedUser != null) {
      // Sync path - no FutureBuilder needed
      return _buildUsername(context, cachedUser);
    }

    // Async path - use FutureBuilder with cache
    return FutureBuilder<User?>(
      // This will update the cache when resolved
      future: _userFuture,
      builder: (context, snapshot) {
        return _buildUsername(context, snapshot.data);
      },
    );
  }

  Widget _buildUsername(BuildContext context, User? user) {
    final theme = context.select(
      (ChatTheme t) => (
        labelMedium: t.typography.labelMedium,
        onSurface: t.colors.onSurface,
      ),
    );

    final defaultStyle = theme.labelMedium.copyWith(color: theme.onSurface);

    return Text(
      user?.name ?? 'Unknown user',
      style: widget.style ?? defaultStyle,
    );
  }
}
