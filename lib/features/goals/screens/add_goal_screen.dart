import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/providers/goal_provider.dart';

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
      // Default deadline 1 tahun dari sekarang
      _selectedDeadline = DateTime.now().add(const Duration(days: 365));
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
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 tahun
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
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
        // Update goal (edit mode)
        await goalProvider.updateGoalTitle(
              goalId: widget.editGoal!.id,
              newTitle: title,
            );
        if (_selectedDeadline != null) {
          await goalProvider.updateGoalDeadline(
                goalId: widget.editGoal!.id,
                deadline: _selectedDeadline,
              );
        }
      } else {
        // Add new goal
        await goalProvider.addGoal(
              title: title,
              coins: 50, // Fixed reward untuk goal selesai
              color: _selectedColor,
              deadline: _selectedDeadline,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? '✅ Goal diperbarui' : '✅ Goal dibuat',
            ),
          ),
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
          _isEditing ? 'Edit Goal' : 'Buat Goal Baru',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal title input
            Text(
              'Nama Goal',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Contoh: Meningkatkan Iman, Sehat, Produktif...',
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

            // Deadline picker
            Text(
              'Target Selesai',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Color picker
            Text(
              'Warna Goal',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
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
            const SizedBox(height: 32),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Setelah membuat goal, Anda bisa menambahkan kegiatan/tasks untuk goal ini',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '✓ Reward: 50 koin saat semua kegiatan selesai',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Goal' : 'Buat Goal',
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
