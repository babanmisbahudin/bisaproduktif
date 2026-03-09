import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/memo_model.dart';

class MemoProvider extends ChangeNotifier {
  static const String _boxName = 'memos';

  late Box<MemoModel> _box;
  List<MemoModel> _memos = [];
  bool _isLoaded = false;

  List<MemoModel> get memos => List.unmodifiable(_memos.where((m) => !m.isArchived));
  List<MemoModel> get archivedMemos => List.unmodifiable(_memos.where((m) => m.isArchived));
  bool get isLoaded => _isLoaded;
  int get memoCount => memos.length;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _box = await Hive.openBox<MemoModel>(_boxName);
    _loadMemos();
    _isLoaded = true;
    notifyListeners();
  }

  void _loadMemos() {
    _memos = _box.values.toList();
    _memos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  /// Tambah memo baru (text + optional voice)
  Future<void> addMemo({
    required String content,
    String? voiceFilePath,
  }) async {
    final memo = MemoModel(
      id: const Uuid().v4(),
      content: content.trim(),
      voiceFilePath: voiceFilePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isArchived: false,
    );

    await _box.put(memo.id, memo);
    _memos.add(memo);
    _sortMemos();
    notifyListeners();
  }

  /// Update memo
  Future<void> updateMemo({
    required String memoId,
    required String content,
    String? voiceFilePath,
  }) async {
    final memo = _memos.firstWhere((m) => m.id == memoId);
    memo.content = content.trim();
    if (voiceFilePath != null) memo.voiceFilePath = voiceFilePath;
    memo.updatedAt = DateTime.now();

    await _box.put(memoId, memo);
    _sortMemos();
    notifyListeners();
  }

  /// Archive memo
  Future<void> archiveMemo(String memoId) async {
    final memo = _memos.firstWhere((m) => m.id == memoId);
    memo.isArchived = true;
    memo.updatedAt = DateTime.now();

    await _box.put(memoId, memo);
    notifyListeners();
  }

  /// Unarchive memo
  Future<void> unarchiveMemo(String memoId) async {
    final memo = _memos.firstWhere((m) => m.id == memoId);
    memo.isArchived = false;
    memo.updatedAt = DateTime.now();

    await _box.put(memoId, memo);
    notifyListeners();
  }

  /// Delete memo permanently
  Future<void> deleteMemo(String memoId) async {
    await _box.delete(memoId);
    _memos.removeWhere((m) => m.id == memoId);
    notifyListeners();
  }

  void _sortMemos() {
    _memos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Clear semua memo saat logout
  Future<void> clearUserData() async {
    _memos.clear();
    await _box.clear();
    notifyListeners();
  }
}
