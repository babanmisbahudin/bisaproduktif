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
  // Status: 'pending' → 'diproses' → 'dikirim' (final)
  //                   ↘ 'ditolak' (final, coins refunded)
  String status;
  String category;
  String? approvedBy; // Email admin yang menangani
  DateTime? approvedAt; // Waktu update status terakhir
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
    // Baca ke variabel lokal dulu agar setiap field hanya di-read SATU kali.
    // Pattern: `reader.readString().isEmpty ? null : value` membaca DUA kali
    // dan menggeser posisi reader — ini menyebabkan data korup.
    final id           = reader.readString();
    final userId       = reader.readString();
    final userName     = reader.readString();
    final rewardId     = reader.readString();
    final rewardTitle  = reader.readString();
    final rewardEmoji  = reader.readString();
    final coinsCost    = reader.readInt();
    final timestamp    = DateTime.parse(reader.readString());
    final status       = reader.readString();
    final category     = reader.readString();
    final approvedByRaw      = reader.readString();
    final approvedAtRaw      = reader.readString();
    final rejectionReasonRaw = reader.readString();

    return TransactionModel(
      id: id,
      userId: userId,
      userName: userName,
      rewardId: rewardId,
      rewardTitle: rewardTitle,
      rewardEmoji: rewardEmoji,
      coinsCost: coinsCost,
      timestamp: timestamp,
      status: status,
      category: category,
      approvedBy:      approvedByRaw.isEmpty      ? null : approvedByRaw,
      approvedAt:      approvedAtRaw.isEmpty      ? null : DateTime.parse(approvedAtRaw),
      rejectionReason: rejectionReasonRaw.isEmpty ? null : rejectionReasonRaw,
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
