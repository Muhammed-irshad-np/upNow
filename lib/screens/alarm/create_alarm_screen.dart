import 'package:flutter/material.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/services/alarm_service.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/gradient_button.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/alarm_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;

class CreateAlarmScreen extends StatefulWidget {
  final AlarmModel? alarm; // If null, we're creating a new alarm
  
  const CreateAlarmScreen({Key? key, this.alarm}) : super(key: key);

  @override
  _CreateAlarmScreenState createState() => _CreateAlarmScreenState();
}

class _CreateAlarmScreenState extends State<CreateAlarmScreen> {
  late TimeOfDay _selectedTime;
  late String _label;
  late DismissType _dismissType;
  late AlarmRepeat _repeat;
  late List<bool> _weekdays;
  late bool _vibrate;
  late String? _selectedSoundPath;
  
  final TextEditingController _labelController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<String> _availableSounds = [
    'assets/sounds/stardust.mp3',
    'assets/sounds/simplified.mp3',
    'assets/sounds/lofi.mp3',
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.alarm != null) {
      _selectedTime = TimeOfDay(hour: widget.alarm!.hour, minute: widget.alarm!.minute);
      _label = widget.alarm!.label;
      _dismissType = widget.alarm!.dismissType;
      _repeat = widget.alarm!.repeat;
      _weekdays = List.from(widget.alarm!.weekdays);
      _vibrate = widget.alarm!.vibrate;
      _selectedSoundPath = widget.alarm!.soundPath;
    } else {
      final now = TimeOfDay.now();
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
      _label = 'Alarm';
      _dismissType = DismissType.math;
      _repeat = AlarmRepeat.once;
      _weekdays = List.filled(7, false);
      _vibrate = true;
      _selectedSoundPath = _availableSounds.isNotEmpty ? _availableSounds[0] : null;
    }
    
