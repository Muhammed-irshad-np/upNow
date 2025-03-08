import 'package:flutter/material.dart';
import 'package:upnow/models/alarm_model.dart';
import 'package:upnow/services/alarm_service.dart';
import 'package:upnow/utils/app_theme.dart';
import 'package:upnow/widgets/gradient_button.dart';
import 'package:provider/provider.dart';
import 'package:upnow/providers/alarm_provider.dart';

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
  
  final TextEditingController _labelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing alarm data or defaults
    if (widget.alarm != null) {
      _selectedTime = TimeOfDay(hour: widget.alarm!.hour, minute: widget.alarm!.minute);
      _label = widget.alarm!.label;
      _dismissType = widget.alarm!.dismissType;
      _repeat = widget.alarm!.repeat;
      _weekdays = List.from(widget.alarm!.weekdays);
      _vibrate = widget.alarm!.vibrate;
    } else {
      // Set defaults for new alarm
      final now = TimeOfDay.now();
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
      _label = 'Alarm';
      _dismissType = DismissType.math;
      _repeat = AlarmRepeat.once;
      _weekdays = List.filled(7, false);
      _vibrate = true;
    }
    
    _labelController.text = _label;
  }

  @override
  void dispose() {
    _labelController.dispose();
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
              Text(
                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
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
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _dismissType = type;
        });
      },
      child: Container(
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
      ),
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
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
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
    
    // Create or update alarm
    final alarm = widget.alarm != null
        ? widget.alarm!
        : AlarmModel(
            hour: _selectedTime.hour,
            minute: _selectedTime.minute,
          );
    
    // Update properties
    alarm.hour = _selectedTime.hour;
    alarm.minute = _selectedTime.minute;
    alarm.label = _label;
    alarm.dismissType = _dismissType;
    alarm.repeat = _repeat;
    alarm.weekdays = _weekdays;
    alarm.vibrate = _vibrate;
    
    // Debug: Log the alarm time being set
    debugPrint('Setting alarm for ${_selectedTime.hour}:${_selectedTime.minute} (${alarm.hour}:${alarm.minute})');
    
    // Get the AlarmProvider and save the alarm
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