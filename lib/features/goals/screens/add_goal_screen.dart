// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/coin_calculator.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/providers/goal_provider.dart';
import '../../../data/providers/habit_provider.dart';
import '../widgets/goal_suggestions_sheet.dart';

class AddGoalScreen extends StatefulWidget {
  final GoalModel? editGoal;

  const AddGoalScreen({super.key, this.editGoal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
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

  /// Koin dihitung otomatis oleh algoritma
  int get _calculatedCoins => CoinCalculator.forGoal(
        _titleController.text.trim(),
        _descController.text.trim(),
        _selectedDeadline,
      );

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.editGoal!.title;
      _descController.text = widget.editGoal!.targetDescription;
      _selectedColor = widget.editGoal!.color;
      _selectedDeadline = widget.editGoal!.deadline;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDeadline = picked);
  }

  Future<void> _save() async {
    final trimmedTitle = _titleController.text.trim();
    final trimmedDesc = _descController.text.trim();
    if (trimmedTitle.isEmpty || trimmedDesc.isEmpty) return;
    setState(() => _isLoading = true);

    final goalProvider = context.read<GoalProvider>();
    final habitProvider = context.read<HabitProvider>();

    if (_isEditing) {
      await goalProvider.editGoal(
        id: widget.editGoal!.id,
        title: trimmedTitle,
        targetDescription: trimmedDesc,
        coins: _calculatedCoins,
        color: _selectedColor,
        deadline: _selectedDeadline,
      );
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    // Add path: run through validator
    final result = await goalProvider.addGoal(
      title: trimmedTitle,
      targetDescription: trimmedDesc,
      coins: _calculatedCoins,
      color: _selectedColor,
      deadline: _selectedDeadline,
      habitProvider: habitProvider,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isValid) {
      // Hard block — show error dialog, stay on screen
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.block_rounded, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(
                'Tidak Bisa Disimpan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            result.warningMessage ?? 'Judul tidak valid.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(
                'Oke',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return; // stay on screen so user can fix title
    }

    if (result.isSuspicious && result.warningMessage != null) {
      // Soft warning — goal was already saved, inform user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ ${result.warningMessage}',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFFFFA500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    Navigator.pop(context);
  }

  void _showSuggestions() {
    final habitProvider = context.read<HabitProvider>();
    final habitTitles = habitProvider.habits.map((h) => h.title).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => GoalSuggestionsSheet(
        habitTitles: habitTitles,
        onSelectGoal: (suggestion) {
          // Auto-fill form dengan suggestion
          setState(() {
            _titleController.text = suggestion.title;
            _descController.text = suggestion.description;
            _selectedColor = suggestion.color;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sheetBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Goal' : 'Tambah Goal',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: Text(
              'Simpan',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview card
            _buildPreviewCard(),
            const SizedBox(height: 24),

            _buildLabel('Judul Goal'),
            const SizedBox(height: 8),
            _buildTextInput(
              controller: _titleController,
              hint: 'Contoh: Baca 10 buku bulan ini',
              maxLength: 80,
            ),
            const SizedBox(height: 20),

            _buildLabel('Deskripsi Target'),
            const SizedBox(height: 8),
            _buildTextInput(
              controller: _descController,
              hint: 'Jelaskan detail target yang ingin dicapai...',
              maxLength: 200,
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            _buildLabel('Deadline (Opsional)'),
            const SizedBox(height: 8),
            _buildDeadlinePicker(),
            const SizedBox(height: 24),

            // Reward koin otomatis (info only — update saat judul/deadline berubah)
            _buildCoinInfo(),
            const SizedBox(height: 24),

            // Pilih warna
            _buildLabel('Warna Kartu'),
            const SizedBox(height: 8),
            _buildColorPicker(),
            const SizedBox(height: 24),

            // Tombol lihat suggestions
            if (!_isEditing) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.lightbulb_outline),
                  onPressed: _showSuggestions,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  label: Text(
                    '💡 Lihat Suggestions',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Goal'),
              ),
            ),

            if (_isEditing &&
                widget.editGoal!.status == GoalStatus.active) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _confirmDelete,
                  child: Text(
                    'Hapus Goal',
                    style: GoogleFonts.poppins(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final title = _titleController.text.isEmpty
        ? 'Judul goal kamu...'
        : _titleController.text;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _selectedColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha:
                        _titleController.text.isEmpty ? 0.6 : 1.0),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$_calculatedCoins',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.0,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '0% selesai',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  /// Panel info reward koin otomatis — update live
  Widget _buildCoinInfo() {
    final cat = CoinCalculator.goalCategory(
      _titleController.text.trim(),
      _descController.text.trim(),
      _selectedDeadline,
    );
    final coins = cat.coins;

    // Warna aksen berdasarkan besaran koin
    Color accent;
    if (coins >= 1000) {
      accent = Colors.amber.shade700;
    } else if (coins >= 600) {
      accent = Colors.orange.shade600;
    } else if (coins >= 400) {
      accent = Colors.blue.shade600;
    } else if (coins >= 250) {
      accent = Colors.teal.shade500;
    } else {
      accent = AppColors.primary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reward otomatis: $coins koin',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: accent,
                    fontSize: 14,
                  ),
                ),
                Text(
                  cat.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: accent.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message:
                'Koin ditentukan otomatis berdasarkan kategori goal & durasi deadline',
            child:
                Icon(Icons.info_outline, color: accent.withValues(alpha: 0.5), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    int maxLength = 100,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        style:
            GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
        maxLines: maxLines,
        minLines: 1,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        maxLength: maxLength,
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
            null,
      ),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _colorOptions.map((color) {
        final isSelected = _selectedColor.toARGB32() == color.toARGB32();
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: isSelected ? 12 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeadlinePicker() {
    final hasDeadline = _selectedDeadline != null;
    return GestureDetector(
      onTap: _pickDeadline,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color:
                  hasDeadline ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              hasDeadline
                  ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                  : 'Pilih deadline (opsional)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: hasDeadline
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            if (hasDeadline)
              GestureDetector(
                onTap: () => setState(() => _selectedDeadline = null),
                child: const Icon(Icons.close,
                    size: 18, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Goal?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Goal "${widget.editGoal!.title}" akan dihapus permanen.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          // Horizontal aligned buttons dengan equal width
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final dialogCtx = ctx;
                    final stateContext = context;
                    final provider = stateContext.read<GoalProvider>();
                    await provider.deleteGoal(widget.editGoal!.id);
                    if (!mounted) return;
                    Navigator.pop(dialogCtx);
                    if (mounted) {
                      Navigator.pop(stateContext);
                    }
                  },
                  child: Text(
                    'Hapus',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
