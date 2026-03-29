import 'package:hive_flutter/hive_flutter.dart';

class GoalTask {
  String id;
  String name; // "Sholat Subuh", "Ngaji", dll
  bool completed;
  int coins; // reward saat task selesai
  DateTime createdAt;
  DateTime? completedAt;

  GoalTask({
    required this.id,
    required this.name,
    this.completed = false,
    required this.coins,
    required this.createdAt,
    this.completedAt,
  });
}

// Manual Hive Adapter untuk GoalTask
class GoalTaskAdapter extends TypeAdapter<GoalTask> {
  @override
  final int typeId = 5; // typeId 5 untuk GoalTask

  @override
  GoalTask read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return GoalTask(
      id: fields[0] as String,
      name: fields[1] as String,
      completed: fields[2] as bool? ?? false,
      coins: fields[3] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      completedAt: fields[5] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[5] as int)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, GoalTask obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.completed)
      ..writeByte(3)
      ..write(obj.coins)
      ..writeByte(4)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.completedAt?.millisecondsSinceEpoch);
  }
}
