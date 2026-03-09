import 'package:hive_flutter/hive_flutter.dart';

class MemoModel {
  String id;
  String content; // Text content
  String? voiceFilePath; // Path ke audio file (optional)
  DateTime createdAt;
  DateTime updatedAt;
  bool isArchived;

  MemoModel({
    required this.id,
    required this.content,
    this.voiceFilePath,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
  });
}

class MemoModelAdapter extends TypeAdapter<MemoModel> {
  @override
  final int typeId = 3;

  @override
  MemoModel read(BinaryReader reader) {
    return MemoModel(
      id: reader.readString(),
      content: reader.readString(),
      voiceFilePath: reader.readString().isEmpty ? null : reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
      updatedAt: DateTime.parse(reader.readString()),
      isArchived: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, MemoModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.content);
    writer.writeString(obj.voiceFilePath ?? '');
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
    writer.writeBool(obj.isArchived);
  }
}
