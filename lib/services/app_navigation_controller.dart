import 'package:flutter/foundation.dart';
import 'package:trailerhustle_admin/models/user_data.dart';

enum AppRoute {
  dashboard,
  giveaways,
  trailers,
  trailersReview,
  trailersAll,
  trailerTypesEdit,
  manufacturersEdit,
  notifications,
  sendPush,
  customerProfile,
}

class AppNavigationController extends ChangeNotifier {
  AppRoute _route = AppRoute.dashboard;
  AppRoute _previousRoute = AppRoute.dashboard;

  /// The user being viewed when [route] is [AppRoute.customerProfile].
  UserData? _profileUser;
  int _profileTabIndex = 0;

  AppRoute get route => _route;
  AppRoute get previousRoute => _previousRoute;
  UserData? get profileUser => _profileUser;
  int get profileTabIndex => _profileTabIndex;

  void go(AppRoute route) {
    if (_route == route) return;
    _previousRoute = _route;
    _route = route;
    _profileUser = null;
    _profileTabIndex = 0;
    notifyListeners();
  }

  /// Navigate to the full-page customer profile.
  void goToProfile(UserData user, {int tabIndex = 0}) {
    _previousRoute = _route;
    _route = AppRoute.customerProfile;
    _profileUser = user;
    _profileTabIndex = tabIndex;
    notifyListeners();
  }

  /// Update the profile user in-place (e.g. after an edit) without navigating.
  void updateProfileUser(UserData user) {
    _profileUser = user;
    notifyListeners();
  }

  /// Go back to the previous route.
  void goBack() {
    _route = _previousRoute;
    _profileUser = null;
    _profileTabIndex = 0;
    notifyListeners();
  }
}
