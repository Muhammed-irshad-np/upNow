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
import 'package:upnow/screens/habit_detail_screen.dart';

class HabitHomeScreen extends StatefulWidget {
  const HabitHomeScreen({Key? key}) : super(key: key);

  @override
  State<HabitHomeScreen> createState() => _HabitHomeScreenState();
}

enum HabitGridLayout { weekly, monthly, yearly }

class _HabitHomeScreenState extends State<HabitHomeScreen> {
  late ConfettiController _confettiController;
  HabitGridLayout _selectedLayout = HabitGridLayout.yearly;

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SegmentedButton<HabitGridLayout>(
              segments: const [
                ButtonSegment<HabitGridLayout>(
                  value: HabitGridLayout.weekly,
                  label: Text('Weekly'),
                  icon: Icon(Icons.view_week),
                ),
                ButtonSegment<HabitGridLayout>(
                  value: HabitGridLayout.monthly,
                  label: Text('Monthly'),
                  icon: Icon(Icons.calendar_view_month),
                ),
                ButtonSegment<HabitGridLayout>(
                  value: HabitGridLayout.yearly,
                  label: Text('Yearly'),
                  icon: Icon(Icons.calendar_today),
                ),
              ],
              selected: {_selectedLayout},
              onSelectionChanged: (Set<HabitGridLayout> newSelection) {
                setState(() {
                  _selectedLayout = newSelection.first;
                });
                HapticFeedbackHelper.trigger();
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return AppTheme.primaryColor;
                    }
                    return Colors.transparent;
                  },
                ),
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.white;
                    }
                    return AppTheme.secondaryTextColor;
                  },
                ),
                side: MaterialStateProperty.all(
                  BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                ),
              ),
            ),
          ),
        ),
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
      child: GestureDetector(
        onTap: () {
          HapticFeedbackHelper.trigger();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HabitDetailScreen(habit: habit),
            ),
          ).then((_) {
            if (mounted) {
              // Refresh habits when returning from detail screen (in case of edits/deletes)
              context.read<HabitService>().loadHabits();
            }
          });
        },
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Habit Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: habit.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: habit.color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            () {
                              const Map<String, IconData> iconMap = {
                                '0xe3a7': Icons.fitness_center,
                                '0xe0bb': Icons.book,
                                '0xe798': Icons.water_drop,
                                '0xe3e4': Icons.bedtime,
                                '0xe4ba': Icons.self_improvement,
                                '0xe57a': Icons.restaurant,
                                '0xe566': Icons.directions_run,
                                '0xe4cd': Icons.psychology,
                                '0xe405': Icons.music_note,
                                '0xe3a9': Icons.brush,
                              };
                              return iconMap[habit.icon] ?? Icons.star;
                            }(),
                            color: habit.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Habit Name & Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                textAlign: TextAlign.left,
                                style: AppTheme.titleStyle.copyWith(
                                  fontSize: 18,
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

                        const SizedBox(width: 8),

                        // Check Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedbackHelper.trigger();
                            _toggleHabitCompletion(
                                habit.id, today, habitService);
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
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const SizedBox(height: 12),

                    // Layout based on selection
                    if (_selectedLayout == HabitGridLayout.monthly)
                      _buildMonthlyLayout(habit, habitService, stats)
                    else ...[
                      // Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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

                      const SizedBox(height: 12),

                      // Contribution Grid based on selected layout
                      _buildGridForLayout(habit, habitService),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyLayout(
      HabitModel habit, HabitService habitService, HabitStats stats) {
    final monthData = habitService.getMonthlyGridData(habit.id, DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthlyGrid(monthData, habit.color),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCompactStats(stats, habit.color),
        ),
      ],
    );
  }

  Widget _buildCompactStats(HabitStats stats, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              _buildStatItem(
                '${stats.completedDays}',
                'Done',
                Icons.check_circle_outline,
                color,
              ),
              _buildStatItem(
                '${stats.currentStreak}',
                'Streak',
                Icons.local_fire_department,
                color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                '${stats.longestStreak}',
                'Best',
                Icons.emoji_events_outlined,
                color,
              ),
              _buildStatItem(
                '${stats.completionRate.toStringAsFixed(0)}%',
                'Rate',
                Icons.trending_up,
                color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridForLayout(HabitModel habit, HabitService habitService) {
    switch (_selectedLayout) {
      case HabitGridLayout.weekly:
        final weekData = habitService.getWeeklyGridData(
            habit.id, DateTime.now().subtract(const Duration(days: 6)));
        return _buildWeeklyGrid(weekData, habit.color);
      case HabitGridLayout.monthly:
        // Should not be called in new layout, but keeping as fallback
        final monthData =
            habitService.getMonthlyGridData(habit.id, DateTime.now());
        return _buildMonthlyGrid(monthData, habit.color);
      case HabitGridLayout.yearly:
        final yearGrid =
            habitService.getYearlyGridData(habit.id, DateTime.now().year);
        return _buildContributionGrid(yearGrid, habit.color);
    }
  }

  Widget _buildWeeklyGrid(List<HabitGridDay> weekData, Color habitColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekData.map((day) {
          final isToday = day.date.day == DateTime.now().day &&
              day.date.month == DateTime.now().month &&
              day.date.year == DateTime.now().year;

          return Column(
            children: [
              Text(
                DateFormat('E').format(day.date)[0],
                style: TextStyle(
                  color: isToday
                      ? habitColor
                      : AppTheme.secondaryTextColor.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: day.completed
                      ? habitColor
                      : Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: habitColor.withOpacity(0.5), width: 1)
                      : null,
                ),
                child: day.completed
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyGrid(List<HabitGridDay> monthData, Color habitColor) {
    // Calculate width for 7 columns with 24px items and 4px spacing
    const double itemSize = 24.0;
    const double spacing = 4.0;
    const double gridWidth = (itemSize * 7) + (spacing * 6);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(DateTime.now()),
            style: TextStyle(
              color: AppTheme.secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: gridWidth,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: 1.0, // Square items
              ),
              itemCount: monthData.length,
              itemBuilder: (context, index) {
                final day = monthData[index];
                final isToday = day.date.day == DateTime.now().day &&
                    day.date.month == DateTime.now().month &&
                    day.date.year == DateTime.now().year;

                return Tooltip(
                  message:
                      '${DateFormat('MMM d').format(day.date)}\n${day.completed ? "Completed" : "Not completed"}',
                  child: Container(
                    decoration: BoxDecoration(
                      color: day.completed
                          ? habitColor
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: isToday
                          ? Border.all(
                              color: habitColor.withOpacity(0.5), width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${day.date.day}',
                        style: TextStyle(
                          color: day.completed
                              ? Colors.white
                              : AppTheme.secondaryTextColor.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(HabitStats stats, Color color) {
    return Row(
      // mainAxisAlignment: MainAxisAlignment.spaceAround,
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
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
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
      // padding: const EdgeInsets.all(8),
      // decoration: BoxDecoration(
      //   color: Colors.black.withOpacity(0.2),
      //   borderRadius: BorderRadius.circular(12),
      // ),
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month labels row
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12)),
              ),
              child: _buildMonthLabelsRow(yearGrid),
            ),
            // const SizedBox(height: 4),
            // Weekday labels and grid row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekday labels
                // Column(
                //   children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                //       .map((day) => SizedBox(
                //             height: 11,
                //             child: Center(
                //               child: Text(
                //                 day,
                //                 style: TextStyle(
                //                   color: AppTheme.secondaryTextColor,
                //                   fontSize: 10,
                //                   fontFamily: 'Poppins',
                //                 ),
                //               ),
                //             ),
                //           ))
                //       .toList(),
                // ),
                // const SizedBox(width: 4),
                // Grid without separate scrolling
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: yearGrid.asMap().entries.map((entry) {
                    final index = entry.key;
                    final week = entry.value;
                    return Column(
                      children: week.map((day) {
                        return Container(
                          width: 11,
                          height: 11,
                          margin: EdgeInsets.only(
                              left: index == 0 ? 0 : 3, bottom: 3),
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
    monthLabels.add(const SizedBox(width: 3));

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
              fontWeight: FontWeight.bold,
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
    double currentPosition = 0.0; // Offset for day labels (S M T W T F S)

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
        currentPosition += 14.0; // 1 week width
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
}
