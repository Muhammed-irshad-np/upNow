import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/services/habit_service.dart';

class HabitGridWidget extends StatefulWidget {
  final String habitId;
  final int year;
  final bool showHeader;
  final double cellSize;
  final double cellSpacing;
  final Function(DateTime)? onDayTapped;

  const HabitGridWidget({
    Key? key,
    required this.habitId,
    required this.year,
    this.showHeader = true,
    this.cellSize = 12.0,
    this.cellSpacing = 2.0,
    this.onDayTapped,
  }) : super(key: key);

  @override
  State<HabitGridWidget> createState() => _HabitGridWidgetState();
}

class _HabitGridWidgetState extends State<HabitGridWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<HabitService>(
      builder: (context, habitService, child) {
        final yearData = habitService.getYearlyGridData(widget.habitId, widget.year);
        final habit = habitService.habits.firstWhere((h) => h.id == widget.habitId);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader) _buildHeader(context, habit, habitService),
            const SizedBox(height: 16),
            _buildGrid(context, yearData, habit),
            const SizedBox(height: 16),
            _buildLegend(context, habit),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, HabitModel habit, HabitService habitService) {
    final stats = habitService.getHabitStats(widget.habitId);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: habit.color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: habit.icon != null 
                ? Icon(
                    IconData(int.parse(habit.icon!), fontFamily: 'MaterialIcons'),
                    size: 12,
                    color: Colors.white,
                  )
                : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (habit.description != null)
                    Text(
                      habit.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildStatChip('${stats.currentStreak} day streak', Icons.local_fire_department, Colors.orange),
            _buildStatChip('${stats.completionRate.toInt()}% complete', Icons.check_circle, Colors.green),
            _buildStatChip('${stats.totalCompletions} total', Icons.star, Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color color) {
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<List<HabitGridDay>> yearData, HabitModel habit) {
    if (yearData.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text(
          'No data for ${widget.year}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.year}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildMonthLabels(),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDayLabels(),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGridCells(yearData, habit),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthLabels() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return Row(
      children: [
        SizedBox(width: 20), // Offset for day labels
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: months.map((month) => Text(
              month,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayLabels() {
    final days = ['Mon', 'Wed', 'Fri'];
    
    return Column(
      children: [
        const SizedBox(height: widget.cellSize + widget.cellSpacing), // Monday
        ...days.map((day) => Container(
          height: widget.cellSize + widget.cellSpacing,
          width: 20,
          alignment: Alignment.centerLeft,
          child: Text(
            day,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildGridCells(List<List<HabitGridDay>> yearData, HabitModel habit) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: yearData.map((week) => Column(
          children: week.map((day) => _buildGridCell(day, habit)).toList(),
        )).toList(),
      ),
    );
  }

  Widget _buildGridCell(HabitGridDay day, HabitModel habit) {
    final color = _getCellColor(day, habit);
    final isToday = DateUtils.isSameDay(day.date, DateTime.now());
    
    return GestureDetector(
      onTap: () => widget.onDayTapped?.call(day.date),
      child: Container(
        width: widget.cellSize,
        height: widget.cellSize,
        margin: EdgeInsets.all(widget.cellSpacing / 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: isToday ? Border.all(color: Colors.blue, width: 1.5) : null,
        ),
        child: day.completionCount > 1 
          ? Center(
              child: Text(
                '${day.completionCount}',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      ),
    );
  }

  Color _getCellColor(HabitGridDay day, HabitModel habit) {
    if (!day.completed) {
      return Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey[800]! 
        : Colors.grey[200]!;
    }

    final baseColor = habit.color;
    
    switch (day.intensityLevel) {
      case 0:
        return Theme.of(context).brightness == Brightness.dark 
          ? Colors.grey[800]! 
          : Colors.grey[200]!;
      case 1:
        return baseColor.withOpacity(0.3);
      case 2:
        return baseColor.withOpacity(0.6);
      case 3:
        return baseColor.withOpacity(0.9);
      default:
        return baseColor;
    }
  }

  Widget _buildLegend(BuildContext context, HabitModel habit) {
    return Row(
      children: [
        Text(
          'Less',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) => Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: index == 0 
              ? (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[800]! 
                  : Colors.grey[200]!)
              : habit.color.withOpacity(0.2 + (index * 0.2)),
            borderRadius: BorderRadius.circular(2),
          ),
        )),
        const SizedBox(width: 8),
        Text(
          'More',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class HabitStreakWidget extends StatelessWidget {
  final String habitId;
  final bool showDetails;

  const HabitStreakWidget({
    Key? key,
    required this.habitId,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitService>(
      builder: (context, habitService, child) {
        final stats = habitService.getHabitStats(habitId);
        final habit = habitService.habits.firstWhere((h) => h.id == habitId);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                habit.color.withOpacity(0.1),
                habit.color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: habit.color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: stats.currentStreak > 0 ? Colors.orange : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${stats.currentStreak} Day Streak',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (showDetails) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      'Longest Streak',
                      '${stats.longestStreak} days',
                      Icons.emoji_events,
                      Colors.amber,
                    ),
                    _buildStatItem(
                      'This Week',
                      '${stats.weeklyRate.toInt()}%',
                      Icons.calendar_view_week,
                      Colors.blue,
                    ),
                    _buildStatItem(
                      'This Month',
                      '${stats.monthlyRate.toInt()}%',
                      Icons.calendar_month,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class HabitWeeklyGridWidget extends StatelessWidget {
  final String habitId;
  final DateTime startDate;
  final Function(DateTime)? onDayTapped;

  const HabitWeeklyGridWidget({
    Key? key,
    required this.habitId,
    required this.startDate,
    this.onDayTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitService>(
      builder: (context, habitService, child) {
        final weekData = habitService.getWeeklyGridData(habitId, startDate);
        final habit = habitService.habits.firstWhere((h) => h.id == habitId);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This Week',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: weekData.map((day) => _buildWeekDay(context, day, habit)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekDay(BuildContext context, HabitGridDay day, HabitModel habit) {
    final isToday = DateUtils.isSameDay(day.date, DateTime.now());
    final dayName = DateFormat('E').format(day.date);
    final dayNumber = day.date.day;
    
    return GestureDetector(
      onTap: () => onDayTapped?.call(day.date),
      child: Column(
        children: [
          Text(
            dayName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: day.completed 
                ? habit.color 
                : (Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[800] 
                    : Colors.grey[200]),
              borderRadius: BorderRadius.circular(8),
              border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
            ),
            child: Center(
              child: day.completed 
                ? Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ),
          ),
          if (day.completionCount > 1) ...[
            const SizedBox(height: 4),
            Text(
              '${day.completionCount}x',
              style: TextStyle(
                fontSize: 10,
                color: habit.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}