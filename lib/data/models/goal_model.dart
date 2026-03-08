import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

enum GoalStatus { active, sentForReview, completed, approved }

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
  });

  Color get color => Color(colorValue);

  double get progressPercent =>
      targetProgress > 0 ? (currentProgress / targetProgress).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => status == GoalStatus.completed || status == GoalStatus.approved;
  bool get isSentForReview => status == GoalStatus.sentForReview;
  bool get isApproved => status == GoalStatus.approved;

  String get statusLabel {
    switch (status) {
      case GoalStatus.active:
        return 'Aktif';
      case GoalStatus.sentForReview:
        return 'Menunggu Review';
      case GoalStatus.completed:
        return 'Selesai';
      case GoalStatus.approved:
        return 'Disetujui';
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
    );
  }

  @override
  void write(BinaryWriter writer, GoalModel obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.reviewNotes);
  }
}
