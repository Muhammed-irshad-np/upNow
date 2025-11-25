import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/services/habit_service.dart';
import 'package:upnow/screens/add_habit_screen.dart';
import 'package:upnow/utils/app_theme.dart';

class HabitHomeScreen extends StatefulWidget {
  const HabitHomeScreen({Key? key}) : super(key: key);

  @override
  State<HabitHomeScreen> createState() => _HabitHomeScreenState();
}

class _HabitHomeScreenState extends State<HabitHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final habitService = context.read<HabitService>();
      habitService.loadHabits();
      habitService.loadHabitEntries(); // Load habit entries from database
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Habits',
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<HabitService>(
        builder: (context, habitService, child) {
          final activeHabits = habitService.getActiveHabits();

          if (activeHabits.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await habitService.loadHabits();
              await habitService.loadHabitEntries();
            },
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeHabits.length,
              itemBuilder: (context, index) {
                final habit = activeHabits[index];
                return _buildHabitCard(habit, habitService);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddHabitScreen()),
          ).then((_) {
            if (mounted) {
              context.read<HabitService>().loadHabits();
            }
          });
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Habit'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes,
            size: 80,
            color: AppTheme.secondaryTextColor,
          ),
          const SizedBox(height: 24),
          Text(
            'No Habits Yet',
            style: AppTheme.titleStyle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your habits!\nCreate your first habit to begin.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddHabitScreen()),
              ).then((_) {
                if (mounted) {
                  context.read<HabitService>().loadHabits();
                }
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Habit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(HabitModel habit, HabitService habitService) {
    final stats = habitService.getHabitStats(habit.id);
    final yearGrid =
        habitService.getYearlyGridData(habit.id, DateTime.now().year);
    final today = DateTime.now();
    final todayEntry = habitService.getHabitEntryForDate(habit.id, today);
    final isCompletedToday = todayEntry?.completed == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: habit.color,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: habit.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.circle,
                    color: habit.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: AppTheme.titleStyle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${stats.currentStreak} day streak',
                        style: AppTheme.captionStyle.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      _toggleHabitCompletion(habit.id, today, habitService),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCompletedToday
                          ? habit.color.withOpacity(0.2)
                          : AppTheme.secondaryTextColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompletedToday
                            ? habit.color
                            : AppTheme.secondaryTextColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      color: isCompletedToday
                          ? habit.color
                          : AppTheme.secondaryTextColor.withOpacity(0.5),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppTheme.secondaryTextColor,
                  ),
                  color: AppTheme.darkCardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editHabit(habit);
                    } else if (value == 'delete') {
                      _deleteHabit(habit, habitService);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit,
                              color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Edit',
                            style: TextStyle(color: AppTheme.textColor),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppTheme.textColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatsRow(stats),
            const SizedBox(height: 16),
            _buildContributionGrid(yearGrid, habit.color),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(HabitStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          '${stats.completedDays}',
          'Completed',
          Icons.check_circle_outline,
        ),
        _buildStatItem(
          '${stats.currentStreak}',
          'Current Streak',
          Icons.local_fire_department,
        ),
        _buildStatItem(
          '${stats.longestStreak}',
          'Best Streak',
          Icons.emoji_events_outlined,
        ),
        _buildStatItem(
          '${stats.completionRate.toStringAsFixed(0)}%',
          'Success',
          Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.captionStyle.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionGrid(
      List<List<HabitGridDay>> yearGrid, Color habitColor) {
    if (yearGrid.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No data yet',
            style: AppTheme.captionStyle,
          ),
        ),
      );
    }

    // Create ScrollController and calculate current month position
    final ScrollController scrollController = ScrollController();
    final currentMonth = DateTime.now().month;

    // Calculate scroll position for current month
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final scrollPosition =
            _calculateScrollPositionForMonth(yearGrid, currentMonth);
        scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Month labels row
            _buildMonthLabelsRow(yearGrid),
            const SizedBox(height: 4),
            // Weekday labels and grid row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekday labels
                Column(
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                      .map((day) => SizedBox(
                            height: 11,
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: AppTheme.secondaryTextColor,
                                  fontSize: 10,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(width: 4),
                // Grid without separate scrolling
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: yearGrid.map((week) {
                    return Column(
                      children: week.map((day) {
                        return Container(
                          width: 11,
                          height: 11,
                          margin: const EdgeInsets.only(left: 3, bottom: 3),
                          decoration: BoxDecoration(
                            color: _getDayColor(day, habitColor),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Tooltip(
                            message:
                                '${DateFormat('MMM d').format(day.date)}\n${day.completed ? "Completed" : "Not completed"}',
                            child: const SizedBox.expand(),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthLabelsRow(List<List<HabitGridDay>> yearGrid) {
    if (yearGrid.isEmpty) return const SizedBox.shrink();

    // Track which month each week belongs to and find first occurrence
    final Map<int, int> monthFirstWeekIndex = {};

    for (int weekIndex = 0; weekIndex < yearGrid.length; weekIndex++) {
      final week = yearGrid[weekIndex];
      if (week.isNotEmpty) {
        final month = week.first.date.month;
        if (!monthFirstWeekIndex.containsKey(month)) {
          monthFirstWeekIndex[month] = weekIndex;
        }
      }
    }

    if (monthFirstWeekIndex.isEmpty) return const SizedBox.shrink();

    final currentYear = DateTime.now().year;
    final monthLabels = <Widget>[];

    // Add offset for day labels (S M T W T F S)
    monthLabels.add(const SizedBox(width: 20));

    // Sort months by their order
    final sortedMonths = monthFirstWeekIndex.keys.toList()..sort();

    // Each week column is 14px wide (11px square + 3px margin)
    const double weekWidth = 14.0;

    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final weekIndex = monthFirstWeekIndex[month]!;
      final monthName =
          DateFormat('MMM').format(DateTime(currentYear, month, 1));

      // Calculate how many weeks until next month (or end of grid)
      int weeksInThisMonth;
      if (i < sortedMonths.length - 1) {
        final nextMonth = sortedMonths[i + 1];
        final nextWeekIndex = monthFirstWeekIndex[nextMonth]!;
        weeksInThisMonth = nextWeekIndex - weekIndex;
      } else {
        weeksInThisMonth = yearGrid.length - weekIndex;
      }

      monthLabels.add(
        Container(
          width: weeksInThisMonth * weekWidth,
          child: Text(
            monthName,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.primaryTextColor,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.left,
          ),
        ),
      );
    }

    return Row(
      children: monthLabels,
    );
  }

  Color _getDayColor(HabitGridDay day, Color habitColor) {
    if (!day.completed) {
      return AppTheme.darkSurfaceLight;
    }

    // Simple completed/not completed - completed days show in habit color
    return habitColor;
  }

  double _calculateScrollPositionForMonth(
      List<List<HabitGridDay>> yearGrid, int targetMonth) {
    // Each grid square is 11px + 3px margin = 14px
    // Each week has 7 days = 7 * 14px = 98px
    double currentPosition = 20.0; // Offset for day labels (S M T W T F S)

    for (int weekIndex = 0; weekIndex < yearGrid.length; weekIndex++) {
      final week = yearGrid[weekIndex];
      if (week.isNotEmpty) {
        final firstDay = week.first;
        final month = firstDay.date.month;

        // If we found the target month, return the position
        if (month == targetMonth) {
          // Center the current month in the view
          return currentPosition - 100; // Offset to center the month
        }

        // Move to next week position
        currentPosition += 98.0; // 7 days * 14px per day
      }
    }

    // If target month not found, scroll to end
    return currentPosition;
  }

  void _toggleHabitCompletion(
      String habitId, DateTime date, HabitService habitService) {
    final entry = habitService.getHabitEntryForDate(habitId, date);

    if (entry?.completed == true) {
      // Mark as uncompleted
      habitService.markHabitUncompleted(habitId, date);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Habit marked as incomplete'),
          backgroundColor: AppTheme.secondaryTextColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Mark as completed
      habitService.markHabitCompleted(habitId, date);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Great job! Habit completed! 🎉'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _editHabit(HabitModel habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddHabitScreen(habit: habit),
      ),
    ).then((_) {
      if (mounted) {
        context.read<HabitService>().loadHabits();
      }
    });
  }

  void _deleteHabit(HabitModel habit, HabitService habitService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Habit',
            style: TextStyle(color: AppTheme.textColor),
          ),
          content: Text(
            'Are you sure you want to delete "${habit.name}"? This action cannot be undone.',
            style: TextStyle(color: AppTheme.secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await habitService.deleteHabit(habit.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${habit.name}" deleted'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(
                'Delete',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
