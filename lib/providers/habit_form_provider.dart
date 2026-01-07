import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:upnow/models/habit_model.dart';

class HabitFormProvider with ChangeNotifier {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  Color _selectedColor = Colors.blue;
  String? _selectedIcon;
  bool _hasAlarm = false;
  bool _showStats = false;
  TimeOfDay _alarmTime = TimeOfDay.now();
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // All days by default
  String? _habitId; // Store habit ID for editing

  // Constructor with optional initial habit data
  HabitFormProvider({HabitModel? initialHabit}) {
    if (initialHabit != null) {
      _habitId = initialHabit.id;
      _nameController.text = initialHabit.name;
      _descriptionController.text = initialHabit.description ?? '';
      _selectedFrequency = initialHabit.frequency;
      _selectedColor = initialHabit.color;
      _selectedIcon = initialHabit.icon;
      _hasAlarm = initialHabit.hasAlarm;
      _showStats = initialHabit.showStats;
      if (initialHabit.targetTime != null) {
        _alarmTime = TimeOfDay(
          hour: initialHabit.targetTime!.hour,
          minute: initialHabit.targetTime!.minute,
        );
      }
      _selectedDays = List<int>.from(initialHabit.daysOfWeek);
    }
  }

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
    {'icon': Icons.star, 'code': '0xe5f9', 'name': 'Default'},
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

  // Getters
  GlobalKey<FormState> get formKey => _formKey;
  TextEditingController get nameController => _nameController;
  TextEditingController get descriptionController => _descriptionController;
  HabitFrequency get selectedFrequency => _selectedFrequency;
  Color get selectedColor => _selectedColor;
  String? get selectedIcon => _selectedIcon;
  bool get hasAlarm => _hasAlarm;
  bool get showStats => _showStats;
  TimeOfDay get alarmTime => _alarmTime;
  List<int> get selectedDays => _selectedDays;
  List<Color> get habitColors => _habitColors;
  List<Map<String, dynamic>> get habitIcons => _habitIcons;
  String? get habitId => _habitId; // Getter for habit ID

  // Setters
  void setSelectedFrequency(HabitFrequency frequency) {
    _selectedFrequency = frequency;
    notifyListeners();
  }

  void setFrequency(HabitFrequency frequency) {
    _selectedFrequency = frequency;
    notifyListeners();
  }

  void setSelectedColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }

  void setColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }

  void setSelectedIcon(String? iconCode) {
    _selectedIcon = iconCode;
    notifyListeners();
  }

  void setIcon(String? iconCode) {
    _selectedIcon = iconCode;
    notifyListeners();
  }

  void setHasAlarm(bool hasAlarm) {
    _hasAlarm = hasAlarm;
    notifyListeners();
  }

  void setShowStats(bool value) {
    _showStats = value;
    notifyListeners();
  }

  void setAlarmTime(TimeOfDay time) {
    _alarmTime = time;
    notifyListeners();
  }

  Future<void> selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime,
    );

    if (picked != null && picked != _alarmTime) {
      _alarmTime = picked;
      notifyListeners();
    }
  }

  void toggleDay(int dayNumber) {
    if (_selectedDays.contains(dayNumber)) {
      _selectedDays.remove(dayNumber);
    } else {
      _selectedDays.add(dayNumber);
    }
    notifyListeners();
  }

  void addDay(int dayNumber) {
    if (!_selectedDays.contains(dayNumber)) {
      _selectedDays.add(dayNumber);
      notifyListeners();
    }
  }

  void removeDay(int dayNumber) {
    if (_selectedDays.contains(dayNumber)) {
      _selectedDays.remove(dayNumber);
      notifyListeners();
    }
  }

  void resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _selectedFrequency = HabitFrequency.daily;
    _selectedColor = Colors.blue;
    _selectedIcon = null;
    _hasAlarm = false;
    _showStats = false;
    _alarmTime = TimeOfDay.now();
    _selectedDays = [1, 2, 3, 4, 5, 6, 7];
    notifyListeners();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
