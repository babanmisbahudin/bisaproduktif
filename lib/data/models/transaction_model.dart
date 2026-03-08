import 'package:hive_flutter/hive_flutter.dart';

class TransactionModel {
  String id;
  String userId; // UID dari Firebase Auth
  String userName; // Nama pengguna untuk referensi
  String rewardId;
  String rewardTitle;
  String rewardEmoji;
  int coinsCost;
  DateTime timestamp;
  String status; // 'pending', 'approved', 'rejected'
  String category;
  String? approvedBy; // Email admin yang approve
  DateTime? approvedAt;
  String? rejectionReason;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rewardId,
    required this.rewardTitle,
    required this.rewardEmoji,
    required this.coinsCost,
    required this.timestamp,
    required this.status,
    required this.category,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
  });
}

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 2;

  @override
  TransactionModel read(BinaryReader reader) {
    return TransactionModel(
      id: reader.readString(),
      userId: reader.readString(),
      userName: reader.readString(),
      rewardId: reader.readString(),
      rewardTitle: reader.readString(),
      rewardEmoji: reader.readString(),
      coinsCost: reader.readInt(),
      timestamp: DateTime.parse(reader.readString()),
      status: reader.readString(),
      category: reader.readString(),
      approvedBy: reader.readString().isEmpty ? null : reader.readString(),
      approvedAt: reader.readString().isEmpty ? null : DateTime.parse(reader.readString()),
      rejectionReason: reader.readString().isEmpty ? null : reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.userName);
    writer.writeString(obj.rewardId);
    writer.writeString(obj.rewardTitle);
    writer.writeString(obj.rewardEmoji);
    writer.writeInt(obj.coinsCost);
    writer.writeString(obj.timestamp.toIso8601String());
    writer.writeString(obj.status);
    writer.writeString(obj.category);
    writer.writeString(obj.approvedBy ?? '');
    writer.writeString(obj.approvedAt?.toIso8601String() ?? '');
    writer.writeString(obj.rejectionReason ?? '');
  }
}
