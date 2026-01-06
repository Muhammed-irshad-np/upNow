import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  // Check if a specific date is a scheduled day for the habit
  bool isScheduledDay(HabitModel habit, DateTime date) {
    if (habit.frequency == HabitFrequency.daily) {
      return true; // Daily habits are scheduled every day
    } else if (habit.frequency == HabitFrequency.custom) {
      // weekday is 1 for Monday, 7 for Sunday
      final isScheduled = habit.daysOfWeek.contains(date.weekday);
      // Debug log for custom habits (limit excessive logging)
      // Log for the first week of Jan 2026 to see the pattern
      if (date.year == 2026 && date.month == 1 && date.day <= 7) {
        print(
            'DEBUG: checking isScheduled for ${habit.name} (${habit.id}) on ${date.toString().split(' ')[0]} (Weekday ${date.weekday}). Frequency: ${habit.frequency}, Days: ${habit.daysOfWeek}. Result: $isScheduled');
      }
      return isScheduled;
    }
    return true;
  }

  // Get current streak for a habit
  int getCurrentStreak(String habitId) {
    final habit = _habits.firstWhere((h) => h.id == habitId,
        orElse: () => HabitModel(name: 'Unknown'));
    if (habit.name == 'Unknown') return 0;

    final entries = getHabitEntries(habitId);
    // Create a set of completed dates for faster lookup
    final completedDates =
        entries.where((e) => e.completed).map((e) => e.dateKey).toSet();

    int streak = 0;
    final today = DateTime.now();
    bool streakBroken = false;

    // Check up to 365 days back
    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));

      // Calculate date key manually to match the format in HabitEntry
      final dateKey =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

      final isCompleted = completedDates.contains(dateKey);
      final isScheduled = isScheduledDay(habit, checkDate);

      // If it's today and not completed yet, don't break streak, just continue
      if (i == 0 && !isCompleted) {
        if (isScheduled && DateTime.now().hour < 24) {
          // It's today, scheduled, but not done yet.
          // Technically streak includes today if done, but looking back
          // we shouldn't fail immediately if today isn't done.
          continue;
        }
      }

      if (isScheduled) {
        if (isCompleted) {
          streak++;
        } else {
          // If today (i=0) was handled above, this triggers for past days
          // If we are here, it's a scheduled day that was NOT completed.
          // However, if we skipped today (i=0) because it's not over yet,
          // we need to be careful.

          // Simplified approach:
          // If it's a past scheduled day and not done -> break.
          // If it's today, scheduled, not done -> don't increment, don't break (allow user to finish today).
          if (i == 0) {
            // Today not done, handled by continue above usually, but if we are here
            // it means we are strictly checking.
            // Let's rely on the logic: Current streak usually counts completed days.
            // If today is not done, does it break the streak from yesterday?
            // No, so we just stop counting.
            break;
          } else {
            streakBroken = true;
          }
        }
      } else {
        // Not scheduled day
        // Check if user did it anyway (optional: bonus? ignore?)
        // For standard "Current Streak" usually we ignore non-scheduled days
        // unless they contribute.
        // If user did it on off day, it adds to streak!
        if (isCompleted) {
          streak++;
        }
        // If not completed on off day, it does NOT break streak.
      }

      if (streakBroken) break;
    }

    return streak;
  }

  // Get longest streak for a habit
  int getLongestStreak(String habitId) {
    final habit = _habits.firstWhere((h) => h.id == habitId,
        orElse: () => HabitModel(name: 'Unknown'));
    if (habit.name == 'Unknown') return 0;

    final entries = getHabitEntries(habitId);
    entries.sort((a, b) => a.date.compareTo(b.date));

    // We need to iterate through all days from first entry to now (or just iterate entries?)
    // Iterating entries is insufficient because we need to know about "missed" scheduled days
    // to break the streak.

    if (entries.isEmpty) return 0;

    // Find the range of dates to check
    // Ideally we start from the habit creation date or the first entry date
    DateTime startDate = entries.first.date;
    if (habit.createdAt.isBefore(startDate)) {
      startDate = habit.createdAt;
    }

    final endDate = DateTime.now();
    final completedDates =
        entries.where((e) => e.completed).map((e) => e.dateKey).toSet();

    int maxStreak = 0;
    int currentStreak = 0;

    // Iterate day by day
    for (DateTime date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final isCompleted = completedDates.contains(dateKey);
      final isScheduled = isScheduledDay(habit, date);

      if (isScheduled) {
        if (isCompleted) {
          currentStreak++;
        } else {
          // Missed a scheduled day -> reset
          // But check if it is today? If today and not done, strictly calling "longest streak"
          // usually implies finished streaks or current running.
          // If today is not done, it breaks 'current' increment, resetting to 0.
          // However, if today is the day we are checking, we might exclude it if not done?
          // Let's just treat it as a break for simplicity in historical calculation.
          if (!DateUtils.isSameDay(date, DateTime.now())) {
            currentStreak = 0;
          }
        }
      } else {
        // Not scheduled
        if (isCompleted) {
          currentStreak++; // Bonus day!
        }
        // Else ignore
      }

      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }
    }

    return maxStreak;
  }

  // Get completion rate for a habit in percentage
  double getCompletionRate(String habitId, {int? days}) {
    final entries = getHabitEntries(habitId);

    // Calculate based on days since creation or specific duration
    int totalDays;

    if (days != null) {
      totalDays = days;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final recentEntries =
          entries.where((e) => e.date.isAfter(cutoffDate)).toList();

      if (recentEntries.isEmpty && totalDays > 0) return 0.0;

      final completedCount = recentEntries.where((e) => e.completed).length;
      return (completedCount / totalDays) * 100;
    } else {
      // For all-time stats, use days since creation
      final habit = _habits.firstWhere((h) => h.id == habitId,
          orElse: () => HabitModel(name: 'Unknown'));
      if (habit.name == 'Unknown') return 0.0;

      totalDays = DateTime.now().difference(habit.createdAt).inDays + 1;
      if (totalDays < 1) totalDays = 1;

      final completedCount = entries.where((e) => e.completed).length;
      return (completedCount / totalDays) * 100;
    }
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
    final habit = _habits.firstWhere((h) => h.id == habitId,
        orElse: () => HabitModel(name: 'Unknown'));

    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final entry = getHabitEntryForDate(habitId, date);

      weekData.add(HabitGridDay(
        date: date,
        completed: entry?.completed ?? false,
        completionCount: entry?.completionCount ?? 0,
        intensity: entry?.intensity,
        isScheduled:
            habit.name != 'Unknown' ? isScheduledDay(habit, date) : true,
      ));
    }

    return weekData;
  }

  // Get monthly grid data
  List<HabitGridDay> getMonthlyGridData(String habitId, DateTime month) {
    final List<HabitGridDay> monthData = [];
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final habit = _habits.firstWhere((h) => h.id == habitId,
        orElse: () => HabitModel(name: 'Unknown'));

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(month.year, month.month, day);
      final entry = getHabitEntryForDate(habitId, date);

      monthData.add(HabitGridDay(
        date: date,
        completed: entry?.completed ?? false,
        completionCount: entry?.completionCount ?? 0,
        intensity: entry?.intensity,
        isScheduled:
            habit.name != 'Unknown' ? isScheduledDay(habit, date) : true,
      ));
    }

    return monthData;
  }

  // Get GitHub-style yearly grid data
  List<List<HabitGridDay>> getYearlyGridData(String habitId, int year) {
    final List<List<HabitGridDay>> yearGrid = [];
    final startDate = DateTime(year, 1, 1);
    final habit = _habits.firstWhere((h) => h.id == habitId,
        orElse: () => HabitModel(name: 'Unknown'));

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
            isScheduled: habit.name != 'Unknown'
                ? isScheduledDay(habit, currentDate)
                : true,
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
  final bool isScheduled;

  HabitGridDay({
    required this.date,
    required this.completed,
    required this.completionCount,
    this.intensity,
    this.isScheduled = true,
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
