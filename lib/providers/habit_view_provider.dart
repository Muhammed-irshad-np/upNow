import 'package:flutter/foundation.dart';

class HabitViewProvider with ChangeNotifier {
  bool _showWeeklyView = true;

  bool get showWeeklyView => _showWeeklyView;

  void toggleView() {
    _showWeeklyView = !_showWeeklyView;
    notifyListeners();
  }

  void setWeeklyView(bool showWeekly) {
    if (_showWeeklyView != showWeekly) {
      _showWeeklyView = showWeekly;
      notifyListeners();
    }
  }

  void setShowWeeklyView(bool showWeekly) {
    if (_showWeeklyView != showWeekly) {
      _showWeeklyView = showWeekly;
      notifyListeners();
    }
  }
}
