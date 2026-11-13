import 'dart:async';
import 'dart:collection';

import 'package:material_ui/material_ui.dart';

import 'package:lttbdd_nhom8/widgets/intro_dialog.dart';

class IntroDialogObserver extends NavigatorObserver {
  final Queue<Route<dynamic>> _pendingRoutes = Queue<Route<dynamic>>();
  final Set<Route<dynamic>> _queuedRoutes = HashSet<Route<dynamic>>.identity();
  bool _isShowing = false;
  bool _drainScheduled = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _enqueuePageRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _enqueuePageRoute(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute && previousRoute != null) {
      _enqueuePageRoute(previousRoute);
    }
  }

  void _enqueuePageRoute(Route<dynamic> route) {
    if (route is! PageRoute || !_queuedRoutes.add(route)) return;
    _pendingRoutes.add(route);
    _scheduleDrain();
  }

  void _scheduleDrain() {
    if (_isShowing || _drainScheduled) return;
    _drainScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drainScheduled = false;
      unawaited(_showPendingIntros());
    });
  }

  Future<void> _showPendingIntros() async {
    if (_isShowing) return;
    _isShowing = true;
    try {
      while (_pendingRoutes.isNotEmpty) {
        final route = _pendingRoutes.removeFirst();
        _queuedRoutes.remove(route);
        if (!route.isActive || !route.isCurrent) continue;

        final currentNavigator = navigator;
        if (currentNavigator == null || !currentNavigator.mounted) continue;

        try {
          await IntroDialog.show(currentNavigator.context);
        } catch (error, stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'intro dialog',
              context: ErrorDescription('when showing an intro for a route'),
            ),
          );
        }
      }
    } finally {
      _isShowing = false;
      if (_pendingRoutes.isNotEmpty) _scheduleDrain();
    }
  }
}
