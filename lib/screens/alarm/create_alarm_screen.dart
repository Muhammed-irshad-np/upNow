import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/providers/settings_provider.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/gradient_button.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/alarm_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:upnow/providers/alarm_form_provider.dart';
import 'package:upnow/utils/global_error_handler.dart';
import 'package:upnow/services/permissions_manager.dart';

class CreateAlarmScreen extends StatefulWidget {
  final AlarmModel? alarm; // If null, we're creating a new alarm

  const CreateAlarmScreen({Key? key, this.alarm}) : super(key: key);

  @override
  _CreateAlarmScreenState createState() => _CreateAlarmScreenState();
}

class _CreateAlarmScreenState extends State<CreateAlarmScreen> {
  final TextEditingController _labelController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AlarmFormProvider(initial: widget.alarm),
      child: Consumer<AlarmFormProvider>(builder: (context, form, _) {
        _labelController.value = _labelController.value.copyWith(
          text: form.label,
          selection: TextSelection.collapsed(offset: form.label.length),
        );
        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          appBar: AppBar(
            title: Text(widget.alarm == null ? 'Add Alarm' : 'Edit Alarm'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimeSelector(form),
                        SizedBox(height: 24.h),
                        _buildLabelInput(form),
                        SizedBox(height: 24.h),
                        _buildDismissTypeSelector(form),
                        SizedBox(height: 24.h),
                        _buildRepeatSelector(form),
                        if (form.repeat == AlarmRepeat.custom)
                          Padding(
                            padding: EdgeInsets.only(top: 16.h),
                            child: _buildWeekdaySelector(form),
                          ),
                        SizedBox(height: 24.h),
                        _buildSoundSelector(form),
                        SizedBox(height: 24.h),
                        _buildVibrationOption(form),
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
                    text: 'Save Alarm',
                    onPressed: () => _saveAlarm(context, form),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimeSelector(AlarmFormProvider form) {
    final settings = Provider.of<SettingsProvider>(context);

    // Create a DateTime object for formatting
    final time =
        DateTime(2023, 1, 1, form.selectedTime.hour, form.selectedTime.minute);
    final formattedTime = settings.is24HourFormat
        ? DateFormat.Hm().format(time) // HH:mm
        : DateFormat.jm().format(time); // h:mm a

    return Center(
      child: InkWell(
        onTap: () => _showTimePicker(context, form),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 24.h),
          decoration: BoxDecoration(
            color: AppTheme.darkCardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 60.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              SizedBox(height: 8.h),
              const Text(
                'Tap to change',
                style: TextStyle(
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelInput(AlarmFormProvider form) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Label',
          style: AppTheme.subtitleStyle,
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _labelController,
          style: const TextStyle(color: AppTheme.textColor),
          decoration: InputDecoration(
            hintText: 'Alarm label',
            hintStyle:
                TextStyle(color: AppTheme.secondaryTextColor.withOpacity(0.5)),
            filled: true,
            fillColor: AppTheme.darkCardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.label_outline,
                color: AppTheme.secondaryTextColor),
          ),
          onChanged: (value) => form.setLabel(value),
        ),
      ],
    );
  }

  Widget _buildDismissTypeSelector(AlarmFormProvider form) {
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
                color: Colors.green,
              ),
              _buildDismissOption(
                form: form,
                type: DismissType.shake,
                icon: Icons.vibration,
                title: 'Shake Phone',
                color: Colors.purple,
              ),
              _buildDismissOption(
                form: form,
                type: DismissType.memory,
                icon: Icons.psychology_outlined,
                title: 'Memory Game',
                color: Colors.blue,
              ),
              _buildDismissOption(
                form: form,
                type: DismissType.barcode,
                icon: Icons.qr_code_scanner,
                title: 'Scan Barcode',
                color: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDismissOption({
    required AlarmFormProvider form,
    required DismissType type,
    required IconData icon,
    required String title,
    required Color color,
  }) {
    final isSelected = form.dismissType == type;
    final bool isComingSoon =
        type != DismissType.math && type != DismissType.normal;

    Widget optionWidget = Container(
      width: 110.w,
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.2) : AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: isSelected ? Border.all(color: color, width: 2.w) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? color : AppTheme.secondaryTextColor,
            size: 32.h,
          ),
          SizedBox(height: 8.r),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  isSelected ? AppTheme.textColor : AppTheme.secondaryTextColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );

    // Wrap with stack to show the "SOON" label if needed
    if (isComingSoon) {
      optionWidget = Stack(
        children: [
          optionWidget,
          Positioned(
            top: 0,
            right: 12.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'SOON',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        if (isComingSoon) {
          // Show tooltip using overlay
          _showTooltip(context, '$title is coming soon!');
          // Don't change the selected option
        } else {
          form.setDismissType(type);
        }
      },
      child: optionWidget,
    );
  }

  Widget _buildRepeatSelector(AlarmFormProvider form) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repeat',
          style: AppTheme.subtitleStyle,
        ),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 8,
          children: [
            _buildRepeatOption(form, AlarmRepeat.once, 'Once'),
            _buildRepeatOption(form, AlarmRepeat.daily, 'Every Day'),
            _buildRepeatOption(form, AlarmRepeat.weekdays, 'Weekdays'),
            _buildRepeatOption(form, AlarmRepeat.weekends, 'Weekends'),
            _buildRepeatOption(form, AlarmRepeat.custom, 'Custom'),
          ],
        ),
      ],
    );
  }

