import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/memo_provider.dart';
import '../widgets/memo_card.dart';
import '../widgets/add_memo_modal.dart';

class MemoScreen extends StatefulWidget {
  const MemoScreen({super.key});

  @override
  State<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> {
  String _filterType = 'active'; // 'active' atau 'archived'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          '📝 Memo - Simpan Ide',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Consumer<MemoProvider>(
        builder: (context, memoProvider, _) {
          final filteredMemos = _filterType == 'active'
              ? memoProvider.memos.where((m) => !m.isArchived).toList()
              : memoProvider.memos.where((m) => m.isArchived).toList();

          return Column(
            children: [
              // ── Filter Tabs ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _filterType = 'active'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _filterType == 'active'
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: _filterType == 'active'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Aktif (${memoProvider.memos.where((m) => !m.isArchived).length})',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: _filterType == 'active'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _filterType = 'archived'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _filterType == 'archived'
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: _filterType == 'archived'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Arsip (${memoProvider.memos.where((m) => m.isArchived).length})',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: _filterType == 'archived'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Memo List ──────────────────────────────────────────────
              if (filteredMemos.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _filterType == 'active'
                              ? '📝 Belum ada memo'
                              : '📁 Arsip kosong',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _filterType == 'active'
                              ? 'Buat memo baru untuk menyimpan ide'
                              : 'Memo yang diarsipkan akan muncul di sini',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredMemos.length,
                    itemBuilder: (context, index) {
                      final memo = filteredMemos[index];
                      return MemoCard(
                        memo: memo,
                        onTap: () {
                          _showEditMemoModal(context, memo);
                        },
                        onDelete: () {
                          memoProvider.deleteMemo(memo.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Memo dihapus',
                                style: GoogleFonts.poppins(),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        onArchive: () {
                          if (memo.isArchived) {
                            memoProvider.unarchiveMemo(memo.id);
                          } else {
                            memoProvider.archiveMemo(memo.id);
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMemoModal(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddMemoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddMemoModal(),
    );
  }

  void _showEditMemoModal(BuildContext context, dynamic memo) {
    final textCtrl = TextEditingController(text: memo.content);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Memo',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tulis memo...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(color: AppColors.textSecondary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final memoProvider =
                          context.read<MemoProvider>();
                      if (textCtrl.text.isNotEmpty) {
                        memoProvider.updateMemo(
                          memoId: memo.id,
                          content: textCtrl.text,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Memo diperbarui',
                              style: GoogleFonts.poppins(),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Simpan',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
