import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 10)
enum HabitFrequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  custom
}

@HiveType(typeId: 11)
enum HabitIntensity {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high
}

@HiveType(typeId: 12)
class HabitModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  HabitFrequency frequency;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? targetTime; // For alarm functionality

  @HiveField(6)
  Color color;

  @HiveField(7)
  String? icon;

  @HiveField(8)
  bool isActive;

  @HiveField(9)
  int targetCount; // How many times per frequency period

  @HiveField(10)
  List<int> daysOfWeek; // For weekly habits (1-7, Monday=1)

  @HiveField(11)
  bool hasAlarm;

  @HiveField(12)
  bool isArchived;

  @HiveField(13)
  Map<String, dynamic>? metadata; // For additional data

  @HiveField(14)
  bool showStats;

  HabitModel({
    String? id,
    required this.name,
    this.description,
    this.frequency = HabitFrequency.daily,
    DateTime? createdAt,
    this.targetTime,
    this.color = Colors.blue,
    this.icon,
    this.isActive = true,
    this.targetCount = 1,
    List<int>? daysOfWeek,
    this.hasAlarm = false,
    this.isArchived = false,
    this.metadata,
    this.showStats = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        daysOfWeek = daysOfWeek ?? [1, 2, 3, 4, 5, 6, 7];

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'frequency': frequency.index,
        'createdAt': createdAt.toIso8601String(),
        'targetTime': targetTime?.toIso8601String(),
        'color': color.value,
        'icon': icon,
        'isActive': isActive,
        'targetCount': targetCount,
        'daysOfWeek': daysOfWeek,
        'hasAlarm': hasAlarm,
        'isArchived': isArchived,
        'metadata': metadata,
        'showStats': showStats,
      };

  factory HabitModel.fromJson(Map<String, dynamic> json) => HabitModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        frequency: HabitFrequency.values[json['frequency'] ?? 0],
        createdAt: DateTime.parse(json['createdAt']),
        targetTime: json['targetTime'] != null
            ? DateTime.parse(json['targetTime'])
            : null,
        color: Color(json['color'] ?? Colors.blue.value),
        icon: json['icon'],
        isActive: json['isActive'] ?? true,
        targetCount: json['targetCount'] ?? 1,
        daysOfWeek: List<int>.from(json['daysOfWeek'] ?? [1, 2, 3, 4, 5, 6, 7]),
        hasAlarm: json['hasAlarm'] ?? false,
        isArchived: json['isArchived'] ?? false,
        metadata: json['metadata'],
        showStats: json['showStats'] ?? false,
      );

  HabitModel copyWith({
    String? name,
    String? description,
    HabitFrequency? frequency,
    DateTime? targetTime,
    Color? color,
    String? icon,
    bool? isActive,
    int? targetCount,
    List<int>? daysOfWeek,
    bool? hasAlarm,
    bool? isArchived,
    Map<String, dynamic>? metadata,
    bool? showStats,
  }) {
    return HabitModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt,
      targetTime: targetTime ?? this.targetTime,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      targetCount: targetCount ?? this.targetCount,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      isArchived: isArchived ?? this.isArchived,
      metadata: metadata ?? this.metadata,
      showStats: showStats ?? this.showStats,
    );
  }
}

@HiveType(typeId: 13)
class HabitEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String habitId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final bool completed;

  @HiveField(4)
  final int completionCount; // For habits that can be done multiple times

  @HiveField(5)
  final DateTime? completedAt;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final HabitIntensity? intensity;

  @HiveField(8)
  final Map<String, dynamic>? metadata;

  HabitEntry({
    String? id,
    required this.habitId,
    required this.date,
    this.completed = false,
    this.completionCount = 0,
    this.completedAt,
    this.notes,
    this.intensity,
    this.metadata,
  }) : id = id ?? const Uuid().v4();

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'date': date.toIso8601String(),
        'completed': completed,
        'completionCount': completionCount,
        'completedAt': completedAt?.toIso8601String(),
        'notes': notes,
        'intensity': intensity?.index,
        'metadata': metadata,
      };

  factory HabitEntry.fromJson(Map<String, dynamic> json) => HabitEntry(
        id: json['id'],
        habitId: json['habitId'],
        date: DateTime.parse(json['date']),
        completed: json['completed'] ?? false,
        completionCount: json['completionCount'] ?? 0,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
        notes: json['notes'],
        intensity: json['intensity'] != null
            ? HabitIntensity.values[json['intensity']]
            : null,
        metadata: json['metadata'],
      );

  HabitEntry copyWith({
    String? habitId,
    DateTime? date,
    bool? completed,
    int? completionCount,
    DateTime? completedAt,
    String? notes,
    HabitIntensity? intensity,
    Map<String, dynamic>? metadata,
  }) {
    return HabitEntry(
      id: id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      completionCount: completionCount ?? this.completionCount,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      intensity: intensity ?? this.intensity,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get date without time for comparison
  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
