import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/services/habit_service.dart';

import 'package:upnow/providers/habit_form_provider.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/gradient_button.dart';
import 'package:upnow/providers/subscription_provider.dart';
import 'package:upnow/screens/settings/subscription_screen.dart';
import 'package:upnow/providers/alarm_provider.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/screens/alarm/alarm_sound_selection_screen.dart';
import 'package:path/path.dart' as p;
import 'package:upnow/services/permissions_manager.dart';
import 'package:upnow/providers/alarm_form_provider.dart';

class AddHabitScreen extends StatefulWidget {
  final HabitModel? habit; // Optional habit for editing

  const AddHabitScreen({Key? key, this.habit}) : super(key: key);

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = HabitFormProvider(initialHabit: widget.habit);
        // Load linked alarm details if editing
        if (widget.habit != null) {
          final alarms = context.read<AlarmProvider>().alarms;
          try {
            final alarm =
                alarms.firstWhere((a) => a.linkedHabitId == widget.habit!.id);
            provider.setAlarmDetails(
                type: alarm.dismissType, sound: alarm.soundPath);
            // Ensure hasAlarm matches (it should be set by initialHabit, but double check)
            // provider.setHasAlarm(true); // HabitModel has 'hasAlarm', relying on that.
          } catch (_) {
            // No linked alarm found
          }
        }
        return provider;
      },
      child: Consumer<HabitFormProvider>(
        builder: (context, habitFormProvider, child) {
          return Scaffold(
            backgroundColor: AppTheme.darkBackground,
            appBar: AppBar(
              title:
                  Text(widget.habit == null ? 'Add New Habit' : 'Edit Habit'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
            body: SafeArea(
              child: Form(
                key: habitFormProvider.formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBasicInfoSection(habitFormProvider),
                            SizedBox(height: 24.h),
                            _buildFrequencySection(habitFormProvider),
                            SizedBox(height: 24.h),
                            _buildCustomizationSection(habitFormProvider),
                            SizedBox(height: 24.h),
                            _buildAlarmSection(habitFormProvider),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBackground,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: GradientButton(
                        text: widget.habit == null
                            ? 'Create Habit'
                            : 'Update Habit',
                        onPressed: () => _saveHabit(context, habitFormProvider),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoSection(HabitFormProvider habitFormProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: AppTheme.subtitleStyle,
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          controller: habitFormProvider.nameController,
          label: 'Habit Name',
          hint: 'e.g., Drink 8 glasses of water',
          icon: Icons.label_outline,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a habit name';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        _buildTextField(
          controller: habitFormProvider.descriptionController,
          label: 'Description (Optional)',
          hint: 'Add more details about this habit...',
          icon: Icons.description_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.secondaryTextColor,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: AppTheme.textColor),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: AppTheme.secondaryTextColor.withOpacity(0.5)),
            filled: true,
            fillColor: AppTheme.darkCardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(icon, color: AppTheme.secondaryTextColor),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildFrequencySection(HabitFormProvider habitFormProvider) {
    final frequencyOptions = [
      HabitFrequency.daily,
      HabitFrequency.custom,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency',
          style: AppTheme.subtitleStyle,
        ),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: frequencyOptions.map((frequency) {
            final isSelected = habitFormProvider.selectedFrequency == frequency;
            return GestureDetector(
              onTap: () => habitFormProvider.setFrequency(frequency),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.darkCardColor,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  _getFrequencyText(frequency),
                  style: TextStyle(
                    color:
                        isSelected ? Colors.white : AppTheme.secondaryTextColor,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (habitFormProvider.selectedFrequency == HabitFrequency.custom) ...[
          SizedBox(height: 16.h),
          const Text(
            'Select Days',
            style: TextStyle(
              color: AppTheme.textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          _buildDaySelector(habitFormProvider),
        ],
      ],
    );
  }

  Widget _buildDaySelector(HabitFormProvider habitFormProvider) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayNumber = index + 1;
        final isSelected = habitFormProvider.selectedDays.contains(dayNumber);

        return GestureDetector(
          onTap: () => habitFormProvider.toggleDay(dayNumber),
          child: Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isSelected ? AppTheme.primaryColor : AppTheme.darkCardColor,
            ),
            child: Center(
              child: Text(
                days[index],
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : AppTheme.secondaryTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCustomizationSection(HabitFormProvider habitFormProvider) {
    // Find selected icon data
    final selectedIconData = habitFormProvider.habitIcons.firstWhere(
      (icon) => icon['code'] == habitFormProvider.selectedIcon,
      orElse: () => habitFormProvider.habitIcons.first,
    );

    final isPro = context.read<SubscriptionProvider>().isPro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customization',
          style: AppTheme.subtitleStyle,
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            // Color selector
            Expanded(
              child: GestureDetector(
                onTap: () => _showColorPicker(context, habitFormProvider),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCardColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: habitFormProvider.selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.w),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Color',
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.secondaryTextColor,
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Icon selector
            Expanded(
              child: GestureDetector(
                onTap: () => _showIconPicker(context, habitFormProvider),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCardColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color:
                              habitFormProvider.selectedColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          selectedIconData['icon'],
                          color: habitFormProvider.selectedColor,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Icon',
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.secondaryTextColor,
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // Show Stats Toggle (Premium)
        GestureDetector(
          onTap: !isPro
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen()),
                  );
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkCardColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: AbsorbPointer(
              absorbing: !isPro,
              child: SwitchListTile(
                title: Row(
                  children: [
                    const Text(
                      'Show Stats on Card',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isPro) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  'Display stats directly on the home screen card',
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 12.sp,
                  ),
                ),
                value: habitFormProvider.showStats,
                onChanged: (value) => habitFormProvider.setShowStats(value),
                activeColor: AppTheme.primaryColor,
                secondary:
                    !isPro ? const Icon(Icons.lock, color: Colors.amber) : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlarmSection(HabitFormProvider habitFormProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder',
          style: AppTheme.subtitleStyle,
        ),
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCardColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                title: const Text(
                  'Set Reminder Alarm',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  habitFormProvider.hasAlarm ? 'Alarm enabled' : 'No alarm set',
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 12.sp,
                  ),
                ),
                value: habitFormProvider.hasAlarm,
                onChanged: (value) => habitFormProvider.setHasAlarm(value),
                activeColor: AppTheme.primaryColor,
              ),
              if (habitFormProvider.hasAlarm) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: habitFormProvider.alarmTime,
                          );
                          if (picked != null) {
                            habitFormProvider.setAlarmTime(picked);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 16.h, horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: AppTheme.darkBackground,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                habitFormProvider.alarmTime.format(context),
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              const Icon(Icons.access_time,
                                  color: AppTheme.secondaryTextColor),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _buildDismissTypeSelector(habitFormProvider),
                      SizedBox(height: 16.h),
                      _buildSoundSelector(habitFormProvider),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDismissTypeSelector(HabitFormProvider form) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dismiss Method',
          style: AppTheme.subtitleStyle,
        ),
        SizedBox(height: 8.h),
        const Text(
          'How would you like to dismiss the alarm?',
          style: TextStyle(color: AppTheme.secondaryTextColor),
        ),
        SizedBox(height: 16.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDismissOption(
                form: form,
                type: DismissType.swipe,
                icon: Icons.swipe,
                title: 'Swipe',
                color: Colors.orange,
              ),
              _buildDismissOption(
                form: form,
                type: DismissType.math,
                icon: Icons.calculate_outlined,
                title: 'Math Problem',
                color: Colors.orange,
              ),
              _buildDismissOption(
                form: form,
                type: DismissType.typing,
                icon: Icons.keyboard_alt_outlined,
                title: 'Type Text',
                color: Colors.orange,
              ),
              _buildDismissOption(
                form: form,
                type: DismissType.memory,
                icon: Icons.psychology_outlined,
                title: 'Memory Game',
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDismissOption({
    required HabitFormProvider form,
    required DismissType type,
    required IconData icon,
    required String title,
    required Color color,
  }) {
    final isSelected = form.dismissType == type;
    final isPro = Provider.of<SubscriptionProvider>(context).isPro;
    final bool isLocked =
        !isPro && (type == DismissType.typing || type == DismissType.memory);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
          );
        } else {
          form.setDismissType(type);
        }
      },
      child: Stack(
        children: [
          Container(
            width: 100.w, // Slightly smaller
            height: 110.h,
            margin: EdgeInsets.only(right: 12.w),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color:
                  isSelected ? color.withOpacity(0.2) : AppTheme.darkBackground,
              borderRadius: BorderRadius.circular(12.r),
              border: isSelected ? Border.all(color: color, width: 2.w) : null,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? color : AppTheme.secondaryTextColor,
                    size: 28.h,
                  ),
                  SizedBox(height: 8.r),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.textColor
                          : AppTheme.secondaryTextColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLocked)
            Positioned(
              top: 0,
              right: 6.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSoundSelector(HabitFormProvider form) {
    String displaySound =
        form.soundPath.isNotEmpty ? p.basename(form.soundPath) : 'Default';

    // Since HabitFormProvider doesn't EXTEND AlarmFormProvider, we can't pass 'form' directly
    // to AlarmSoundSelectionScreen unless we modify it or wrap/mock it.
    // However, AlarmSoundSelectionScreen uses Consumer<AlarmFormProvider>.
    // This is a problem.
    // I should create a temporary AlarmFormProvider adapter or modify functionality.
    // OR, I can refactor AlarmSoundSelectionScreen to accept a generic interface? No time.
    //
    // Workaround: AlarmSoundSelectionScreen logic is coupled to AlarmFormProvider for state.
    // I will skip proper reusable screen for now and just show a simple list or...
    // Wait, the user wants "sound section under dismiss".

    // I'll make a specialized sound picker or just reuse logic.
    // Actually, `AlarmFormProvider` has `selectedSoundPath` setter.
    // I can instantiate `AlarmFormProvider` with current sound, open screen, and on pop read it back?
    // No, `AlarmSoundSelectionScreen` consumes provider from context.

    // I can wrap `AlarmSoundSelectionScreen` in a `ChangeNotifierProvider<AlarmFormProvider>`.
    // And listen to it.

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.music_note_outlined,
          color: AppTheme.secondaryTextColor),
      title: const Text('Alarm Sound', style: AppTheme.subtitleStyle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(displaySound,
              style: TextStyle(
                  color: AppTheme.secondaryTextColor, fontSize: 16.h)),
          SizedBox(width: 8.w),
          Icon(Icons.arrow_forward_ios,
              size: 16.sp, color: AppTheme.secondaryTextColor),
        ],
      ),
      onTap: () async {
        // Create a temporary AlarmFormProvider to drive the selection screen
        final tempProvider = AlarmFormProvider();
        tempProvider.setSelectedSoundPath(form.soundPath);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: tempProvider,
              child: const AlarmSoundSelectionScreen(),
            ),
          ),
        );

        // When back, update our form
        if (tempProvider.selectedSoundPath != null) {
          form.setSoundPath(tempProvider.selectedSoundPath!);
        }
      },
    );
  }

  String _getFrequencyText(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.monthly:
        return 'Monthly';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }

  Future<void> _saveHabit(
      BuildContext context, HabitFormProvider habitFormProvider) async {
    if (!habitFormProvider.formKey.currentState!.validate()) {
      return;
    }

    if (habitFormProvider.selectedFrequency == HabitFrequency.custom &&
        habitFormProvider.selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day for custom frequency'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check permissions if alarm is enabled
    if (habitFormProvider.hasAlarm) {
      final notificationGranted =
          await PermissionsManager.ensureNotificationPermission(context);
      if (!notificationGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Enable notifications so alarms can ring over the lock screen.',
              ),
            ),
          );
        }
        return;
      }
    }

    try {
      final habitService = context.read<HabitService>();
      final alarmProvider = context.read<AlarmProvider>();

      DateTime? targetTime;
      if (habitFormProvider.hasAlarm) {
        final now = DateTime.now();
        targetTime = DateTime(
          now.year,
          now.month,
          now.day,
          habitFormProvider.alarmTime.hour,
          habitFormProvider.alarmTime.minute,
        );
      }

      HabitModel savedHabit;

      if (widget.habit != null && habitFormProvider.habitId != null) {
        // Update existing habit
        final updatedHabit = widget.habit!;
        updatedHabit.name = habitFormProvider.nameController.text.trim();
        updatedHabit.description =
            habitFormProvider.descriptionController.text.trim().isNotEmpty
                ? habitFormProvider.descriptionController.text.trim()
                : null;
        updatedHabit.frequency = habitFormProvider.selectedFrequency;
        updatedHabit.color = habitFormProvider.selectedColor;
        updatedHabit.icon = habitFormProvider.selectedIcon;
        updatedHabit.hasAlarm = habitFormProvider.hasAlarm;
        updatedHabit.targetTime = targetTime;
        updatedHabit.daysOfWeek = habitFormProvider.selectedDays;
        updatedHabit.showStats = habitFormProvider.showStats;

        await habitService.updateHabit(updatedHabit);
        savedHabit = updatedHabit;
      } else {
        // Create new habit
        print(
            'DEBUG: Creating habit ${habitFormProvider.nameController.text}. Frequency: ${habitFormProvider.selectedFrequency}.');

        final habit = HabitModel(
          name: habitFormProvider.nameController.text.trim(),
          description:
              habitFormProvider.descriptionController.text.trim().isNotEmpty
                  ? habitFormProvider.descriptionController.text.trim()
                  : null,
          frequency: habitFormProvider.selectedFrequency,
          color: habitFormProvider.selectedColor,
          icon: habitFormProvider.selectedIcon,
          hasAlarm: habitFormProvider.hasAlarm,
          targetTime: targetTime,
          daysOfWeek: habitFormProvider.selectedDays,
          showStats: habitFormProvider.showStats,
        );

        await habitService.createHabit(habit);
        savedHabit = habit;
      }

      // Handle Linked Alarm
      if (savedHabit.hasAlarm) {
        // Find existing linked alarm or create new
        AlarmModel? existingAlarm;
        try {
          existingAlarm = alarmProvider.alarms.firstWhere(
            (a) => a.linkedHabitId == savedHabit.id,
          );
        } catch (_) {}

        // Convert frequency to AlarmRepeat and weekdays
        AlarmRepeat alarmRepeat = AlarmRepeat.daily;
        List<bool> alarmWeekdays = List.filled(7, false);

        if (habitFormProvider.selectedFrequency == HabitFrequency.daily) {
          alarmRepeat = AlarmRepeat.daily;
          alarmWeekdays = List.filled(7, true);
        } else if (habitFormProvider.selectedFrequency ==
                HabitFrequency.custom ||
            habitFormProvider.selectedFrequency == HabitFrequency.weekly) {
          alarmRepeat = AlarmRepeat.custom;
          // habit uses 1=Mon, 7=Sun. alarmWeekdays index 0=Mon, 6=Sun.
          for (int day in habitFormProvider.selectedDays) {
            if (day >= 1 && day <= 7) {
              alarmWeekdays[day - 1] = true;
            }
          }
        } else if (habitFormProvider.selectedFrequency ==
            HabitFrequency.monthly) {
          // Alarm doesn't support monthly. Default to daily? Or custom?
          // User likely wants reminder on that day?
          // For now, treat as Daily for simplicity or Custom (all False?? No).
          alarmRepeat = AlarmRepeat.daily; // Fallback
        }

        final newAlarm = AlarmModel(
          id: existingAlarm?.id, // Keep ID if updating
          hour: habitFormProvider.alarmTime.hour,
          minute: habitFormProvider.alarmTime.minute,
          label: savedHabit.name,
          dismissType: habitFormProvider.dismissType,
          soundPath: habitFormProvider.soundPath,
          linkedHabitId: savedHabit.id,
          repeat: alarmRepeat,
          weekdays: alarmWeekdays,
          isEnabled: true,
          vibrate: true, // Default
        );

        if (existingAlarm != null) {
          await alarmProvider.updateAlarm(newAlarm);
        } else {
          await alarmProvider.addAlarm(newAlarm);
        }
      } else {
        // If alarm disabled, remove linked alarm
        try {
          final existingAlarm = alarmProvider.alarms.firstWhere(
            (a) => a.linkedHabitId == savedHabit.id,
          );
          await alarmProvider.deleteAlarm(existingAlarm.id);
        } catch (_) {}
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving habit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving habit: $e')),
        );
      }
    }
  }

  void _showColorPicker(
      BuildContext context, HabitFormProvider habitFormProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Select Color',
            style: TextStyle(color: AppTheme.textColor),
          ),
          content: Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: habitFormProvider.habitColors.map((color) {
              final isSelected = habitFormProvider.selectedColor == color;
              return GestureDetector(
                onTap: () {
                  habitFormProvider.setColor(color);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3.w)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 24.sp)
                      : null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showIconPicker(
      BuildContext context, HabitFormProvider habitFormProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Select Icon',
            style: TextStyle(color: AppTheme.textColor),
          ),
          content: Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: habitFormProvider.habitIcons.map((iconData) {
              final isSelected =
                  habitFormProvider.selectedIcon == iconData['code'];
              return GestureDetector(
                onTap: () {
                  habitFormProvider.setIcon(iconData['code']);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? habitFormProvider.selectedColor.withOpacity(0.2)
                        : AppTheme.darkBackground,
                    borderRadius: BorderRadius.circular(12.r),
                    border: isSelected
                        ? Border.all(
                            color: habitFormProvider.selectedColor, width: 2.w)
                        : null,
                  ),
                  child: Icon(
                    iconData['icon'],
                    color: isSelected
                        ? habitFormProvider.selectedColor
                        : AppTheme.secondaryTextColor,
                    size: 28.sp,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
