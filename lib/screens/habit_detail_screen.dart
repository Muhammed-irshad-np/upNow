import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/services/habit_service.dart';
import 'package:upnow/services/habit_alarm_service.dart';
import 'package:upnow/widgets/habit_grid_widget.dart';
import 'package:upnow/providers/habit_detail_provider.dart';
import 'package:upnow/utils/app_theme.dart';

class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({
    Key? key,
    required this.habitId,
  }) : super(key: key);

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HabitDetailProvider(initialYear: DateTime.now().year),
      child: Consumer2<HabitService, HabitDetailProvider>(
        builder: (context, habitService, detailProvider, child) {
          final habit = habitService.habits.firstWhere(
            (h) => h.id == widget.habitId,
            orElse: () => throw Exception('Habit not found'),
          );

          final stats = habitService.getHabitStats(widget.habitId);

          return Scaffold(
            backgroundColor: AppTheme.darkBackground,
            appBar: AppBar(
              title: Text(habit.name),
              backgroundColor: habit.color,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) =>
                      _handleMenuAction(context, value, habit),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit Habit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'alarm',
                      child: ListTile(
                        leading: Icon(
                            habit.hasAlarm ? Icons.alarm_off : Icons.alarm),
                        title: Text(
                            habit.hasAlarm ? 'Turn Off Alarm' : 'Set Alarm'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: ListTile(
                        leading: Icon(Icons.archive),
                        title: Text('Archive Habit'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete Habit',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHabitHeader(habit),
                  const SizedBox(height: 24),
                  _buildStreakSection(stats, habit),
                  const SizedBox(height: 24),
                  _buildStatsSection(stats),
                  const SizedBox(height: 24),
                  _buildYearSelector(detailProvider),
                  const SizedBox(height: 16),
                  _buildGridSection(habit, detailProvider),
                  const SizedBox(height: 24),
                  _buildQuickActions(context, habitService, habit),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHabitHeader(HabitModel habit) {
    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: AppTheme.titleStyle.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (habit.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          habit.description!,
                          style: AppTheme.bodyStyle.copyWith(
                            color: AppTheme.secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getFrequencyIcon(habit.frequency),
                  color: AppTheme.secondaryTextColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _getFrequencyText(habit.frequency),
                  style: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                if (habit.hasAlarm) ...[
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.alarm,
                    color: AppTheme.secondaryTextColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    habit.targetTime != null
                        ? '${habit.targetTime!.hour.toString().padLeft(2, '0')}:${habit.targetTime!.minute.toString().padLeft(2, '0')}'
                        : 'Set',
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakSection(HabitStats stats, HabitModel habit) {
    return HabitStreakWidget(
      habitId: widget.habitId,
      showDetails: true,
    );
  }

  Widget _buildStatsSection(HabitStats stats) {
    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: AppTheme.titleStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Days',
                    '${stats.totalDays}',
                    Icons.calendar_today,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    '${stats.completedDays}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Success Rate',
                    '${stats.completionRate.toInt()}%',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Best Streak',
                    '${stats.longestStreak} days',
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
            style: AppTheme.captionStyle.copyWith(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector(HabitDetailProvider detailProvider) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              'Year: ',
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: detailProvider.selectedYear,
              dropdownColor: AppTheme.darkSurface,
              style: AppTheme.bodyStyle,
              onChanged: (year) {
                if (year != null) {
                  detailProvider.setSelectedYear(year);
                }
              },
              items: years.map((year) {
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text('$year'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSection(
      HabitModel habit, HabitDetailProvider detailProvider) {
    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Activity Overview',
                  style: AppTheme.titleStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.info_outline,
                      color: AppTheme.secondaryTextColor),
                  onPressed: () => _showGridInfo(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            HabitGridWidget(
              habitId: widget.habitId,
              year: detailProvider.selectedYear,
              showHeader: false,
              onDayTapped: (date) => _toggleHabitCompletion(date),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context, HabitService habitService, HabitModel habit) {
    final today = DateTime.now();
    final todayEntry = habitService.getHabitEntryForDate(widget.habitId, today);
    final isCompletedToday = todayEntry?.completed == true;

    return Card(
      color: AppTheme.darkSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: AppTheme.titleStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleHabitCompletion(today),
                    icon: Icon(isCompletedToday ? Icons.undo : Icons.check),
                    label:
                        Text(isCompletedToday ? 'Undo Today' : 'Mark Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompletedToday
                          ? AppTheme.secondaryTextColor
                          : habit.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addNote(context, habitService, today),
                    icon: const Icon(Icons.note_add),
                    label: const Text('Add Note'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: habit.color,
                      side: BorderSide(color: habit.color),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFrequencyIcon(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return Icons.today;
      case HabitFrequency.weekly:
        return Icons.calendar_view_week;
      case HabitFrequency.monthly:
        return Icons.calendar_month;
      case HabitFrequency.custom:
        return Icons.tune;
    }
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

  void _toggleHabitCompletion(DateTime date) {
    final habitService = context.read<HabitService>();
    final entry = habitService.getHabitEntryForDate(widget.habitId, date);

    if (entry?.completed == true) {
      habitService.markHabitUncompleted(widget.habitId, date);
    } else {
      habitService.markHabitCompleted(widget.habitId, date);
    }
  }

  void _showGridInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activity Grid'),
        content: const Text(
          'This grid shows your habit completion for the selected year. '
          'Each square represents a day:\n\n'
          '• Gray: Not completed\n'
          '• Light color: Completed (low intensity)\n'
          '• Medium color: Completed (medium intensity)\n'
          '• Dark color: Completed (high intensity)\n\n'
          'Tap any day to toggle completion status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _addNote(
      BuildContext context, HabitService habitService, DateTime date) {
    final controller = TextEditingController();
    final entry = habitService.getHabitEntryForDate(widget.habitId, date);

    if (entry?.notes != null) {
      controller.text = entry!.notes!;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Note for ${date.day}/${date.month}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Add your thoughts about today...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (entry != null) {
                await habitService.markHabitCompleted(
                  widget.habitId,
                  date,
                  notes: controller.text.trim(),
                );
              } else {
                await habitService.markHabitCompleted(
                  widget.habitId,
                  date,
                  notes: controller.text.trim(),
                );
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(
      BuildContext context, String action, HabitModel habit) {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit functionality coming soon!')),
        );
        break;
      case 'alarm':
        _toggleAlarm(context, habit);
        break;
      case 'archive':
        _archiveHabit(context, habit);
        break;
      case 'delete':
        _deleteHabit(context, habit);
        break;
    }
  }

  void _toggleAlarm(BuildContext context, HabitModel habit) {
    if (habit.hasAlarm) {
      // Disable alarm
      context.read<HabitService>().updateHabit(habit.copyWith(hasAlarm: false));
      HabitAlarmService.cancelHabitAlarm(habit.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm disabled')),
      );
    } else {
      // Enable alarm - show time picker
      showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      ).then((time) {
        if (time != null) {
          final now = DateTime.now();
          final targetTime =
              DateTime(now.year, now.month, now.day, time.hour, time.minute);

          final updatedHabit = habit.copyWith(
            hasAlarm: true,
            targetTime: targetTime,
          );

          context.read<HabitService>().updateHabit(updatedHabit);
          HabitAlarmService.scheduleHabitAlarm(updatedHabit);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Alarm set for ${time.format(context)}')),
          );
        }
      });
    }
  }

  void _archiveHabit(BuildContext context, HabitModel habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Habit'),
        content: Text('Are you sure you want to archive "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<HabitService>().archiveHabit(habit.id, true);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to habits list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Habit archived')),
                );
              }
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _deleteHabit(BuildContext context, HabitModel habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text(
          'Are you sure you want to delete "${habit.name}"? '
          'This action cannot be undone and will delete all data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<HabitService>().deleteHabit(habit.id);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to habits list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Habit deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
