import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

enum GoalStatus { active, completed }

class GoalModel {
  String id;
  String title;
  String targetDescription;
  int coins; // reward saat approved
  int currentProgress; // 0-100
  int targetProgress; // biasanya 100
  GoalStatus status;
  int colorValue;
  DateTime createdAt;
  DateTime? deadline;
  int order;
  String reviewNotes; // catatan dari review (jika ada)
  int? durationMonths; // optional: durasi goal dalam bulan (1, 3, 6) untuk bonus koin
  int completedDays; // jumlah hari user selesaikan semua habits untuk goal ini
  String lastSyncDate; // tanggal terakhir completedDays di-increment (cegah double-count)

  GoalModel({
    required this.id,
    required this.title,
    required this.targetDescription,
    required this.coins,
    this.currentProgress = 0,
    this.targetProgress = 100,
    this.status = GoalStatus.active,
    required this.colorValue,
    required this.createdAt,
    this.deadline,
    required this.order,
    this.reviewNotes = '',
    this.durationMonths,
    this.completedDays = 0,
    this.lastSyncDate = '',
  });

  Color get color => Color(colorValue);

  /// Total hari yang diharapkan dari createdAt ke deadline
  int get totalExpectedDays {
    if (deadline == null) return 0;
    return deadline!.difference(createdAt).inDays.clamp(1, 99999);
  }

  double get progressPercent =>
      targetProgress > 0 ? (currentProgress / targetProgress).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => status == GoalStatus.completed;

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
      targetDescription: fields[2] as String,
      coins: fields[3] as int,
      currentProgress: fields[4] as int? ?? 0,
      targetProgress: fields[5] as int? ?? 100,
      status: GoalStatus.values[fields[6] as int? ?? 0],
      colorValue: fields[7] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[8] as int),
      deadline: fields[9] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[9] as int)
          : null,
      order: fields[10] as int? ?? 0,
      reviewNotes: fields[11] as String? ?? '',
      durationMonths: fields[12] as int?,
      completedDays: fields[13] as int? ?? 0,
      lastSyncDate: fields[14] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, GoalModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.targetDescription)
      ..writeByte(3)
      ..write(obj.coins)
      ..writeByte(4)
      ..write(obj.currentProgress)
      ..writeByte(5)
      ..write(obj.targetProgress)
      ..writeByte(6)
      ..write(obj.status.index)
      ..writeByte(7)
      ..write(obj.colorValue)
      ..writeByte(8)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(9)
      ..write(obj.deadline?.millisecondsSinceEpoch)
      ..writeByte(10)
      ..write(obj.order)
      ..writeByte(11)
      ..write(obj.reviewNotes)
      ..writeByte(12)
      ..write(obj.durationMonths)
      ..writeByte(13)
      ..write(obj.completedDays)
      ..writeByte(14)
      ..write(obj.lastSyncDate);
  }
}
