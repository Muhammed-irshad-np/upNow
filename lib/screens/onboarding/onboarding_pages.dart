import 'package:flutter/material.dart';
import 'package:upnow/utils/app_theme.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final String? imagePath;
  final bool showPermissionInfo;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.imagePath,
    this.showPermissionInfo = false,
  }) : assert(icon != null || imagePath != null,
            'Either icon or imagePath must be provided');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon or Image with background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: imagePath != null
                  ? null
                  : AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: imagePath != null
                ? Image.asset(
                    imagePath!,
                    fit: BoxFit.contain,
                  )
                : Icon(
                    icon,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.secondaryTextColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Permission info
          if (showPermissionInfo) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orangeAccent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.orangeAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We\'ll ask for necessary permissions after setup to ensure alarms work correctly.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// List of onboarding pages
final List<Widget> onboardingPages = [
  const OnboardingPage(
    title: 'Welcome to UpNow',
    description: 'Your ultimate companion for productivity and habits.',
    imagePath: 'assets/images/app_icon.png',
  ),
  const OnboardingPage(
    title: 'Versatile Alarms',
    description:
        'More than just a wake-up call. Schedule reminders for meetings, workouts, or any important event.',
    icon: Icons.alarm,
  ),
  const OnboardingPage(
    title: 'Build Better Habits',
    description:
        'Create and track positive routines to stay consistent and achieve your goals.',
    icon: Icons.track_changes,
  ),
  const OnboardingPage(
    title: 'You\'re All Set!',
    description: 'Start your journey with UpNow today.',
    icon: Icons.check_circle_outline,
    showPermissionInfo: true,
  ),
];
