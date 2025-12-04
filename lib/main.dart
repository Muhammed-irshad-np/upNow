import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/providers/alarm_provider.dart';
import 'package:upnow/providers/settings_provider.dart';
import 'package:upnow/providers/navigation_provider.dart';
import 'package:upnow/providers/onboarding_provider.dart';
import 'package:upnow/screens/alarm/alarm_screen.dart';
import 'package:upnow/screens/alarm/congratulations_screen.dart';
import 'package:upnow/screens/alarm/create_alarm_screen.dart';
import 'package:upnow/screens/onboarding/onboarding_screen.dart';
import 'package:upnow/screens/settings/settings_screen.dart';
import 'package:upnow/screens/habit_home_screen.dart';
import 'package:upnow/screens/splash_screen.dart';
import 'package:upnow/services/alarm_service.dart';
import 'package:upnow/services/habit_service.dart';
import 'package:upnow/services/habit_alarm_service.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upnow/utils/global_error_handler.dart';
import 'package:upnow/utils/navigation_service.dart';
import 'package:upnow/utils/haptic_feedback_helper.dart';

// Navigator key is provided by navigation_service.dart

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

  // Initialize habit alarm service
  await HabitAlarmService.initialize();

  // Initialize global error handler before the app starts
  GlobalErrorHandler.initialize(navigatorKey: navigationKey);

  // Wrap the app in a guarded zone to catch any uncaught errors and show dialog
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (Object error, StackTrace stack) {
    GlobalErrorHandler.recordError(error, stack);
  });
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
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => HabitService()),
            ChangeNotifierProvider(create: (_) => NavigationProvider()),
            ChangeNotifierProvider(create: (_) => OnboardingProvider()),
            // ChangeNotifierProvider(create: (_) => SleepProvider()), // Commented out for first phase
          ],
          child: MaterialApp(
            title: 'UpNow',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigationKey,
            theme: AppTheme.getDarkTheme(),
            home: const SplashScreen(),
            routes: {
              '/create_alarm': (context) => const CreateAlarmScreen(),
              '/edit_alarm': (context) {
                final alarm =
                    ModalRoute.of(context)?.settings.arguments as AlarmModel;
                return CreateAlarmScreen(alarm: alarm);
              },
              '/congratulations': (context) => const CongratulationsScreen(),
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
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
    // After first frame, attempt to consume any pending navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AlarmService.tryNavigateToCongratulationsIfReady();
    });
  }

  Future<void> _checkOnboardingStatus() async {
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);
    await onboardingProvider.checkOnboardingStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, onboardingProvider, child) {
        if (onboardingProvider.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.darkBackground,
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            ),
          );
        }

        return onboardingProvider.hasCompletedOnboarding
            ? Builder(
                builder: (context) {
                  // Ensure navigation is attempted once UI is built
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AlarmService.tryNavigateToCongratulationsIfReady();
                  });
                  return const MainScreen();
                },
              )
            : const OnboardingScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final List<Widget> _screens = [
    const AlarmScreen(),
    const HabitHomeScreen(),
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

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.track_changes,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Coming Soon!',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Habits Feature',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We\'re working hard to bring you an amazing habits tracking experience! This feature will help you build and maintain positive daily routines.',
                style: TextStyle(
                  color: AppTheme.secondaryTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: const Text(
                        'Stay tuned for updates! We\'ll notify you when it\'s ready.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                HapticFeedbackHelper.trigger();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          body: _screens[navigationProvider.currentIndex],
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double segmentWidth = constraints.maxWidth / 3;
                  return Stack(
                    children: [
                      // Switch-like full block indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOut,
                        left: navigationProvider.currentIndex * segmentWidth,
                        top: 6,
                        bottom: 6,
                        child: Container(
                          width: segmentWidth,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _NavItem(
                            width: segmentWidth,
                            icon: navigationProvider.currentIndex == 0
                                ? Icons.alarm
                                : Icons.alarm_outlined,
                            label: 'Alarms',
                            selected: navigationProvider.currentIndex == 0,
                            onTap: () {
                              HapticFeedbackHelper.trigger();
                              navigationProvider.setCurrentIndex(0);
                            },
                          ),
                          // _NavItem(
                          //   width: segmentWidth,
                          //   icon: Icons.track_changes_outlined,
                          //   label: 'Habits',
                          //   selected: false,
                          //   onTap: () => _showComingSoonDialog(context),
                          // ),
                          _NavItem(
                            width: segmentWidth,
                            icon: navigationProvider.currentIndex == 1
                                ? Icons.track_changes
                                : Icons.track_changes_outlined,
                            label: 'Habits',
                            selected: navigationProvider.currentIndex == 1,
                            onTap: () {
                              HapticFeedbackHelper.trigger();
                              navigationProvider.setCurrentIndex(1);
                            },
                          ),
                          _NavItem(
                            width: segmentWidth,
                            icon: navigationProvider.currentIndex == 2
                                ? Icons.settings
                                : Icons.settings_outlined,
                            label: 'Settings',
                            selected: navigationProvider.currentIndex == 2,
                            onTap: () {
                              HapticFeedbackHelper.trigger();
                              navigationProvider.setCurrentIndex(2);
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.width,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground =
        selected ? Colors.white : AppTheme.secondaryTextColor;
    return SizedBox(
      width: width,
      height: double.infinity,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
