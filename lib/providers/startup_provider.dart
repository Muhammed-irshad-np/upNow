import 'package:flutter/foundation.dart';
import 'package:upnow/utils/preferences_helper.dart';

class StartupProvider with ChangeNotifier {
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;

  bool get isLoading => _isLoading;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  Future<void> checkOnboardingStatus() async {
    _isLoading = true;
    notifyListeners();
    final hasCompleted = await PreferencesHelper.hasCompletedOnboarding();
    _hasCompletedOnboarding = hasCompleted;
    _isLoading = false;
    notifyListeners();
  }
}


