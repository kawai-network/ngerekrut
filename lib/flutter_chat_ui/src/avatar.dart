import 'package:cross_cache/cross_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ngerekrut/flutter_chat_core/flutter_chat_core.dart';
import 'package:provider/provider.dart';

/// A widget that displays a user's avatar.
///
/// Fetches user data using the provided [userId] and [ResolveUserCallback].
/// Uses [UserCache] for efficient user data retrieval.
/// Displays the user's image if available, otherwise shows initials or a default icon.
class Avatar extends StatefulWidget {
  /// The ID of the user whose avatar is to be displayed.
  final UserID userId;

  /// The size (diameter) of the avatar circle.
  final double? size;

  /// Background color for the avatar circle if no image is available.
  final Color? backgroundColor;

  /// Foreground color for the initials text or default icon.
  final Color? foregroundColor;

  /// Optional callback triggered when the avatar is tapped.
  final VoidCallback? onTap;

  /// Optional HTTP headers for authenticated image requests.
  /// Commonly used for authorization tokens, e.g., {'Authorization': 'Bearer token'}.
  final Map<String, String>? headers;

  /// Creates an avatar widget.
  const Avatar({
    super.key,
    required this.userId,
    this.size = 32,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
    this.headers,
  });

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
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
  void didUpdateWidget(covariant Avatar oldWidget) {
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
      return _buildAvatar(context, cachedUser);
    }

    // Async path - use FutureBuilder with cache
    return FutureBuilder<User?>(
      // This will update the cache when resolved
      future: _userFuture,
      builder: (context, snapshot) {
        return _buildAvatar(context, snapshot.data);
      },
    );
  }

  Widget _buildAvatar(BuildContext context, User? user) {
    final theme = context.select(
      (ChatTheme t) => (
        labelLarge: t.typography.labelLarge,
        onSurface: t.colors.onSurface,
        surfaceContainer: t.colors.surfaceContainer,
      ),
    );

    Widget avatar = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: AvatarContent(
        user: user,
        size: widget.size,
        foregroundColor: widget.foregroundColor ?? theme.onSurface,
        headers: widget.headers,
        textStyle: theme.labelLarge.copyWith(
          color: widget.foregroundColor ?? theme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (widget.onTap != null) {
      avatar = GestureDetector(onTap: widget.onTap, child: avatar);
    }

    return avatar;
  }
}

/// Internal widget responsible for rendering the actual avatar content
/// (image, initials, or icon) based on the resolved [User] data.
class AvatarContent extends StatefulWidget {
  /// The resolved user data (can be null if resolution fails or is pending).
  final User? user;

  /// The size (diameter) of the avatar.
  final double? size;

  /// The foreground color for initials or the default icon.
  final Color foregroundColor;

  /// The text style for the initials.
  final TextStyle? textStyle;

  /// Optional HTTP headers for authenticated image requests.
  /// Commonly used for authorization tokens, e.g., {'Authorization': 'Bearer token'}.
  final Map<String, String>? headers;

  /// Creates an [AvatarContent] widget.
  const AvatarContent({
    super.key,
    required this.user,
    required this.size,
    required this.foregroundColor,
    this.textStyle,
    this.headers,
  });

  @override
  State<AvatarContent> createState() => _AvatarContentState();
}

class _AvatarContentState extends State<AvatarContent> {
  late CachedNetworkImage? _cachedNetworkImage;

  @override
  void initState() {
    super.initState();

    final crossCache = context.read<CrossCache>();

    _cachedNetworkImage = widget.user?.imageSource != null
        ? CachedNetworkImage(
            widget.user!.imageSource!,
            crossCache,
            headers: widget.headers,
          )
        : null;
  }

  @override
  void didUpdateWidget(covariant AvatarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.imageSource != widget.user?.imageSource ||
        !mapEquals(oldWidget.headers, widget.headers)) {
      if (widget.user?.imageSource != null) {
        final crossCache = context.read<CrossCache>();
        final newImage = CachedNetworkImage(
          widget.user!.imageSource!,
          crossCache,
          headers: widget.headers,
        );

        precacheImage(newImage, context)
            .then((_) {
              if (!mounted) return;
              setState(() {
                _cachedNetworkImage = newImage;
              });
            })
            .catchError((error, stackTrace) {
              if (!mounted) return;
              debugPrint('Avatar precacheImage failed: $error');
            });
      } else {
        setState(() {
          _cachedNetworkImage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedNetworkImage != null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: _cachedNetworkImage!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final initials = _getInitials(widget.user);
    if (initials.isNotEmpty) {
      return Center(child: Text(initials, style: widget.textStyle));
    }

    final avatarSize = widget.size ?? 0;
    final iconSize = avatarSize > 0
        ? (avatarSize * 0.5).clamp(12.0, avatarSize)
        : 24.0;
    return Icon(Icons.person, color: widget.foregroundColor, size: iconSize);
  }

  String _getInitials(User? user) {
    if (user?.name == null || user!.name!.trim().isEmpty) return '';

    final nameParts = user.name!
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final firstInitial =
        nameParts.isNotEmpty && nameParts.first.isNotEmpty
            ? nameParts.first[0]
            : '';
    final lastInitial =
        nameParts.length > 1 && nameParts.last.isNotEmpty
            ? nameParts.last[0]
            : '';

    return '$firstInitial$lastInitial'.toUpperCase();
  }
}
