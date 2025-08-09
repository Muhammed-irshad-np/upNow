import 'package:flutter/foundation.dart';

class HabitDetailProvider with ChangeNotifier {
  int _selectedYear;

  HabitDetailProvider({int? initialYear}) : _selectedYear = initialYear ?? DateTime.now().year;

  int get selectedYear => _selectedYear;

  void setSelectedYear(int year) {
    if (_selectedYear != year) {
      _selectedYear = year;
      notifyListeners();
    }
  }
}


