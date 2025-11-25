import 'package:flutter/foundation.dart';
import 'package:upnow/utils/preferences_helper.dart';

class OnboardingProvider with ChangeNotifier {
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;
  int _currentPage = 0;

  bool get isLoading => _isLoading;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  int get currentPage => _currentPage;

  Future<void> checkOnboardingStatus() async {
    _isLoading = true;
    notifyListeners();

    final hasCompleted = await PreferencesHelper.hasCompletedOnboarding();
    _hasCompletedOnboarding = hasCompleted;
    _isLoading = false;
    notifyListeners();
  }

  void setCurrentPage(int page) {
    if (_currentPage != page) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void nextPage() {
    if (_currentPage < 2) {
      // Assuming 3 pages (0, 1, 2)
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    await PreferencesHelper.setOnboardingCompleted();
    _hasCompletedOnboarding = true;
    notifyListeners();
  }
}
