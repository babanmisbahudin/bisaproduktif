import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/goal_provider.dart';
import '../../../data/models/goal_model.dart';

class AddTaskScreen extends StatefulWidget {
  final GoalModel goal;

  const AddTaskScreen({super.key, required this.goal});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _taskNameCtrl = TextEditingController();
  final _coinsCtrl = TextEditingController(text: '10');
  bool _isLoading = false;

  @override
  void dispose() {
    _taskNameCtrl.dispose();
    _coinsCtrl.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final taskName = _taskNameCtrl.text.trim();
    final coins = int.tryParse(_coinsCtrl.text) ?? 10;

    if (taskName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kegiatan tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<GoalProvider>().addTaskToGoal(
            goalId: widget.goal.id,
            taskName: taskName,
            coins: coins,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ "$taskName" ditambahkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tambah Kegiatan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: widget.goal.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal title
            Text(
              'Goal: ${widget.goal.title}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Task name input
            Text(
              'Nama Kegiatan',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskNameCtrl,
              decoration: InputDecoration(
                hintText: 'Contoh: Sholat Subuh, Ngaji, Olahraga...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Coins reward
            Text(
              'Koin Reward',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _coinsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '10',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Koin yang diberikan saat kegiatan ini selesai',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.goal.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Tambah Kegiatan',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
