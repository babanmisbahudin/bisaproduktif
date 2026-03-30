import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/providers/goal_provider.dart';
import '../../../core/utils/app_transition.dart';
import 'goal_detail_screen.dart';

class AddGoalScreen extends StatefulWidget {
  final GoalModel? editGoal;

  const AddGoalScreen({super.key, this.editGoal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _titleController = TextEditingController();
  Color _selectedColor = AppColors.primary;
  DateTime? _selectedDeadline;
  bool _isLoading = false;

  final List<Color> _colorOptions = [
    AppColors.primary,
    AppColors.taskOrange,
    AppColors.taskYellow,
    AppColors.taskGray,
    AppColors.primaryLight,
    AppColors.taskOrangeLight,
    const Color(0xFF7B5EA7),
    const Color(0xFF2196F3),
  ];

  bool get _isEditing => widget.editGoal != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.editGoal!.title;
      _selectedColor = widget.editGoal!.color;
      _selectedDeadline = widget.editGoal!.deadline;
    } else {
      _selectedDeadline =
          DateTime.now().add(const Duration(days: 90)); // default 3 bulan
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ??
          DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDeadline = picked);
  }

  Future<void> _saveGoal() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama goal tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final goalProvider = context.read<GoalProvider>();

      if (_isEditing) {
        await goalProvider.updateGoalTitle(
          goalId: widget.editGoal!.id,
          newTitle: title,
        );
        await goalProvider.updateGoalDeadline(
          goalId: widget.editGoal!.id,
          deadline: _selectedDeadline,
        );
        await goalProvider.updateGoalColor(
          goalId: widget.editGoal!.id,
          color: _selectedColor,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Goal diperbarui')),
          );
        }
      } else {
        await goalProvider.addGoal(
          title: title,
          color: _selectedColor,
          deadline: _selectedDeadline,
        );

        // Langsung buka GoalDetailScreen untuk tambah habit
        final newGoal = goalProvider.goals.last;
        if (mounted) {
          Navigator.pushReplacement(
            context,
            AppTransition.slideRight(
              child: GoalDetailScreen(goal: newGoal),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Goal dibuat! Sekarang tambahkan habit.'),
            ),
          );
        }
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
          _isEditing ? 'Edit Goal' : 'Buat Goal Baru',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama goal
            Text('Nama Goal',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText:
                    'Contoh: Rajin Ibadah, Sehat, Produktif...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Deadline
            Text('Target Selesai',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDeadline != null
                          ? '📅 ${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                          : 'Pilih tanggal',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Warna
            Text('Warna Goal',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedColor = color),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Setelah membuat goal, kamu bisa tambahkan habit yang ingin dikerjakan setiap hari untuk mencapai goal ini.',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        height: 1.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '🪙 Koin dihitung otomatis berdasarkan tingkat kesulitan habit',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                        _isEditing
                            ? 'Update Goal'
                            : 'Buat Goal & Tambah Habit →',
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