  Widget _buildRepeatOption(
      AlarmFormProvider form, AlarmRepeat repeat, String label) {
    final isSelected = form.repeat == repeat;

    return GestureDetector(
      onTap: () => form.setRepeat(repeat),
      child: Chip(
        backgroundColor:
            isSelected ? AppTheme.primaryColor : AppTheme.darkCardColor,
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.secondaryTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdaySelector(AlarmFormProvider form) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Days',
          style: TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            return _buildDayToggle(form, index, dayLabels[index]);
          }),
        ),
      ],
    );
  }

  Widget _buildDayToggle(AlarmFormProvider form, int dayIndex, String label) {
    final isSelected = form.weekdays[dayIndex];

    return GestureDetector(
      onTap: () => form.toggleWeekday(dayIndex),
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppTheme.primaryColor : AppTheme.darkCardColor,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.secondaryTextColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoundSelector(AlarmFormProvider form) {
    String displaySound =
        form.selectedSoundPath != null && form.selectedSoundPath!.isNotEmpty
            ? p.basename(form.selectedSoundPath!)
            : 'Default';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.music_note_outlined,
          color: AppTheme.secondaryTextColor),
      title: const Text('Sound', style: AppTheme.subtitleStyle),
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
      onTap: () => _showSoundSelectionDialog(context, form),
    );
  }

  void _showSoundSelectionDialog(BuildContext context, AlarmFormProvider form) {
    // Store the initially selected path to manage temporary selection in the dialog
    String? tempSelectedPath = form.selectedSoundPath;

    showDialog(
      context: context,
      // Prevent dialog dismissal by tapping outside
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Use StatefulBuilder to manage state within the dialog
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return SimpleDialog(
              title: const Text('Select Alarm Sound'),
              backgroundColor: AppTheme.darkCardColor,
              titleTextStyle: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              children: [
                // Map sounds to dialog options
                ...form.availableSounds.map((soundPath) {
                  final fileName = p.basename(soundPath);
                  // Check if this sound is the one temporarily selected in the dialog
                  final isTemporarilySelected = tempSelectedPath == soundPath;

                  return SimpleDialogOption(
                    onPressed: () async {
                      String relativePath = ''; // Declare outside try
                      try {
                        await form.stopPreview(); // Stop previous sound
                        relativePath = soundPath.replaceFirst(
                            'assets/', ''); // Assign inside try
                        debugPrint('Previewing sound: $relativePath');
                        await form.previewSound(soundPath); // Play preview

                        // Update the temporary selection within the dialog ONLY
                        dialogSetState(() {
                          tempSelectedPath = soundPath;
                        });
                      } catch (e, stackTrace) {
                        // Add stackTrace here
                        GlobalErrorHandler.onException(e, stackTrace);
                      }
                      // DO NOT pop navigator here
                      // DO NOT set the main screen state here
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(fileName,
                            style: TextStyle(
                              // Highlight the temporarily selected item
                              color: isTemporarilySelected
                                  ? Theme.of(context).primaryColor
                                  : AppTheme.textColor,
                              fontSize: 16.sp,
                              fontWeight: isTemporarilySelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            )),
                        if (isTemporarilySelected) // Show check only for temporary selection
                          Icon(Icons.music_note,
                              color: Theme.of(context).primaryColor,
                              size: 20.h),
                        // Optional: Show a different indicator for the *originally* selected sound
                        // else if (_selectedSoundPath == soundPath)
                        //   Icon(Icons.check_circle_outline, color: AppTheme.secondaryTextColor, size: 20),
                      ],
                    ),
                  );
                }).toList(),

                // Add Cancel and OK buttons
                Padding(
                  padding: EdgeInsets.only(
                      top: 16.0.h, right: 16.0.w, bottom: 8.0.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text('Cancel',
                            style:
                                TextStyle(color: AppTheme.secondaryTextColor)),
                        onPressed: () async {
                          await form.stopPreview(); // Stop preview on cancel
                          Navigator.pop(context); // Close dialog
                        },
                      ),
                      SizedBox(width: 8.w),
                      TextButton(
                        child: Text('OK',
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          await form.stopPreview(); // Stop preview on OK
                          form.setSelectedSoundPath(tempSelectedPath);
                          Navigator.pop(context); // Close dialog
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ); // Removed .then() as stopping is handled by buttons now
  }

  Widget _buildVibrationOption(AlarmFormProvider form) {
    return SwitchListTile(
      title: const Text(
        'Vibrate',
        style: TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: form.vibrate,
      activeColor: AppTheme.primaryColor,
      onChanged: (value) => form.setVibrate(value),
      tileColor: AppTheme.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }

  Widget _buildMorningAlarmOption(AlarmFormProvider form) {
    return SwitchListTile(
      title: const Text(
        'Morning Wake-Up Alarm',
        style: TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Set as your daily wake-up alarm',
        style: TextStyle(
          color: AppTheme.secondaryTextColor,
          fontSize: 12.sp,
        ),
      ),
      value: form.isMorningAlarm,
      activeColor: Colors.orange,
      onChanged: (value) => form.setMorningAlarm(value),
      tileColor: AppTheme.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }

  Future<void> _showTimePicker(
      BuildContext context, AlarmFormProvider form) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: form.selectedTime,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (BuildContext context, Widget? child) {
        // Wrap with MediaQuery to use 12-hour format
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppTheme.primaryColor,
                onSurface: AppTheme.textColor,
              ),
              timePickerTheme: TimePickerThemeData(
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (pickedTime != null) {
      form.setSelectedTime(pickedTime);
    }
  }

  Future<void> _saveAlarm(BuildContext context, AlarmFormProvider form) async {
    try {
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

      // Permission granted, proceed to save alarm
      final alarm = form.buildOrUpdate(widget.alarm);
      final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
      if (widget.alarm != null) {
        await alarmProvider.updateAlarm(alarm);
      } else {
        await alarmProvider.addAlarm(alarm);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e, s) {
      await GlobalErrorHandler.onException(e, s);
    }
  }

  // Overlay-specific dialogs removed; notification permissions are now handled via PermissionsManager.

  void _showTooltip(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height *
            0.3, // Show in middle of screen
        left: MediaQuery.of(context).size.width * 0.1,
        right: MediaQuery.of(context).size.width * 0.1,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppTheme.darkCardColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}
