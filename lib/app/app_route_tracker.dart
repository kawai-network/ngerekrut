import 'package:flutter/material.dart';

class AppRouteTracker extends NavigatorObserver {
  static final AppRouteTracker instance = AppRouteTracker._();

  AppRouteTracker._();

  String? _currentRouteName;

  String? get currentRouteName => _currentRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _update(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _update(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _update(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _update(previousRoute);
  }

  void _update(Route<dynamic>? route) {
    final routeName = route?.settings.name;
    if (routeName != null && routeName.isNotEmpty) {
      _currentRouteName = routeName;
      return;
    }
    _currentRouteName = route?.runtimeType.toString();
  }
}
