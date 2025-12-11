import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/services/habit_service.dart';
import 'package:upnow/services/habit_alarm_service.dart';
import 'package:upnow/providers/habit_form_provider.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/gradient_button.dart';

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
      create: (_) => HabitFormProvider(initialHabit: widget.habit),
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
          child: SwitchListTile(
            title: const Text(
              'Set Reminder',
              style: TextStyle(
                color: AppTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              habitFormProvider.hasAlarm
                  ? 'Daily reminder enabled'
                  : 'No reminder set',
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontSize: 12.sp,
              ),
            ),
            value: habitFormProvider.hasAlarm,
            onChanged: (value) => habitFormProvider.setHasAlarm(value),
            activeColor: AppTheme.primaryColor,
          ),
        ),
        if (habitFormProvider.hasAlarm) ...[
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () => habitFormProvider.selectTime(context),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.darkCardColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reminder Time',
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 16.sp,
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      habitFormProvider.alarmTime.format(context),
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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

    try {
      final habitService = context.read<HabitService>();

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

        await habitService.updateHabit(updatedHabit);

        // Update alarm if needed
        if (habitFormProvider.hasAlarm) {
          await HabitAlarmService.scheduleHabitAlarm(updatedHabit);
        } else {
          await HabitAlarmService.cancelHabitAlarm(updatedHabit.id);
        }
      } else {
        // Create new habit
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
        );

        await habitService.createHabit(habit);

        // Schedule alarm if enabled
        if (habitFormProvider.hasAlarm) {
          await HabitAlarmService.scheduleHabitAlarm(habit);
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving habit: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
