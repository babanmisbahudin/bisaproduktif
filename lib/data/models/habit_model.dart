import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

enum HabitCategory { ringan, sedang, berat, sangatBerat }

extension HabitCategoryExt on HabitCategory {
  String get label {
    switch (this) {
      case HabitCategory.ringan:     return 'Ringan';
      case HabitCategory.sedang:     return 'Sedang';
      case HabitCategory.berat:      return 'Berat';
      case HabitCategory.sangatBerat: return 'Sangat Berat';
    }
  }

  int get baseCoins {
    switch (this) {
      case HabitCategory.ringan:     return 3;
      case HabitCategory.sedang:     return 5;
      case HabitCategory.berat:      return 10;
      case HabitCategory.sangatBerat: return 15;
    }
  }

  String get emoji {
    switch (this) {
      case HabitCategory.ringan:     return '🌱';
      case HabitCategory.sedang:     return '⚡';
      case HabitCategory.berat:      return '🔥';
      case HabitCategory.sangatBerat: return '💎';
    }
  }
}

class HabitModel {
  String id;
  String title;
  int coins;
  bool isCompletedToday;
  String lastCompletedDate; // format: yyyy-MM-dd
  int streak;
  int colorValue;
  DateTime createdAt;
  int order;
  // Untuk anti-fraud: simpan timestamp penyelesaian
  List<String> completionTimestamps; // max 30 hari terakhir
  String? goalId; // null = habit bebas, ada nilai = terkunci ke goal ini
  int? durationDays;
  HabitCategory category; // menentukan koin per hari

  HabitModel({
    required this.id,
    required this.title,
    required this.coins,
    this.isCompletedToday = false,
    this.lastCompletedDate = '',
    this.streak = 0,
    required this.colorValue,
    required this.createdAt,
    required this.order,
    List<String>? completionTimestamps,
    this.goalId,
    this.durationDays,
    this.category = HabitCategory.sedang,
  }) : completionTimestamps = completionTimestamps ?? [];

  Color get color => Color(colorValue);

  String get todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool get isCompletedOnDate {
    return lastCompletedDate == todayKey;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'coins': coins,
      'isCompletedToday': isCompletedToday,
      'lastCompletedDate': lastCompletedDate,
      'streak': streak,
      'colorValue': colorValue,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'order': order,
      'completionTimestamps': completionTimestamps,
      'goalId': goalId,
      'durationDays': durationDays,
      'category': category.index,
    };
  }

  factory HabitModel.fromMap(Map<dynamic, dynamic> map) {
    return HabitModel(
      id: map['id'] as String,
      title: map['title'] as String,
      coins: map['coins'] as int,
      isCompletedToday: map['isCompletedToday'] as bool? ?? false,
      lastCompletedDate: map['lastCompletedDate'] as String? ?? '',
      streak: map['streak'] as int? ?? 0,
      colorValue: map['colorValue'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      order: map['order'] as int? ?? 0,
      completionTimestamps:
          (map['completionTimestamps'] as List?)?.cast<String>() ?? [],
      goalId: map['goalId'] as String?,
      durationDays: map['durationDays'] as int?,
      category: HabitCategory.values[map['category'] as int? ?? 1],
    );
  }
}

// Manual Hive Adapter — tanpa code generation
class HabitModelAdapter extends TypeAdapter<HabitModel> {
  @override
  final int typeId = 0;

  @override
  HabitModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return HabitModel(
      id: fields[0] as String,
      title: fields[1] as String,
      coins: fields[2] as int,
      isCompletedToday: fields[3] as bool? ?? false,
      lastCompletedDate: fields[4] as String? ?? '',
      streak: fields[5] as int? ?? 0,
      colorValue: fields[6] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[7] as int),
      order: fields[8] as int? ?? 0,
      completionTimestamps:
          (fields[9] as List?)?.cast<String>() ?? [],
      goalId: fields[10] as String?,
      durationDays: fields[11] as int?,
      category: HabitCategory.values[fields[12] as int? ?? 1],
    );
  }

  @override
  void write(BinaryWriter writer, HabitModel obj) {
    writer
      ..writeByte(13) // jumlah field
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.coins)
      ..writeByte(3)
      ..write(obj.isCompletedToday)
      ..writeByte(4)
      ..write(obj.lastCompletedDate)
      ..writeByte(5)
      ..write(obj.streak)
      ..writeByte(6)
      ..write(obj.colorValue)
      ..writeByte(7)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(8)
      ..write(obj.order)
      ..writeByte(9)
      ..write(obj.completionTimestamps)
      ..writeByte(10)
      ..write(obj.goalId)
      ..writeByte(11)
      ..write(obj.durationDays)
      ..writeByte(12)
      ..write(obj.category.index);
  }
}
