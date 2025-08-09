import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/services/habit_service.dart';
import 'package:upnow/widgets/habit_grid_widget.dart';
import 'package:upnow/providers/habit_analytics_provider.dart';

class HabitAnalyticsScreen extends StatefulWidget {
  const HabitAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<HabitAnalyticsScreen> createState() => _HabitAnalyticsScreenState();
}

class _HabitAnalyticsScreenState extends State<HabitAnalyticsScreen> {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HabitAnalyticsProvider(),
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Habit Analytics'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<HabitService, HabitAnalyticsProvider>(
        builder: (context, habitService, analytics, child) {
          final habits = habitService.getActiveHabits();
          
          if (habits.isEmpty) {
            return _buildEmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallStats(habitService, habits),
                const SizedBox(height: 24),
                _buildHabitSelector(analytics, habits),
                const SizedBox(height: 24),
                _buildPeriodSelector(analytics),
                const SizedBox(height: 24),
                if (analytics.selectedHabit != null) ...[
                  _buildHabitAnalytics(habitService, analytics.selectedHabit!),
                  const SizedBox(height: 24),
                  _buildProgressChart(habitService, analytics.selectedHabit!, analytics.selectedPeriod),
                  const SizedBox(height: 24),
                  _buildStreakAnalysis(habitService, analytics.selectedHabit!),
                ] else
                  _buildAllHabitsOverview(habitService, habits),
              ],
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Habits to Analyze',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create some habits first to see analytics',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats(HabitService habitService, List<HabitModel> habits) {
    int totalStreaks = 0;
    double avgCompletionRate = 0;
    int totalCompletions = 0;
    // int activeDays = 0; // removed (unused)

    for (final habit in habits) {
      final stats = habitService.getHabitStats(habit.id);
      totalStreaks += stats.currentStreak;
      avgCompletionRate += stats.completionRate;
      totalCompletions += stats.totalCompletions;
      // previously tracked activeDays; removed as unused
    }

    if (habits.isNotEmpty) {
      avgCompletionRate /= habits.length;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverallStatCard(
                    'Active Habits',
                    '${habits.length}',
                    Icons.track_changes,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOverallStatCard(
                    'Total Streaks',
                    '$totalStreaks',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildOverallStatCard(
                    'Avg Success',
                    '${avgCompletionRate.toInt()}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildOverallStatCard(
                    'Completions',
                    '$totalCompletions',
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHabitSelector(HabitAnalyticsProvider analytics, List<HabitModel> habits) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analyze Specific Habit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HabitModel?>(
              value: analytics.selectedHabit,
              decoration: const InputDecoration(
                labelText: 'Select Habit',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<HabitModel?>(
                  value: null,
                  child: Text('All Habits Overview'),
                ),
                ...habits.map((habit) => DropdownMenuItem<HabitModel?>(
                  value: habit,
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: habit.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(habit.name)),
                    ],
                  ),
                )),
              ],
              onChanged: (habit) => analytics.setSelectedHabit(habit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(HabitAnalyticsProvider analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildPeriodChip(analytics, 'Week', 'week'),
                const SizedBox(width: 8),
                _buildPeriodChip(analytics, 'Month', 'month'),
                const SizedBox(width: 8),
                _buildPeriodChip(analytics, 'Year', 'year'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(HabitAnalyticsProvider analytics, String label, String value) {
    final isSelected = analytics.selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          analytics.setSelectedPeriod(value);
        }
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildHabitAnalytics(HabitService habitService, HabitModel habit) {
    final stats = habitService.getHabitStats(habit.id);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: habit.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    habit.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            HabitStreakWidget(habitId: habit.id, showDetails: true),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'This Week',
                    '${stats.weeklyRate.toInt()}%',
                    Icons.calendar_view_week,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    'This Month',
                    '${stats.monthlyRate.toInt()}%',
                    Icons.calendar_month,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    'All Time',
                    '${stats.completionRate.toInt()}%',
                    Icons.all_inclusive,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(HabitService habitService, HabitModel habit, String selectedPeriod) {
    final entries = habitService.getHabitEntries(habit.id);
    final now = DateTime.now();
    final days = selectedPeriod == 'week' ? 7 : (selectedPeriod == 'month' ? 30 : 365);
    
    final chartData = <FlSpot>[];
    double cumulativeRate = 0;
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayEntries = entries.where((e) => 
        e.date.year == date.year && 
        e.date.month == date.month && 
        e.date.day == date.day
      ).toList();
      
      final completed = dayEntries.isNotEmpty && dayEntries.first.completed;
      cumulativeRate += completed ? 1 : 0;
      
      final rate = cumulativeRate / (days - i) * 100;
      chartData.add(FlSpot((days - 1 - i).toDouble(), rate));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Trend (${selectedPeriod.toUpperCase()})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final dayIndex = value.toInt();
                          final date = now.subtract(Duration(days: days - 1 - dayIndex));
                          return Text(DateFormat('M/d').format(date));
                        },
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color: habit.color,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: habit.color.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakAnalysis(HabitService habitService, HabitModel habit) {
    final entries = habitService.getHabitEntries(habit.id);
    final stats = habitService.getHabitStats(habit.id);
    
    // Calculate streak distribution
    final streaks = <int>[];
    int currentStreak = 0;
    
    entries.sort((a, b) => a.date.compareTo(b.date));
    DateTime? lastDate;
    
    for (final entry in entries) {
      if (entry.completed) {
        if (lastDate == null || entry.date.difference(lastDate).inDays == 1) {
          currentStreak++;
        } else {
          if (currentStreak > 0) {
            streaks.add(currentStreak);
          }
          currentStreak = 1;
        }
        lastDate = entry.date;
      } else {
        if (currentStreak > 0) {
          streaks.add(currentStreak);
        }
        currentStreak = 0;
        lastDate = null;
      }
    }
    
    if (currentStreak > 0) {
      streaks.add(currentStreak);
    }

    final avgStreak = streaks.isEmpty ? 0.0 : streaks.reduce((a, b) => a + b) / streaks.length;
    final streakCount = streaks.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Streak Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStreakStat(
                    'Current',
                    '${stats.currentStreak} days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStreakStat(
                    'Longest',
                    '${stats.longestStreak} days',
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStreakStat(
                    'Average',
                    '${avgStreak.toInt()} days',
                    Icons.timeline,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStreakStat(
                    'Total Streaks',
                    '$streakCount',
                    Icons.repeat,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllHabitsOverview(HabitService habitService, List<HabitModel> habits) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Habits Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...habits.map((habit) {
              final stats = habitService.getHabitStats(habit.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: habit.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        habit.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${stats.currentStreak} days',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${stats.completionRate.toInt()}%',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}