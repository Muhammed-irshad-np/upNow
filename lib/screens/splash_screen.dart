import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/onboarding_provider.dart';
import 'package:upnow/screens/onboarding/onboarding_screen.dart';
import 'package:upnow/main.dart';
import 'package:upnow/services/alarm_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    
    // Navigate after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });
  }

  Future<void> _navigateToNext() async {
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    await onboardingProvider.checkOnboardingStatus();

    if (!mounted) return;

    if (onboardingProvider.hasCompletedOnboarding) {
      // Ensure navigation is attempted once UI is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AlarmService.tryNavigateToCongratulationsIfReady();
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Logo and branding
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // UpNow branding
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'UpN',
                                style: TextStyle(
                                  fontSize: 52.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                  letterSpacing: -1.5,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 4.w),
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.alarm,
                                  size: 38.sp,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'w',
                                style: TextStyle(
                                  fontSize: 52.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                  letterSpacing: -1.5,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 16.h),
                          
                          // Tagline with gradient text
                          ShaderMask(
                            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                            child: Text(
                              'Rise & Thrive',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 2,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 8.h),
                          
                          Text(
                            'Your Perfect Wake-Up Companion',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.secondaryTextColor,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // Linear progress indicator
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Stack(
                            children: [
                              // Background track
                              Container(
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: AppTheme.darkSurfaceLight,
                                  borderRadius: BorderRadius.circular(2.h),
                                ),
                              ),
                              // Progress track with gradient
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return Container(
                                    height: 4.h,
                                    width: MediaQuery.of(context).size.width * 
                                           _progressAnimation.value * 0.85,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(2.h),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withOpacity(0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