    _labelController.text = _label;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(widget.alarm == null ? 'Add Alarm' : 'Edit Alarm'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeSelector(),
            const SizedBox(height: 24),
            _buildLabelInput(),
            const SizedBox(height: 24),
            _buildDismissTypeSelector(),
            const SizedBox(height: 24),
            _buildRepeatSelector(),
            if (_repeat == AlarmRepeat.custom) 
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildWeekdaySelector(),
              ),
            const SizedBox(height: 24),
            _buildSoundSelector(),
            const SizedBox(height: 24),
            _buildVibrationOption(),
            const SizedBox(height: 36),
            GradientButton(
              text: 'Save Alarm',
              onPressed: _saveAlarm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    // Convert 24-hour format to 12-hour format for display only
    final int displayHour = _selectedTime.hour > 12 ? _selectedTime.hour - 12 : _selectedTime.hour == 0 ? 12 : _selectedTime.hour;
    final String amPm = _selectedTime.hour >= 12 ? 'PM' : 'AM';
    
    return Center(
      child: GestureDetector(
        onTap: _showTimePicker,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppTheme.darkCardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$displayHour:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amPm,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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

  Widget _buildLabelInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Label',
          style: AppTheme.subtitleStyle,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _labelController,
          style: const TextStyle(color: AppTheme.textColor),
          decoration: InputDecoration(
            hintText: 'Alarm label',
            hintStyle: TextStyle(color: AppTheme.secondaryTextColor.withOpacity(0.5)),
            filled: true,
            fillColor: AppTheme.darkCardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.label_outline, color: AppTheme.secondaryTextColor),
          ),
          onChanged: (value) {
            setState(() {
              _label = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDismissTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dismiss Method',
          style: AppTheme.subtitleStyle,
        ),
        const SizedBox(height: 8),
        const Text(
          'How would you like to dismiss the alarm?',
          style: TextStyle(color: AppTheme.secondaryTextColor),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDismissOption(
                type: DismissType.math,
                icon: Icons.calculate_outlined,
                title: 'Math Problem',
                color: Colors.orange,
              ),
              _buildDismissOption(
                type: DismissType.typing,
                icon: Icons.keyboard_alt_outlined,
                title: 'Type Text',
                color: Colors.green,
              ),
              _buildDismissOption(
                type: DismissType.shake,
                icon: Icons.vibration,
                title: 'Shake Phone',
                color: Colors.purple,
              ),
              _buildDismissOption(
                type: DismissType.memory,
                icon: Icons.psychology_outlined,
                title: 'Memory Game',
                color: Colors.blue,
              ),
              _buildDismissOption(
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
    required DismissType type,
    required IconData icon,
    required String title,
    required Color color,
  }) {
    final isSelected = _dismissType == type;
    final bool isComingSoon = type != DismissType.math && type != DismissType.normal;
    // Create a global key for the tooltip
    final GlobalKey tooltipKey = GlobalKey();
    
    Widget optionWidget = Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.2) : AppTheme.darkCardColor,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: color, width: 2) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? color : AppTheme.secondaryTextColor,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppTheme.textColor : AppTheme.secondaryTextColor,
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
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'SOON',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
      
      // Wrap with tooltip
      optionWidget = Tooltip(
        key: tooltipKey,
        message: '$title is coming soon!',
        preferBelow: true,
        showDuration: const Duration(seconds: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white),
        triggerMode: TooltipTriggerMode.longPress, // Show on long press by default
        child: optionWidget,
      );
    }
    
    return GestureDetector(
      onTap: () {
        if (isComingSoon) {
          // Show a custom dialog instead of trying to force tooltip
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Coming Soon!'),
                content: Text('$title feature will be available in a future update.'),
                backgroundColor: AppTheme.darkCardColor,
                titleTextStyle: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                contentTextStyle: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                    style: TextButton.styleFrom(
                      foregroundColor: color,
                    ),
                  ),
                ],
              );
            },
          );
          // Don't change the selected option
        } else {
          setState(() {
            _dismissType = type;
          });
        }
      },
      child: optionWidget,
    );
  }

  Widget _buildRepeatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repeat',
          style: AppTheme.subtitleStyle,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            _buildRepeatOption(AlarmRepeat.once, 'Once'),
            _buildRepeatOption(AlarmRepeat.daily, 'Every Day'),
            _buildRepeatOption(AlarmRepeat.weekdays, 'Weekdays'),
            _buildRepeatOption(AlarmRepeat.weekends, 'Weekends'),
            _buildRepeatOption(AlarmRepeat.custom, 'Custom'),
          ],
        ),
      ],
    );
  }

  Widget _buildRepeatOption(AlarmRepeat repeat, String label) {
    final isSelected = _repeat == repeat;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _repeat = repeat;
        });
      },
      child: Chip(
        backgroundColor: isSelected ? AppTheme.primaryColor : AppTheme.darkCardColor,
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

  Widget _buildWeekdaySelector() {
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            return _buildDayToggle(index, dayLabels[index]);
          }),
        ),
      ],
    );
  }

  Widget _buildDayToggle(int dayIndex, String label) {
    final isSelected = _weekdays[dayIndex];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _weekdays[dayIndex] = !_weekdays[dayIndex];
        });
      },
      child: Container(
        width: 40,
        height: 40,
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

  Widget _buildSoundSelector() {
    String displaySound = _selectedSoundPath != null && _selectedSoundPath!.isNotEmpty
        ? p.basename(_selectedSoundPath!)
        : 'Default'; 

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.music_note_outlined, color: AppTheme.secondaryTextColor),
      title: const Text('Sound', style: AppTheme.subtitleStyle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
             displaySound,
             style: const TextStyle(color: AppTheme.secondaryTextColor, fontSize: 16)
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.secondaryTextColor),
        ],
      ),
      onTap: _showSoundSelectionDialog,
    );
  }

  void _showSoundSelectionDialog() {
    // Store the initially selected path to manage temporary selection in the dialog
    String? tempSelectedPath = _selectedSoundPath; 

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
              titleTextStyle: const TextStyle(color: AppTheme.textColor, fontSize: 20, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              children: [
                // Map sounds to dialog options
                ..._availableSounds.map((soundPath) {
                  final fileName = p.basename(soundPath);
                  // Check if this sound is the one temporarily selected in the dialog
                  final isTemporarilySelected = tempSelectedPath == soundPath; 

                  return SimpleDialogOption(
                    onPressed: () async {
                      String relativePath = ''; // Declare outside try
                      try {
                        await _audioPlayer.stop(); // Stop previous sound
                        await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the sound until user decides
                        relativePath = soundPath.replaceFirst('assets/', ''); // Assign inside try
                        debugPrint('Previewing sound: $relativePath'); 
                        await _audioPlayer.play(AssetSource(relativePath)); // Play preview
                        
                        // Update the temporary selection within the dialog ONLY
                        dialogSetState(() { 
                          tempSelectedPath = soundPath;
                        });

                      } catch (e, stackTrace) { // Add stackTrace here
                        print("Error playing sound preview for path: $soundPath");
                        // Now relativePath is accessible here
                        print("Relative path attempted: $relativePath"); 
                        print("ERROR DETAILS: $e"); // Log the error
                        print("STACK TRACE: $stackTrace"); // Log the full stack trace
                      }
                      // DO NOT pop navigator here
                      // DO NOT set the main screen state here
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fileName,
                          style: TextStyle(
                            // Highlight the temporarily selected item
                            color: isTemporarilySelected ? Theme.of(context).primaryColor : AppTheme.textColor, 
                            fontSize: 16,
                            fontWeight: isTemporarilySelected ? FontWeight.bold : FontWeight.normal,
                          )
                        ),
                        if (isTemporarilySelected) // Show check only for temporary selection
                          Icon(Icons.music_note, color: Theme.of(context).primaryColor, size: 20),
                        // Optional: Show a different indicator for the *originally* selected sound
                        // else if (_selectedSoundPath == soundPath) 
                        //   Icon(Icons.check_circle_outline, color: AppTheme.secondaryTextColor, size: 20),
                      ],
                    ),
                  );
                }).toList(),
                
                // Add Cancel and OK buttons
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, right: 16.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text('Cancel', style: TextStyle(color: AppTheme.secondaryTextColor)),
                        onPressed: () async {
                          await _audioPlayer.stop(); // Stop preview on cancel
                          Navigator.pop(context); // Close dialog
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        child: Text('OK', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                           await _audioPlayer.stop(); // Stop preview on OK
                           // Update the main screen state with the temporary selection
                           setState(() {
                             _selectedSoundPath = tempSelectedPath;
                           });
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

  Widget _buildVibrationOption() {
    return SwitchListTile(
      title: const Text(
        'Vibrate',
        style: TextStyle(
          color: AppTheme.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: _vibrate,
      activeColor: AppTheme.primaryColor,
      onChanged: (value) {
        setState(() {
          _vibrate = value;
        });
      },
      tileColor: AppTheme.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Future<void> _showTimePicker() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (BuildContext context, Widget? child) {
        // Wrap with MediaQuery to use 12-hour format
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.primaryColor,
                onSurface: AppTheme.textColor,
              ),
              timePickerTheme: TimePickerThemeData(
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _saveAlarm() async {
    if (_label.isEmpty) {
      _label = 'Alarm';
    }
    
    // Ensure we're using a supported dismiss type
    if (_dismissType != DismissType.math && _dismissType != DismissType.normal) {
      // Force to math problem as other types aren't implemented yet
      _dismissType = DismissType.math;
    }
    
    final alarm = widget.alarm != null
        ? widget.alarm!
        : AlarmModel(
            hour: _selectedTime.hour,
            minute: _selectedTime.minute,
          );
    
    alarm.hour = _selectedTime.hour;
    alarm.minute = _selectedTime.minute;
    alarm.label = _label;
    alarm.dismissType = _dismissType;
    alarm.repeat = _repeat;
    alarm.weekdays = _weekdays;
    alarm.vibrate = _vibrate;
    alarm.soundPath = _selectedSoundPath ?? '';
    
    debugPrint('Setting alarm for ${_selectedTime.hour}:${_selectedTime.minute} (${alarm.hour}:${alarm.minute})');
    
    final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
    if (widget.alarm != null) {
      await alarmProvider.updateAlarm(alarm);
    } else {
      await alarmProvider.addAlarm(alarm);
    }
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }
} 