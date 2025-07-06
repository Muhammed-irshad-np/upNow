import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/providers/alarm_provider.dart';
import 'package:upnow/screens/alarm/alarm_screen.dart';
import 'package:upnow/screens/alarm/create_alarm_screen.dart';
import 'package:upnow/screens/onboarding/onboarding_screen.dart';
import 'package:upnow/screens/settings/settings_screen.dart';
import 'package:upnow/services/alarm_service.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/utils/preferences_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AlarmProvider()),
            // ChangeNotifierProvider(create: (_) => SleepProvider()), // Commented out for first phase
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
      },
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
    final hasCompleted = await PreferencesHelper.hasCompletedOnboarding();
    // final hasCompleted = false;
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
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
                 child: FloatingActionButton(
           onPressed: () async {
             // Navigate to create alarm screen  
             await Navigator.pushNamed(context, '/create_alarm');
           },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomAppBar(
            color: Colors.transparent,
            elevation: 0,
            height: 70,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentIndex = 0;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _currentIndex == 0 
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _currentIndex == 0 ? Icons.alarm : Icons.alarm_outlined,
                            color: _currentIndex == 0 
                              ? AppTheme.primaryColor 
                              : AppTheme.secondaryTextColor,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Alarm',
                            style: TextStyle(
                              fontSize: 12,
                              color: _currentIndex == 0 
                                ? AppTheme.primaryColor 
                                : AppTheme.secondaryTextColor,
                              fontWeight: _currentIndex == 0 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 80), // Space for FAB
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _currentIndex == 1 
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _currentIndex == 1 ? Icons.settings : Icons.settings_outlined,
                            color: _currentIndex == 1 
                              ? AppTheme.primaryColor 
                              : AppTheme.secondaryTextColor,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 12,
                              color: _currentIndex == 1 
                                ? AppTheme.primaryColor 
                                : AppTheme.secondaryTextColor,
                              fontWeight: _currentIndex == 1 
                                ? FontWeight.w600 
                                : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
