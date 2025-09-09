import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upnow/models/habit_model.dart';
import 'package:upnow/services/habit_service.dart';
import 'package:upnow/services/habit_alarm_service.dart';
import 'package:upnow/providers/habit_form_provider.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({Key? key}) : super(key: key);

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HabitFormProvider(),
      child: Consumer<HabitFormProvider>(
        builder: (context, habitFormProvider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Add New Habit'),
              backgroundColor: habitFormProvider.selectedColor,
              foregroundColor: Colors.white,
              actions: [
                TextButton(
                  onPressed: () => _saveHabit(context, habitFormProvider),
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
            body: SafeArea(
              child: Form(
                key: habitFormProvider.formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(habitFormProvider),
                      const SizedBox(height: 24),
                      _buildFrequencySection(habitFormProvider),
                      const SizedBox(height: 24),
                      _buildCustomizationSection(habitFormProvider),
                      const SizedBox(height: 24),
                      _buildAlarmSection(habitFormProvider),
                      const SizedBox(height: 32),
                      _buildSaveButton(habitFormProvider),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoSection(HabitFormProvider habitFormProvider) {
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
              controller: habitFormProvider.nameController,
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
              controller: habitFormProvider.descriptionController,
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

  Widget _buildFrequencySection(HabitFormProvider habitFormProvider) {
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
                final isSelected = habitFormProvider.selectedFrequency == frequency;
                return ChoiceChip(
                  label: Text(_getFrequencyText(frequency)),
                  selected: isSelected,
                  onSelected: (selected) {
                    habitFormProvider.setFrequency(frequency);
                  },
                  selectedColor: habitFormProvider.selectedColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? habitFormProvider.selectedColor : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                );
              }).toList(),
            ),
            if (habitFormProvider.selectedFrequency == HabitFrequency.custom) ...[
              const SizedBox(height: 16),
              const Text(
                'Select Days:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildDaySelector(habitFormProvider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector(HabitFormProvider habitFormProvider) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        final dayNumber = index + 1;
        final isSelected = habitFormProvider.selectedDays.contains(dayNumber);
        
        return FilterChip(
          label: Text(days[index]),
          selected: isSelected,
          onSelected: (selected) {
            habitFormProvider.toggleDay(dayNumber);
          },
          selectedColor: habitFormProvider.selectedColor.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? habitFormProvider.selectedColor : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        );
      }),
    );
  }

  Widget _buildCustomizationSection(HabitFormProvider habitFormProvider) {
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
              children: habitFormProvider.habitColors.map((color) {
                final isSelected = habitFormProvider.selectedColor == color;
                return GestureDetector(
                  onTap: () => habitFormProvider.setColor(color),
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
              children: habitFormProvider.habitIcons.map((iconData) {
                final isSelected = habitFormProvider.selectedIcon == iconData['code'];
                return GestureDetector(
                  onTap: () => habitFormProvider.setIcon(iconData['code']),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? habitFormProvider.selectedColor.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected 
                        ? Border.all(color: habitFormProvider.selectedColor, width: 2)
                        : Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          iconData['icon'],
                          color: isSelected ? habitFormProvider.selectedColor : Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          iconData['name'],
                          style: TextStyle(
                            fontSize: 8,
                            color: isSelected ? habitFormProvider.selectedColor : Colors.grey[600],
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

  Widget _buildAlarmSection(HabitFormProvider habitFormProvider) {
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
                habitFormProvider.hasAlarm 
                  ? 'Daily reminder at ${habitFormProvider.alarmTime.format(context)}'
                  : 'No reminder set',
              ),
              value: habitFormProvider.hasAlarm,
              onChanged: (value) {
                habitFormProvider.setHasAlarm(value);
              },
              activeColor: habitFormProvider.selectedColor,
            ),
            if (habitFormProvider.hasAlarm) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Reminder Time'),
                subtitle: Text(habitFormProvider.alarmTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () => habitFormProvider.selectTime(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(HabitFormProvider habitFormProvider) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _saveHabit(context, habitFormProvider),
        icon: const Icon(Icons.save),
        label: const Text(
          'Create Habit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: habitFormProvider.selectedColor,
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

  Future<void> _saveHabit(BuildContext context, HabitFormProvider habitFormProvider) async {
    if (!habitFormProvider.formKey.currentState!.validate()) {
      return;
    }

    if (habitFormProvider.selectedFrequency == HabitFrequency.custom && habitFormProvider.selectedDays.isEmpty) {
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

      final habit = HabitModel(
        name: habitFormProvider.nameController.text.trim(),
        description: habitFormProvider.descriptionController.text.trim().isNotEmpty 
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

      if (context.mounted) {
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