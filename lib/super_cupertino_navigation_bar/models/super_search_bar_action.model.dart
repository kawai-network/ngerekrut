import 'package:flutter/cupertino.dart';
import '../models/super_search_bar.model.dart';

class SuperAction extends StatelessWidget {
  const SuperAction({
    super.key,
    required this.child,
    this.behavior = SuperActionBehavior.visibleOnFocus,
  });
  final Widget child;
  final SuperActionBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
