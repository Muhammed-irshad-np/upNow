import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/services/habit_service.dart';
import 'package:upnow/widgets/habit_grid_widget.dart';
import 'package:upnow/screens/add_habit_screen.dart';
import 'package:upnow/screens/habit_detail_screen.dart';
import 'package:upnow/screens/habit_analytics_screen.dart';
import 'package:upnow/providers/habit_view_provider.dart';

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
      context.read<HabitService>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HabitViewProvider(),
      child: Consumer2<HabitService, HabitViewProvider>(
        builder: (context, habitService, habitViewProvider, child) {
          final activeHabits = habitService.getActiveHabits();
          
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(context, activeHabits.length),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTodayOverview(context, habitService, activeHabits),
                          const SizedBox(height: 24),
                          _buildViewToggle(habitViewProvider),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (activeHabits.isEmpty)
                    _buildEmptyState(context)
                  else
                    _buildHabitsList(context, habitService, activeHabits, habitViewProvider),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100), // Bottom padding
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _navigateToAddHabit(context),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, int habitCount) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
        expandedTitleScale: 1.4,
        title: const Text(
          'Habits',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$habitCount Active Habits',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.analytics, color: Colors.white),
          onPressed: () => _showAnalytics(context),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'archive',
              child: ListTile(
                leading: Icon(Icons.archive),
                title: Text('Archived Habits'),
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Data'),
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayOverview(BuildContext context, HabitService habitService, List<HabitModel> habits) {
    final today = DateTime.now();
    int completedToday = 0;
    
    for (final habit in habits) {
      final entry = habitService.getHabitEntryForDate(habit.id, today);
      if (entry?.completed == true) {
        completedToday++;
      }
    }

    final completionRate = habits.isNotEmpty ? (completedToday / habits.length) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.today,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Today\'s Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTodayMetric(
                  'Completed',
                  '$completedToday/${habits.length}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildTodayMetric(
                  'Success Rate',
                  '${completionRate.toInt()}%',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildTodayMetric(
                  'Streak Total',
                  '${_getTotalStreaks(habitService, habits)}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  int _getTotalStreaks(HabitService habitService, List<HabitModel> habits) {
    return habits.fold(0, (total, habit) {
      return total + habitService.getCurrentStreak(habit.id);
    });
  }

  Widget _buildViewToggle(HabitViewProvider habitViewProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            'Week',
            habitViewProvider.showWeeklyView,
            () => habitViewProvider.setShowWeeklyView(true),
          ),
          _buildToggleButton(
            'Year',
            !habitViewProvider.showWeeklyView,
            () => habitViewProvider.setShowWeeklyView(false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.track_changes,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'No Habits Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start building better habits today!\nTap the + button to create your first habit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _navigateToAddHabit(context),
                icon: const Icon(Icons.add),
                label: const Text('Create First Habit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitsList(BuildContext context, HabitService habitService, List<HabitModel> habits, HabitViewProvider habitViewProvider) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final habit = habits[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildHabitCard(context, habitService, habit, habitViewProvider),
          );
        },
        childCount: habits.length,
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, HabitService habitService, HabitModel habit, HabitViewProvider habitViewProvider) {
    final stats = habitService.getHabitStats(habit.id);
    final today = DateTime.now();
    final todayEntry = habitService.getHabitEntryForDate(habit.id, today);
    final isCompletedToday = todayEntry?.completed == true;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToHabitDetail(context, habit.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 40,
                    decoration: BoxDecoration(
                      color: habit.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                habit.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (habit.hasAlarm)
                              Icon(
                                Icons.alarm,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                          ],
                        ),
                        if (habit.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            habit.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildQuickActionButton(
                    context,
                    habitService,
                    habit,
                    isCompletedToday,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatChip(
                    '${stats.currentStreak} day streak',
                    Icons.local_fire_department,
                    stats.currentStreak > 0 ? Colors.orange : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    '${stats.completionRate.toInt()}%',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                  const Spacer(),
                  Text(
                    _getFrequencyText(habit.frequency),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (habitViewProvider.showWeeklyView)
                HabitWeeklyGridWidget(
                  habitId: habit.id,
                  startDate: _getWeekStart(today),
                  onDayTapped: (date) => _toggleHabitCompletion(habitService, habit.id, date),
                )
              else
                HabitGridWidget(
                  habitId: habit.id,
                  year: today.year,
                  showHeader: false,
                  cellSize: 10,
                  cellSpacing: 1,
                  onDayTapped: (date) => _toggleHabitCompletion(habitService, habit.id, date),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    HabitService habitService,
    HabitModel habit,
    bool isCompleted,
  ) {
    return Material(
      color: isCompleted ? Colors.green : habit.color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _toggleHabitCompletion(habitService, habit.id, DateTime.now()),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          child: Icon(
            isCompleted ? Icons.check : Icons.add,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  String _getFrequencyText(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.monthly:
        return 'Monthly';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }

  void _toggleHabitCompletion(HabitService habitService, String habitId, DateTime date) {
    final entry = habitService.getHabitEntryForDate(habitId, date);
    
    if (entry?.completed == true) {
      habitService.markHabitUncompleted(habitId, date);
    } else {
      habitService.markHabitCompleted(habitId, date);
    }
  }

  void _navigateToAddHabit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddHabitScreen()),
    );
  }

  void _navigateToHabitDetail(BuildContext context, String habitId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailScreen(habitId: habitId),
      ),
    );
  }

  void _showAnalytics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HabitAnalyticsScreen()),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'archive':
        // TODO: Navigate to archived habits
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archived habits coming soon!')),
        );
        break;
      case 'export':
        // TODO: Export data functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export functionality coming soon!')),
        );
        break;
      case 'settings':
        // TODO: Navigate to settings
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings coming soon!')),
        );
        break;
    }
  }
}