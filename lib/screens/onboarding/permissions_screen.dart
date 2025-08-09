import 'package:flutter/material.dart';
import 'package:upnow/main.dart';
import 'package:upnow/services/permissions_manager.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/permissions_provider.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ChangeNotifierProvider(
            create: (_) => PermissionsProvider(),
            child: Consumer<PermissionsProvider>(builder: (context, provider, _) {
              return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Title
              const Text(
                'One Last Step',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                'UpNow needs a few permissions to function properly. We\'ll guide you through them one by one.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.secondaryTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // Permissions list
              _buildPermissionItem(
                'Notifications',
                'So you can receive alarm alerts',
                Icons.notifications_outlined,
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                'Display Over Apps',
                'To show alarms when your phone is locked',
                Icons.layers_outlined,
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                'Battery Optimization',
                'To ensure alarms work even in battery saving mode',
                Icons.battery_charging_full,
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                'Schedule Exact Alarms',
                'For precise alarm timing',
                Icons.access_time,
              ),
              
              const Spacer(),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: provider.isRequesting
                          ? null
                          : _skipPermissions,
                      child: Text(
                        'Skip for Now',
                        style: TextStyle(
                          color: AppTheme.secondaryTextColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: provider.isRequesting
                          ? null
                          : () => _requestPermissions(context, provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: provider.isRequesting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(String title, String description, IconData icon) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _requestPermissions(BuildContext context, PermissionsProvider provider) async {
    provider.startRequest();

    // Request permissions one by one with explanations
    await PermissionsManager.requestNotifications(context);
    await PermissionsManager.requestDisplayOverApps(context);
    await PermissionsManager.requestBatteryOptimization(context);
    await PermissionsManager.requestExactAlarm(context);

    provider.finishRequest();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  void _skipPermissions() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }
} 