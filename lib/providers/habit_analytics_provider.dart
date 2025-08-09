import 'package:flutter/foundation.dart';
import 'package:upnow/models/habit_model.dart';

class HabitAnalyticsProvider with ChangeNotifier {
  String _selectedPeriod = 'week';
  HabitModel? _selectedHabit;

  String get selectedPeriod => _selectedPeriod;
  HabitModel? get selectedHabit => _selectedHabit;

  void setSelectedPeriod(String period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      notifyListeners();
    }
  }

  void setSelectedHabit(HabitModel? habit) {
    if (_selectedHabit != habit) {
      _selectedHabit = habit;
      notifyListeners();
    }
  }
}


