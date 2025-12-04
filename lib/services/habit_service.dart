import 'package:flutter/foundation.dart';
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/database/hive_database.dart';

class HabitService extends ChangeNotifier {
  List<HabitModel> _habits = [];
  List<HabitEntry> _habitEntries = [];

  List<HabitModel> get habits => _habits;
  List<HabitEntry> get habitEntries => _habitEntries;

  // Initialize the service and load data
  Future<void> initialize() async {
    await loadHabits();
    await loadHabitEntries();
  }

  // Load all habits from database
  Future<void> loadHabits() async {
    _habits = HiveDatabase.getAllHabits();
    _habits.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();
  }

  // Load all habit entries from database
  Future<void> loadHabitEntries() async {
    _habitEntries = HiveDatabase.getAllHabitEntries();
    _habitEntries.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  // Create a new habit
  Future<HabitModel> createHabit(HabitModel habit) async {
    await HiveDatabase.saveHabit(habit);
    _habits.add(habit);
    _habits.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();
    return habit;
  }

  // Update an existing habit
  Future<void> updateHabit(HabitModel habit) async {
    await HiveDatabase.saveHabit(habit);
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
      notifyListeners();
    }
  }

  // Delete a habit and all its entries
  Future<void> deleteHabit(String habitId) async {
    await HiveDatabase.deleteHabit(habitId);
    _habits.removeWhere((h) => h.id == habitId);
    _habitEntries.removeWhere((e) => e.habitId == habitId);
    notifyListeners();
  }

  // Mark habit as completed for a specific date (git-like commit)
  Future<HabitEntry> markHabitCompleted(
    String habitId,
    DateTime date, {
    String? notes,
    HabitIntensity? intensity,
    int completionCount = 1,
  }) async {
    final existingEntry = getHabitEntryForDate(habitId, date);

    HabitEntry entry;
    if (existingEntry != null) {
      // Update existing entry
      entry = existingEntry.copyWith(
        completed: true,
        completionCount: completionCount,
        completedAt: DateTime.now(),
        notes: notes,
        intensity: intensity,
      );
    } else {
      // Create new entry
      entry = HabitEntry(
        habitId: habitId,
        date: date,
        completed: true,
        completionCount: completionCount,
        completedAt: DateTime.now(),
        notes: notes,
        intensity: intensity,
      );
    }

    await HiveDatabase.saveHabitEntry(entry);

    // Update local list
    final index = _habitEntries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _habitEntries[index] = entry;
    } else {
      _habitEntries.add(entry);
    }

    _habitEntries.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();

