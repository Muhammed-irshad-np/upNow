import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/sleep_provider.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/gradient_button.dart';
import 'package:upnow/widgets/sleep_toggle_button.dart';

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({Key? key}) : super(key: key);

  @override
  _SleepTrackerScreenState createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _toggleSleepTracking(SleepToggleState state) async {
    final provider = Provider.of<SleepProvider>(context, listen: false);
    
    if (state == SleepToggleState.sleep) {
      await provider.startTracking();
    } else {
      if (provider.isTracking) {
        await provider.stopTracking();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final sleepProvider = Provider.of<SleepProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Sleep Tracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.textColor,
          unselectedLabelColor: AppTheme.secondaryTextColor,
          tabs: const [
            Tab(text: 'Tracker'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrackerTab(sleepProvider),
          _buildHistoryTab(sleepProvider),
        ],
      ),
    );
  }
  
  Widget _buildTrackerTab(SleepProvider provider) {
    final isTracking = provider.isTracking;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTracking)
            _buildActiveTrackingUI(provider)
          else
            _buildStartTrackingUI(),
          
          const SizedBox(height: 24),
          
          _buildSleepStatsCard(provider),
          const SizedBox(height: 16),
          _buildSleepTipsCard(),
        ],
      ),
    );
  }
  
  Widget _buildActiveTrackingUI(SleepProvider provider) {
    final duration = provider.currentTrackingDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    return Column(
      children: [
        const Text(
          'Sleep in progress',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: AppTheme.darkCardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.nightlight_round,
                size: 48,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$hours',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const Text(
                    'h',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$minutes',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const Text(
                    'm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GradientButton(
          text: 'Wake Up Now',
          onPressed: () {
            _toggleSleepTracking(SleepToggleState.wakeUp);
          },
          gradient: AppTheme.morningGradient,
          icon: const Icon(Icons.alarm, color: Colors.white),
        ),
      ],
    );
  }
  
  Widget _buildStartTrackingUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sleep Better',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Track your sleep to get insights and improve your sleep quality',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              const Icon(
                Icons.bedtime,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ready to sleep?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Place your device on the bed',
                style: TextStyle(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                text: 'Start Sleep Tracking',
                onPressed: () {
                  _toggleSleepTracking(SleepToggleState.sleep);
                },
                gradient: AppTheme.nightGradient,
                icon: const Icon(Icons.bedtime, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSleepStatsCard(SleepProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Sleep Stats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  _tabController.animateTo(1);
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Placeholder for sleep stats
          const Text(
            'No recent sleep data available',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSleepTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amber),
              const SizedBox(width: 8),
              const Text(
                'Tips for Better Sleep',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• Maintain a consistent sleep schedule\n'
            '• Avoid caffeine late in the day\n'
            '• Create a restful environment\n'
            '• Limit exposure to screens before bedtime\n'
            '• Avoid heavy meals before sleeping',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryTab(SleepProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 100,
            color: AppTheme.secondaryTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No sleep data yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start tracking your sleep to see history',
            style: TextStyle(
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
} 