import 'package:hive_flutter/hive_flutter.dart';

class FocusSessionModel {
  String id;
  String activity; // "Baca Buku", "Al-Quran", etc
  int durationSeconds; // Total duration
  int elapsedSeconds; // Time elapsed
  DateTime startedAt;
  DateTime? completedAt;
  bool isCompleted;
  String category; // "reading", "prayer", "work", "study"
  bool isPomodoro; // true jika Pomodoro session
  int pomodoroCount; // Berapa siklus Pomodoro sudah selesai
  bool wasCheatDetected; // Anti-fraud: true jika terdeteksi manipulasi waktu

  FocusSessionModel({
    required this.id,
    required this.activity,
    required this.durationSeconds,
    this.elapsedSeconds = 0,
    required this.startedAt,
    this.completedAt,
    this.isCompleted = false,
    required this.category,
    this.isPomodoro = false,
    this.pomodoroCount = 0,
    this.wasCheatDetected = false,
  });
}

class FocusSessionModelAdapter extends TypeAdapter<FocusSessionModel> {
  @override
  final int typeId = 4;

  @override
  FocusSessionModel read(BinaryReader reader) {
    return FocusSessionModel(
      id: reader.readString(),
      activity: reader.readString(),
      durationSeconds: reader.readInt(),
      elapsedSeconds: reader.readInt(),
      startedAt: DateTime.parse(reader.readString()),
      completedAt: reader.readString().isEmpty ? null : DateTime.parse(reader.readString()),
      isCompleted: reader.readBool(),
      category: reader.readString(),
      isPomodoro: reader.readBool(),
      pomodoroCount: reader.readInt(),
      wasCheatDetected: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, FocusSessionModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.activity);
    writer.writeInt(obj.durationSeconds);
    writer.writeInt(obj.elapsedSeconds);
    writer.writeString(obj.startedAt.toIso8601String());
    writer.writeString(obj.completedAt?.toIso8601String() ?? '');
    writer.writeBool(obj.isCompleted);
    writer.writeString(obj.category);
    writer.writeBool(obj.isPomodoro);
    writer.writeInt(obj.pomodoroCount);
    writer.writeBool(obj.wasCheatDetected);
  }
}
