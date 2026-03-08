import 'package:flutter/foundation.dart';

enum AppRoute {
  dashboard,
  giveaways,
  trailers,
  trailersReview,
  trailersAll,
  trailerTypesEdit,
  manufacturersEdit,
  notifications,
}

class AppNavigationController extends ChangeNotifier {
  AppRoute _route = AppRoute.dashboard;

  AppRoute get route => _route;

  void go(AppRoute route) {
    if (_route == route) return;
    _route = route;
    notifyListeners();
  }
}
