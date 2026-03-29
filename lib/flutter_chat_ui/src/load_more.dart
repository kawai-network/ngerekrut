import 'package:flutter/material.dart';
import 'package:ngerekrut/flutter_chat_core/flutter_chat_core.dart';
import 'package:provider/provider.dart';

/// A widget displayed at the top of the chat list when paginating
/// (loading more historical messages).
///
/// Typically shows a [CircularProgressIndicator].
class LoadMore extends StatelessWidget {
  /// Color of the progress indicator. Defaults to theme's `onSurface`.
  final Color? color;

  /// Vertical padding around the indicator.
  final double padding;

  /// Size (diameter) of the progress indicator.
  final double size;

  /// Creates a load more indicator widget.
  const LoadMore({
    super.key,
    this.color,
    this.padding = 20,
    this.size = 20,
  }) : assert(padding >= 0),
       assert(size >= 0);

  @override
  Widget build(BuildContext context) {
    final onSurface = context.select((ChatTheme t) => t.colors.onSurface);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: Center(
        child: SizedBox(
          height: size,
          width: size,
          child: CircularProgressIndicator(
            color: color ?? onSurface,
            strokeCap: StrokeCap.round,
          ),
        ),
      ),
    );
  }
}
