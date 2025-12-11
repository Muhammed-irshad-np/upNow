import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/services/habit_service.dart';
import 'package:upnow/screens/add_habit_screen.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/utils/haptic_feedback_helper.dart';

class HabitDetailScreen extends StatefulWidget {
  final HabitModel habit;

  const HabitDetailScreen({Key? key, required this.habit}) : super(key: key);

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

enum TimeFilter { week, month, year }

class _HabitDetailScreenState extends State<HabitDetailScreen>
    with SingleTickerProviderStateMixin {
  late HabitModel _habit;
  TimeFilter _selectedFilter = TimeFilter.month;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _refreshHabit() {
    final habitService = context.read<HabitService>();
    final updatedHabit = habitService.habits.firstWhere(
      (h) => h.id == _habit.id,
      orElse: () => _habit,
    );
    setState(() {
      _habit = updatedHabit;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<HabitService>(
        builder: (context, habitService, child) {
          // Check if habit still exists
          if (!habitService.habits.any((h) => h.id == _habit.id)) {
            return const Center(child: Text('Habit not found'));
          }

          final stats = habitService.getHabitStats(_habit.id);

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      SizedBox(height: 16.h),
                      _buildStatsCards(stats),
                      SizedBox(height: 24.h),
                      _buildTimeFilterTabs(),
                      SizedBox(height: 16.h),
                      _buildChartsSection(habitService, stats),
                      SizedBox(height: 24.h),
                      _buildInsightsSection(stats),
                      SizedBox(height: 24.h),
                      _buildDeleteButton(context, habitService),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.h,
      pinned: true,
      backgroundColor: AppTheme.darkBackground,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            HapticFeedbackHelper.trigger();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddHabitScreen(habit: _habit),
              ),
            ).then((_) {
              _refreshHabit();
            });
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _habit.color.withOpacity(0.3),
                    AppTheme.darkBackground,
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: _habit.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: _habit.color.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getIconData(),
                      color: _habit.color,
                      size: 40.sp,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _habit.name,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  if (_habit.description != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      _habit.description!,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData() {
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
    return iconMap[_habit.icon] ?? Icons.star;
  }

  Widget _buildStatsCards(HabitStats stats) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 1.5,
        children: [
          _buildAnimatedStatCard(
            'Current Streak',
            '${stats.currentStreak}',
            'days',
            Icons.local_fire_department,
            Colors.orange,
            0,
          ),
          _buildAnimatedStatCard(
            'Best Streak',
            '${stats.longestStreak}',
            'days',
            Icons.emoji_events,
            Colors.amber,
            100,
          ),
          _buildAnimatedStatCard(
            'Completion',
            '${stats.completionRate.toStringAsFixed(0)}',
            '%',
            Icons.pie_chart,
            Colors.blue,
            200,
          ),
          _buildAnimatedStatCard(
            'Total Done',
            '${stats.totalCompletions}',
            'times',
            Icons.check_circle,
            Colors.green,
            300,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
    int delayMs,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(icon, color: color, size: 18.sp),
                    ),
                    Text(
                      unit,
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.secondaryTextColor,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeFilterTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCardColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            _buildFilterTab('Week', TimeFilter.week),
            _buildFilterTab('Month', TimeFilter.month),
            _buildFilterTab('Year', TimeFilter.year),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, TimeFilter filter) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedbackHelper.trigger();
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [_habit.color, _habit.color.withOpacity(0.7)],
                  )
                : null,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.secondaryTextColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartsSection(HabitService habitService, HabitStats stats) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          if (_selectedFilter == TimeFilter.week) ...[
            _buildWeeklyBarChart(habitService),
          ] else if (_selectedFilter == TimeFilter.month) ...[
            _buildMonthlyLineChart(habitService),
            SizedBox(height: 16.h),
            _buildContributionHeatmap(habitService),
          ] else ...[
            _buildContributionHeatmap(habitService),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(HabitService habitService) {
    final weekData = habitService.getWeeklyGridData(
      _habit.id,
      DateTime.now().subtract(const Duration(days: 6)),
    );

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Progress',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 200.h,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: _habit.color.withOpacity(0.8),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = weekData[group.x.toInt()];
                      return BarTooltipItem(
                        day.completed ? 'Completed' : 'Not done',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        return Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 12.sp,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  weekData.length,
                  (index) {
                    final day = weekData[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: day.completed ? 1 : 0.1,
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: day.completed
                                ? [_habit.color, _habit.color.withOpacity(0.6)]
                                : [
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.05)
                                  ],
                          ),
                          width: 24.w,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyLineChart(HabitService habitService) {
    final monthData =
        habitService.getMonthlyGridData(_habit.id, DateTime.now());

    // Group by weeks for smoother chart
    final spots = <FlSpot>[];
    for (int i = 0; i < monthData.length; i++) {
      spots.add(FlSpot(i.toDouble(), monthData[i].completed ? 1 : 0));
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Trend',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 150.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.05),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 7,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= monthData.length)
                          return const SizedBox();
                        final day = monthData[value.toInt()].date.day;
                        return Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 10.sp,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [_habit.color, _habit.color.withOpacity(0.5)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: spot.y > 0.5 ? 4 : 2,
                          color: spot.y > 0.5
                              ? _habit.color
                              : Colors.white.withOpacity(0.3),
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _habit.color.withOpacity(0.3),
                          _habit.color.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionHeatmap(HabitService habitService) {
    final yearGrid =
        habitService.getYearlyGridData(_habit.id, DateTime.now().year);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity Heatmap',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildHeatmapLegend(),
            ],
          ),
          SizedBox(height: 16.h),
          if (yearGrid.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: Text(
                  'No data available yet',
                  style: TextStyle(color: AppTheme.secondaryTextColor),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: yearGrid.reversed.map((week) {
                  return Column(
                    children: week.map((day) {
                      return Container(
                        width: 14.w,
                        height: 14.w,
                        margin: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: day.completed
                              ? _habit.color
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(3.r),
                          border: day.date.day == DateTime.now().day &&
                                  day.date.month == DateTime.now().month
                              ? Border.all(color: Colors.white, width: 1)
                              : null,
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      children: [
        Text(
          'Less',
          style: TextStyle(
            color: AppTheme.secondaryTextColor,
            fontSize: 10.sp,
          ),
        ),
        SizedBox(width: 4.w),
        ...List.generate(4, (index) {
          return Container(
            width: 12.w,
            height: 12.w,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              color: _habit.color.withOpacity(0.25 + (index * 0.25)),
              borderRadius: BorderRadius.circular(2.r),
            ),
          );
        }),
        SizedBox(width: 4.w),
        Text(
          'More',
          style: TextStyle(
            color: AppTheme.secondaryTextColor,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(HabitStats stats) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _habit.color.withOpacity(0.15),
              _habit.color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: _habit.color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: _habit.color, size: 24.sp),
                SizedBox(width: 8.w),
                Text(
                  'Insights',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildInsightRow(
              Icons.trending_up,
              'Weekly Success',
              '${stats.weeklyRate.toStringAsFixed(0)}%',
            ),
            SizedBox(height: 12.h),
            _buildInsightRow(
              Icons.calendar_month,
              'Monthly Success',
              '${stats.monthlyRate.toStringAsFixed(0)}%',
            ),
            SizedBox(height: 12.h),
            _buildInsightRow(
              Icons.star,
              'Total Days',
              '${stats.completedDays} / ${stats.totalDays}',
            ),
            SizedBox(height: 16.h),
            _buildMomentumIndicator(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.secondaryTextColor, size: 16.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMomentumIndicator(HabitStats stats) {
    final momentum = stats.currentStreak > 0 ? 'On Fire!' : 'Get Started!';
    final momentumColor = stats.currentStreak > 0 ? Colors.orange : Colors.blue;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: momentumColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: momentumColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            stats.currentStreak > 0
                ? Icons.local_fire_department
                : Icons.rocket_launch,
            color: momentumColor,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            momentum,
            style: TextStyle(
              color: momentumColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, HabitService habitService) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: () => _confirmDelete(context, habitService),
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text(
            'Delete Habit',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            backgroundColor: Colors.red.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(color: Colors.red.withOpacity(0.3)),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, HabitService habitService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title:
            const Text('Delete Habit?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${_habit.name}"? This action cannot be undone.',
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
              await habitService.deleteHabit(_habit.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close detail screen
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
