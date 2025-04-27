import 'dart:io';

import 'package:flutter/material.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/gradient_button.dart';
import 'package:upnow/services/alarm_service.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/database/hive_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:upnow/screens/alarm/alarm_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'App Settings',
              children: [
                _buildSettingTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notification settings',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.color_lens_outlined,
                  title: 'Theme',
                  subtitle: 'Dark mode',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.volume_up_outlined,
                  title: 'Sound',
                  subtitle: 'Alarm sounds and volume',
                  onTap: () {},
                ),
              ],
            ),
            _buildSection(
              title: 'Sleep Tracking',
              children: [
                _buildSettingTile(
                  icon: Icons.bedtime_outlined,
                  title: 'Sleep Detection',
                  subtitle: 'Sensitivity: Medium',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.watch_outlined,
                  title: 'Sleep Schedule',
                  subtitle: 'Set your ideal sleep times',
                  onTap: () {},
                ),
                _buildSwitchTile(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Sleep Reminders',
                  subtitle: 'Remind you to go to sleep',
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
            _buildSection(
              title: 'Alarm Settings',
              children: [
                _buildSwitchTile(
                  icon: Icons.vibration_outlined,
                  title: 'Vibration',
                  subtitle: 'Vibrate when alarm sounds',
                  value: true,
                  onChanged: (value) {},
                ),
                _buildSettingTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Dismissal Tasks',
                  subtitle: 'Configure wake-up tasks',
                  onTap: () {},
                ),
                _buildSwitchTile(
                  icon: Icons.snooze_outlined,
                  title: 'Snooze',
                  subtitle: '5 minutes',
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
            _buildSection(
              title: 'App Info',
              children: [
                _buildSettingTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'Version 1.0.0',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'FAQs and contact info',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Data usage and permissions',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            GradientButton(
              gradient: AppTheme.morningGradient,
              text: 'Reset All Settings',
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.darkCardColor,
                    title: const Text(
                      'Reset Settings?',
                      style: TextStyle(color: AppTheme.textColor),
                    ),
                    content: const Text(
                      'This will reset all settings to default values. This action cannot be undone.',
                      style: TextStyle(color: AppTheme.secondaryTextColor),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Reset settings logic would go here
                          Navigator.pop(context);
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.secondaryTextColor,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.secondaryTextColor,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.secondaryTextColor,
          fontSize: 12,
        ),
      ),
      value: value,
      activeColor: AppTheme.primaryColor,
      onChanged: onChanged,
    );
  }
} 