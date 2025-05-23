import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/providers/alarm_provider.dart';
import 'package:upnow/providers/sleep_provider.dart';
import 'package:upnow/screens/alarm/alarm_screen.dart';
import 'package:upnow/screens/alarm/create_alarm_screen.dart';
import 'package:upnow/screens/onboarding/onboarding_screen.dart';
import 'package:upnow/screens/sleep_tracker/sleep_tracker_screen.dart';
import 'package:upnow/screens/settings/settings_screen.dart';
import 'package:upnow/services/alarm_service.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/utils/preferences_helper.dart';

// Global navigator key for accessing Navigator from outside the widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize database
  await HiveDatabase.init();

  // Migrate default sound path to alarm_sound
  await _migrateDefaultSoundPath();

  // Initialize alarm service
  await AlarmService.init();

  runApp(const MyApp());
}

/// Migrates any alarms with 'default' sound path to 'alarm_sound'
Future<void> _migrateDefaultSoundPath() async {
  final alarms = HiveDatabase.getAllAlarms();
  for (final alarm in alarms) {
    if (alarm.soundPath == 'default') {
      alarm.soundPath = 'alarm_sound';
      await HiveDatabase.saveAlarm(alarm);
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlarmProvider()),
        ChangeNotifierProvider(create: (_) => SleepProvider()),
      ],
      child: MaterialApp(
        title: 'UpNow',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: AppTheme.getDarkTheme(),
        home: const StartupScreen(),
        routes: {
          '/create_alarm': (context) => const CreateAlarmScreen(),
          '/edit_alarm': (context) {
            final alarm =
                ModalRoute.of(context)?.settings.arguments as AlarmModel;
            return CreateAlarmScreen(alarm: alarm);
          },
        },
      ),
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // final hasCompleted = await PreferencesHelper.hasCompletedOnboarding();
    final hasCompleted = false;
    setState(() {
      _hasCompletedOnboarding = hasCompleted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }
    
    return _hasCompletedOnboarding ? const MainScreen() : const OnboardingScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AlarmScreen(),
    const SleepTrackerScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Update the global variable in AlarmService
    currentAppState = state;
    debugPrint("App Lifecycle State Changed: $state");
  }

  Future<void> _requestPermissions() async {
    await AlarmService.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppTheme.darkSurface,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.secondaryTextColor,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.alarm),
              label: 'Alarm',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.nightlight_round),
              label: 'Sleep',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
