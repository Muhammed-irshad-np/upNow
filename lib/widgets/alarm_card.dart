import 'package:flutter/material.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/utils/app_theme.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback onDelete;
  final Function(bool) onToggle;
  final VoidCallback onTap;

  const AlarmCard({
    Key? key,
    required this.alarm,
    required this.onDelete,
    required this.onToggle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alarm.timeString,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alarm.repeatString,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: alarm.isEnabled,
                    onChanged: onToggle,
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
              if (alarm.label.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.label_outline,
                      size: 16,
                      color: AppTheme.secondaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      alarm.label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    alarm.dismissTypeString,
                    Icons.check_circle_outline,
                  ),
                  const SizedBox(width: 8),
                  if (alarm.vibrate)
                    _buildInfoChip(
                      'Vibrate',
                      Icons.vibration,
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 22,
                    ),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
} 