    return entry;
  }

  // Mark habit as not completed for a specific date
  Future<void> markHabitUncompleted(String habitId, DateTime date) async {
    final existingEntry = getHabitEntryForDate(habitId, date);

    if (existingEntry != null) {
      final updatedEntry = existingEntry.copyWith(
        completed: false,
        completionCount: 0,
        completedAt: null,
      );

      await HiveDatabase.saveHabitEntry(updatedEntry);

      final index = _habitEntries.indexWhere((e) => e.id == updatedEntry.id);
      if (index != -1) {
        _habitEntries[index] = updatedEntry;
        notifyListeners();
      }
    }
  }

  // Get habit entry for a specific date
  HabitEntry? getHabitEntryForDate(String habitId, DateTime date) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    for (var entry in _habitEntries) {
      if (entry.habitId == habitId && entry.dateKey == dateKey) {
        return entry;
      }
    }

    return null;
  }

  // Get all entries for a specific habit
  List<HabitEntry> getHabitEntries(String habitId) {
    return _habitEntries.where((entry) => entry.habitId == habitId).toList();
  }

  // Get habit completion data for a year (GitHub-style grid)
  Map<String, HabitEntry> getHabitYearData(String habitId, int year) {
    final entries = getHabitEntries(habitId);
    final Map<String, HabitEntry> yearData = {};

    for (var entry in entries) {
      if (entry.date.year == year) {
        yearData[entry.dateKey] = entry;
      }
    }

    return yearData;
  }

  // Get current streak for a habit
  int getCurrentStreak(String habitId) {
    final entries = getHabitEntries(habitId);
    entries.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final entry = getHabitEntryForDate(habitId, checkDate);

      if (entry != null && entry.completed) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  // Get longest streak for a habit
  int getLongestStreak(String habitId) {
    final entries = getHabitEntries(habitId);
    entries.sort((a, b) => a.date.compareTo(b.date));

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    for (var entry in entries) {
      if (entry.completed) {
        if (lastDate == null || entry.date.difference(lastDate).inDays == 1) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }

        maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
        lastDate = entry.date;
      } else {
        currentStreak = 0;
        lastDate = null;
      }
    }

    return maxStreak;
  }

  // Get completion rate for a habit in percentage
  double getCompletionRate(String habitId, {int? days}) {
    final entries = getHabitEntries(habitId);

    if (days != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final recentEntries =
          entries.where((e) => e.date.isAfter(cutoffDate)).toList();

      if (recentEntries.isEmpty) return 0.0;

      final completedCount = recentEntries.where((e) => e.completed).length;
      return (completedCount / recentEntries.length) * 100;
    }

    if (entries.isEmpty) return 0.0;

    final completedCount = entries.where((e) => e.completed).length;
    return (completedCount / entries.length) * 100;
  }

  // Get habit statistics
  HabitStats getHabitStats(String habitId) {
    final entries = getHabitEntries(habitId);
    final completedEntries = entries.where((e) => e.completed).toList();

    return HabitStats(
      totalDays: entries.length,
      completedDays: completedEntries.length,
      currentStreak: getCurrentStreak(habitId),
      longestStreak: getLongestStreak(habitId),
      completionRate: getCompletionRate(habitId),
      weeklyRate: getCompletionRate(habitId, days: 7),
      monthlyRate: getCompletionRate(habitId, days: 30),
      totalCompletions:
          completedEntries.fold(0, (sum, entry) => sum + entry.completionCount),
    );
  }

  // Get weekly grid data (7 days)
  List<HabitGridDay> getWeeklyGridData(String habitId, DateTime startDate) {
    final List<HabitGridDay> weekData = [];

    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final entry = getHabitEntryForDate(habitId, date);

      weekData.add(HabitGridDay(
        date: date,
        completed: entry?.completed ?? false,
        completionCount: entry?.completionCount ?? 0,
        intensity: entry?.intensity,
      ));
    }

    return weekData;
  }

  // Get monthly grid data
  List<HabitGridDay> getMonthlyGridData(String habitId, DateTime month) {
    final List<HabitGridDay> monthData = [];
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(month.year, month.month, day);
      final entry = getHabitEntryForDate(habitId, date);

      monthData.add(HabitGridDay(
        date: date,
        completed: entry?.completed ?? false,
        completionCount: entry?.completionCount ?? 0,
        intensity: entry?.intensity,
      ));
    }

    return monthData;
  }

  // Get GitHub-style yearly grid data
  List<List<HabitGridDay>> getYearlyGridData(String habitId, int year) {
    final List<List<HabitGridDay>> yearGrid = [];
    final startDate = DateTime(year, 1, 1);

    // Calculate weeks in year
    int totalDays = DateTime(year, 12, 31).difference(startDate).inDays + 1;
    int totalWeeks = (totalDays / 7).ceil();

    DateTime currentDate = startDate;

    for (int week = 0; week < totalWeeks; week++) {
      final List<HabitGridDay> weekData = [];

      for (int day = 0; day < 7; day++) {
        if (currentDate.year == year) {
          final entry = getHabitEntryForDate(habitId, currentDate);

          weekData.add(HabitGridDay(
            date: currentDate,
            completed: entry?.completed ?? false,
            completionCount: entry?.completionCount ?? 0,
            intensity: entry?.intensity,
          ));
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }

      if (weekData.isNotEmpty) {
        yearGrid.add(weekData);
      }
    }

    return yearGrid;
  }

  // Archive/unarchive habit
  Future<void> archiveHabit(String habitId, bool archive) async {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    final updatedHabit = habit.copyWith(isArchived: archive);
    await updateHabit(updatedHabit);
  }

  // Get active habits only
  List<HabitModel> getActiveHabits() {
    return _habits.where((h) => !h.isArchived && h.isActive).toList();
  }

  // Get archived habits
  List<HabitModel> getArchivedHabits() {
    return _habits.where((h) => h.isArchived).toList();
  }
}

// Helper classes for statistics
class HabitStats {
  final int totalDays;
  final int completedDays;
  final int currentStreak;
  final int longestStreak;
  final double completionRate;
  final double weeklyRate;
  final double monthlyRate;
  final int totalCompletions;

  HabitStats({
    required this.totalDays,
    required this.completedDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
    required this.weeklyRate,
    required this.monthlyRate,
    required this.totalCompletions,
  });
}

class HabitGridDay {
  final DateTime date;
  final bool completed;
  final int completionCount;
  final HabitIntensity? intensity;

  HabitGridDay({
    required this.date,
    required this.completed,
    required this.completionCount,
    this.intensity,
  });

  // Get intensity level for grid coloring (0-4)
  int get intensityLevel {
    if (!completed) return 0;
    if (intensity == null) return 1;

    switch (intensity!) {
      case HabitIntensity.low:
        return 1;
      case HabitIntensity.medium:
        return 2;
      case HabitIntensity.high:
        return 3;
    }
  }
}
