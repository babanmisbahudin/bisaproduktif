import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'goal_task_model.dart';

enum GoalStatus { active, completed }

class GoalModel {
  String id;
  String title; // "Meningkatkan Iman", "Sehat", dll
  List<GoalTask> tasks; // List of kegiatan/activities
  int coins; // reward saat goal selesai (semua task done)
  GoalStatus status;
  int colorValue;
  DateTime createdAt;
  DateTime? deadline;
  int order;

  GoalModel({
    required this.id,
    required this.title,
    this.tasks = const [],
    required this.coins,
    this.status = GoalStatus.active,
    required this.colorValue,
    required this.createdAt,
    this.deadline,
    required this.order,
  });

  Color get color => Color(colorValue);

  /// Progress: completed tasks / total tasks
  double get progressPercent {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.completed).length;
    return (completed / tasks.length).clamp(0.0, 1.0);
  }

  int get completedTasks => tasks.where((t) => t.completed).length;
  int get totalTasks => tasks.length;

  bool get isCompleted => status == GoalStatus.completed || (tasks.isNotEmpty && completedTasks == totalTasks);

  String get statusLabel {
    switch (status) {
      case GoalStatus.active:
        return 'Aktif';
      case GoalStatus.completed:
        return 'Selesai';
    }
  }
}

// Manual Hive Adapter — tanpa code generation
class GoalModelAdapter extends TypeAdapter<GoalModel> {
  @override
  final int typeId = 1;

  @override
  GoalModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return GoalModel(
      id: fields[0] as String,
      title: fields[1] as String,
      tasks: (fields[2] as List?)?.cast<GoalTask>() ?? [],
      coins: fields[3] as int,
      status: GoalStatus.values[fields[4] as int? ?? 0],
      colorValue: fields[5] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
      deadline: fields[7] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[7] as int)
          : null,
      order: fields[8] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, GoalModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.tasks)
      ..writeByte(3)
      ..write(obj.coins)
      ..writeByte(4)
      ..write(obj.status.index)
      ..writeByte(5)
      ..write(obj.colorValue)
      ..writeByte(6)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(7)
      ..write(obj.deadline?.millisecondsSinceEpoch)
      ..writeByte(8)
      ..write(obj.order);
  }
}
