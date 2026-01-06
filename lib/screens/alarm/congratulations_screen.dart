import 'package:flutter/material.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:lottie/lottie.dart';
import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/navigation_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CongratulationsScreen extends StatefulWidget {
  const CongratulationsScreen({super.key});

  @override
  State<CongratulationsScreen> createState() => _CongratulationsScreenState();
}

class _CongratulationsScreenState extends State<CongratulationsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Animation
                    DotLottieLoader.fromAsset(
                      'assets/images/Success.lottie',
                      frameBuilder: (context, dotlottie) {
                        if (dotlottie != null) {
                          return Lottie.memory(
                            dotlottie.animations.values.first,
                            width: 150.w,
                            height: 150.h,
                            repeat: false,
                          );
                        } else {
                          return SizedBox(width: 150.w, height: 150.h);
                        }
                      },
                    ),

                    const SizedBox(height: 32),

                    // Congratulations Text
                    Text(
                      'Congratulations!',
                      style: AppTheme.headlineStyle.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Success Message
                    Text(
                      'You successfully solved the problem\nand dismissed the alarm!',
                      style: AppTheme.subtitleStyle.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Done Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Reset navigation to Alarm tab (index 0)
                          Provider.of<NavigationProvider>(context,
                                  listen: false)
                              .setCurrentIndex(0);

                          // Navigate back to main screen
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/main',
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
