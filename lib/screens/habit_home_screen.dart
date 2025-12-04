import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/services/habit_service.dart';
import 'package:upnow/screens/add_habit_screen.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/utils/haptic_feedback_helper.dart';

class HabitHomeScreen extends StatefulWidget {
  const HabitHomeScreen({Key? key}) : super(key: key);

  @override
  State<HabitHomeScreen> createState() => _HabitHomeScreenState();
}

class _HabitHomeScreenState extends State<HabitHomeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final habitService = context.read<HabitService>();
      habitService.loadHabits();
      habitService.loadHabitEntries(); // Load habit entries from database
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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
      body: Stack(
        children: [
          Consumer<HabitService>(
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
          // Confetti widget
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // downward
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedbackHelper.trigger();
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
              HapticFeedbackHelper.trigger();
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
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        // Use a gradient that blends the habit color with a dark background
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
                habit.color.withOpacity(0.25), const Color(0xFF121212)),
            Color.alphaBlend(
                habit.color.withOpacity(0.1), const Color(0xFF000000)),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: habit.color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: habit.color.withOpacity(0.15),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative background glow - enhanced for more "pop"
            Positioned(
              right: -60,
              top: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: habit.color.withOpacity(0.2),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.name,
                              style: AppTheme.titleStyle.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            if (habit.description != null &&
                                habit.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                habit.description!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Check Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedbackHelper.trigger();
                          _toggleHabitCompletion(habit.id, today, habitService);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCompletedToday
                                ? habit.color
                                : Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCompletedToday
                                  ? habit.color
                                  : habit.color.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: isCompletedToday
                                ? [
                                    BoxShadow(
                                      color: habit.color.withOpacity(0.6),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Icon(
                            Icons.check,
                            color: isCompletedToday
                                ? Colors.white
                                : habit.color.withOpacity(0.5),
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Menu Button
                      Material(
                        color: Colors.transparent,
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (value) {
                            HapticFeedbackHelper.trigger();
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
                                  Text('Edit',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 12),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: _buildStatsRow(stats, habit.color),
                  ),

                  const SizedBox(height: 24),

                  // Contribution Grid
                  _buildContributionGrid(yearGrid, habit.color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(HabitStats stats, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          '${stats.completedDays}',
          'Completed',
          Icons.check_circle_outline,
          color,
        ),
        _buildStatItem(
          '${stats.currentStreak}',
          'Current Streak',
          Icons.local_fire_department,
          color,
        ),
        _buildStatItem(
          '${stats.longestStreak}',
          'Best Streak',
          Icons.emoji_events_outlined,
          color,
        ),
        _buildStatItem(
          '${stats.completionRate.toStringAsFixed(0)}%',
          'Success',
          Icons.trending_up,
          color,
        ),
      ],
    );
  }

  Widget _buildStatItem(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.captionStyle.copyWith(
              fontSize: 10,
              color: Colors.white.withOpacity(0.5),
            ),
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
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
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
      return Colors.white.withOpacity(0.05);
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

      // Trigger confetti animation! 🎉
      _confettiController.play();

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
              onPressed: () {
                HapticFeedbackHelper.trigger();
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.secondaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                HapticFeedbackHelper.trigger();
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
