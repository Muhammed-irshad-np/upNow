import 'package:flutter/material.dart';
import 'package:upnow/utils/app_theme.dart';

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool showPermissionInfo;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.showPermissionInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
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
    description: 'Your modern alarm clock and sleep tracker to help you wake up refreshed..',
    icon: Icons.watch_later_outlined,
  ),
  const OnboardingPage(
    title: 'Smart Alarm',
    description: 'Set alarms with customizable options to ensure you wake up on time, every time.',
    icon: Icons.alarm,
  ),
  const OnboardingPage(
    title: 'Track Your Sleep',
    description: 'Monitor your sleep patterns and get insights to improve your sleep quality.',
    icon: Icons.nightlight_round,
  ),
  const OnboardingPage(
    title: 'You\'re All Set!',
    description: 'Get ready to experience better mornings with UpNow.',
    icon: Icons.check_circle_outline,
    showPermissionInfo: true,
  ),
]; 