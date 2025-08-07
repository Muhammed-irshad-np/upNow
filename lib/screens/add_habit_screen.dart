import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/services/habit_service.dart';
import 'package:upnow/services/habit_alarm_service.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({Key? key}) : super(key: key);

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  Color _selectedColor = Colors.blue;
  String? _selectedIcon;
  bool _hasAlarm = false;
  TimeOfDay _alarmTime = TimeOfDay.now();
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // All days by default
  
  final List<Color> _habitColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  final List<Map<String, dynamic>> _habitIcons = [
    {'icon': Icons.fitness_center, 'code': '0xe3a7', 'name': 'Fitness'},
    {'icon': Icons.book, 'code': '0xe0bb', 'name': 'Reading'},
    {'icon': Icons.water_drop, 'code': '0xe798', 'name': 'Water'},
    {'icon': Icons.bedtime, 'code': '0xe3e4', 'name': 'Sleep'},
    {'icon': Icons.self_improvement, 'code': '0xe4ba', 'name': 'Meditation'},
    {'icon': Icons.restaurant, 'code': '0xe57a', 'name': 'Diet'},
    {'icon': Icons.directions_run, 'code': '0xe566', 'name': 'Running'},
    {'icon': Icons.psychology, 'code': '0xe4cd', 'name': 'Learning'},
    {'icon': Icons.music_note, 'code': '0xe405', 'name': 'Music'},
    {'icon': Icons.brush, 'code': '0xe3a9', 'name': 'Art'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Habit'),
        backgroundColor: _selectedColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveHabit,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildFrequencySection(),
              const SizedBox(height: 24),
              _buildCustomizationSection(),
              const SizedBox(height: 24),
              _buildAlarmSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Habit Name *',
                hintText: 'e.g., Drink 8 glasses of water',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a habit name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add more details about this habit...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: HabitFrequency.values.map((frequency) {
                final isSelected = _selectedFrequency == frequency;
                return ChoiceChip(
                  label: Text(_getFrequencyText(frequency)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFrequency = frequency;
                    });
                  },
                  selectedColor: _selectedColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? _selectedColor : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                );
              }).toList(),
            ),
            if (_selectedFrequency == HabitFrequency.custom) ...[
              const SizedBox(height: 16),
              const Text(
                'Select Days:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildDaySelector(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        final dayNumber = index + 1;
        final isSelected = _selectedDays.contains(dayNumber);
        
        return FilterChip(
          label: Text(days[index]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(dayNumber);
              } else {
                _selectedDays.remove(dayNumber);
              }
            });
          },
          selectedColor: _selectedColor.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? _selectedColor : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        );
      }),
    );
  }

  Widget _buildCustomizationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customization',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Color Theme:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _habitColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected 
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                    ),
                    child: isSelected 
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Icon:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _habitIcons.map((iconData) {
                final isSelected = _selectedIcon == iconData['code'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconData['code']),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? _selectedColor.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected 
                        ? Border.all(color: _selectedColor, width: 2)
                        : Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          iconData['icon'],
                          color: isSelected ? _selectedColor : Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          iconData['name'],
                          style: TextStyle(
                            fontSize: 8,
                            color: isSelected ? _selectedColor : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reminder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Set Reminder'),
              subtitle: Text(
                _hasAlarm 
                  ? 'Daily reminder at ${_alarmTime.format(context)}'
                  : 'No reminder set',
              ),
              value: _hasAlarm,
              onChanged: (value) {
                setState(() {
                  _hasAlarm = value;
                });
              },
              activeColor: _selectedColor,
            ),
            if (_hasAlarm) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Reminder Time'),
                subtitle: Text(_alarmTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: _selectTime,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _saveHabit,
        icon: const Icon(Icons.save),
        label: const Text(
          'Create Habit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime,
    );
    
    if (picked != null && picked != _alarmTime) {
      setState(() {
        _alarmTime = picked;
      });
    }
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFrequency == HabitFrequency.custom && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day for custom frequency'),
        ),
      );
      return;
    }

    try {
      final habitService = context.read<HabitService>();
      
      DateTime? targetTime;
      if (_hasAlarm) {
        final now = DateTime.now();
        targetTime = DateTime(
          now.year,
          now.month,
          now.day,
          _alarmTime.hour,
          _alarmTime.minute,
        );
      }

      final habit = HabitModel(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
        frequency: _selectedFrequency,
        color: _selectedColor,
        icon: _selectedIcon,
        hasAlarm: _hasAlarm,
        targetTime: targetTime,
        daysOfWeek: _selectedDays,
      );

      await habitService.createHabit(habit);

      // Schedule alarm if enabled
      if (_hasAlarm) {
        await HabitAlarmService.scheduleHabitAlarm(habit);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Habit "${habit.name}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating habit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}