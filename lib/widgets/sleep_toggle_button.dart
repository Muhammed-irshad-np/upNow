import 'package:flutter/material.dart';
import 'package:upnow/utils/app_theme.dart';

enum SleepToggleState {
  sleep,
  wakeUp,
}

class SleepToggleButton extends StatelessWidget {
  final SleepToggleState currentState;
  final Function(SleepToggleState) onToggle;

  const SleepToggleButton({
    Key? key,
    required this.currentState,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleOption(SleepToggleState.sleep),
            _buildToggleOption(SleepToggleState.wakeUp),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(SleepToggleState state) {
    final isSelected = state == currentState;
    final label = state == SleepToggleState.sleep ? 'Sleep' : 'Wake Up';
    final icon = state == SleepToggleState.sleep
        ? Icons.nightlight_round
        : Icons.wb_sunny;
    final gradient = state == SleepToggleState.sleep
        ? AppTheme.nightGradient
        : AppTheme.morningGradient;

    return Expanded(
      child: GestureDetector(
        onTap: () => onToggle(state),
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            gradient: isSelected ? gradient : null,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : AppTheme.secondaryTextColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 