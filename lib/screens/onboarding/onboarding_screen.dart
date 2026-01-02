import 'package:flutter/material.dart';
import 'package:upnow/screens/onboarding/onboarding_pages.dart';
import 'package:upnow/screens/onboarding/wakeup_time_page.dart';
import 'package:upnow/screens/onboarding/permissions_screen.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/utils/preferences_helper.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/onboarding_provider.dart';
import 'package:upnow/utils/haptic_feedback_helper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  // Add 1 to total pages for the WakeupTimePage which is inserted before the last page
  final int _totalPages = onboardingPages.length + 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage(OnboardingProvider p) {
    if (p.currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    await PreferencesHelper.setOnboardingCompleted();

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PermissionsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Consumer<OnboardingProvider>(builder: (context, provider, _) {
          return Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: provider.currentPage == _totalPages - 2
                        ? null // Disable/Hide skip on wakeup time page (which is second to last now)
                        : () {
                            HapticFeedbackHelper.trigger();
                            _completeOnboarding();
                          },
                    child: provider.currentPage == _totalPages - 2
                        ? const SizedBox
                            .shrink() // Hide skip text on wakeup time page
                        : Text(
                            'Skip',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),

              // PageView for onboarding content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _totalPages,
                  onPageChanged: (int page) => provider.setCurrentPage(page),
                  itemBuilder: (context, index) {
                    // Logic to insert WakeupTimePage before the last page
                    if (index == onboardingPages.length - 1) {
                      return const WakeupTimePage();
                    } else if (index >= onboardingPages.length) {
                      return onboardingPages[
                          index - 1]; // The last page (You're All Set)
                    }
                    return onboardingPages[index];
                  },
                ),
              ),

              // Page indicator and next button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page indicator
                    Row(
                      children: List.generate(
                        _totalPages,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: provider.currentPage == index
                                ? AppTheme.primaryColor
                                : AppTheme.secondaryTextColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),

                    // Next button
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedbackHelper.trigger();
                        _onNextPage(provider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        provider.currentPage == _totalPages - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
