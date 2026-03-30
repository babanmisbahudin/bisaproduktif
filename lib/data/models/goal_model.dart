import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

enum GoalStatus { active, completed }

class GoalModel {
  String id;
  String title;
  List<String> linkedHabitIds; // habit yang di-lock ke goal ini
  int coins;                   // bonus koin saat goal selesai (50 fixed)
  GoalStatus status;
  int colorValue;
  DateTime createdAt;
  DateTime? deadline;
  int order;
  double progressPercent;      // diupdate oleh GoalProvider saat habit dicentang

  GoalModel({
    required this.id,
    required this.title,
    List<String>? linkedHabitIds,
    required this.coins,
    this.status = GoalStatus.active,
    required this.colorValue,
    required this.createdAt,
    this.deadline,
    required this.order,
    this.progressPercent = 0.0,
  }) : linkedHabitIds = linkedHabitIds ?? [];

  Color get color => Color(colorValue);

  bool get isCompleted => status == GoalStatus.completed;

  int get linkedCount => linkedHabitIds.length;

  /// Sisa hari menuju deadline
  int get daysLeft {
    if (deadline == null) return 0;
    final diff = deadline!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  String get statusLabel {
    switch (status) {
      case GoalStatus.active:    return 'Aktif';
      case GoalStatus.completed: return 'Selesai';
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

    // Field 2: dulu List<GoalTask>, sekarang List<String>
    // Baca dengan try-catch untuk migrasi data lama
    List<String> linkedHabitIds = [];
    try {
      linkedHabitIds = (fields[2] as List?)?.cast<String>() ?? [];
    } catch (_) {
      linkedHabitIds = []; // data lama (List<GoalTask>) diabaikan
    }

    return GoalModel(
      id: fields[0] as String,
      title: fields[1] as String,
      linkedHabitIds: linkedHabitIds,
      coins: fields[3] as int,
      status: GoalStatus.values[fields[4] as int? ?? 0],
      colorValue: fields[5] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
      deadline: fields[7] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[7] as int)
          : null,
      order: fields[8] as int? ?? 0,
      progressPercent: (fields[9] as double?) ?? 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, GoalModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.linkedHabitIds)
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
      ..write(obj.order)
      ..writeByte(9)
      ..write(obj.progressPercent);
  }
}
