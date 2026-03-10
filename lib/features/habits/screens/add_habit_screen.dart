import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/coin_calculator.dart';
import '../../../data/models/habit_model.dart';
import '../../../data/providers/habit_provider.dart';

class AddHabitScreen extends StatefulWidget {
  final HabitModel? editHabit; // null = tambah baru

  const AddHabitScreen({super.key, this.editHabit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _titleController = TextEditingController();
  Color _selectedColor = AppColors.taskOrange;
  bool _isLoading = false;
  int _selectedCategoryIndex = -1;

  final List<Color> _colorOptions = [
    AppColors.taskOrange,
    AppColors.taskOrangeLight,
    AppColors.taskYellow,
    AppColors.taskGray,
    AppColors.primary,
    AppColors.primaryLight,
    const Color(0xFF7B5EA7),
    const Color(0xFF2196F3),
  ];

  bool get _isEditing => widget.editHabit != null;

  /// Koin dihitung otomatis oleh algoritma
  int get _calculatedCoins =>
      CoinCalculator.forHabit(_titleController.text.trim());

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.editHabit!.title;
      _selectedColor = widget.editHabit!.color;
    } else {
      // Listen to title changes untuk auto-detect kategori
      _titleController.addListener(_autoDetectCategory);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_autoDetectCategory);
    _titleController.dispose();
    super.dispose();
  }

  /// Auto-detect kategori berdasarkan judul yang diketik
  void _autoDetectCategory() {
    final title = _titleController.text.toLowerCase();
    if (title.isEmpty) {
      setState(() => _selectedCategoryIndex = -1);
      return;
    }

    // Cek setiap kategori untuk match keywords
    for (int i = 0; i < _habitCategories.length; i++) {
      final cat = _habitCategories[i];
      for (final suggestion in cat.suggestions) {
        if (suggestion.toLowerCase().contains(title) ||
            title.contains(suggestion.toLowerCase())) {
          setState(() => _selectedCategoryIndex = i);
          return;
        }
      }
    }

    // Jika tidak ada match di suggestions, cek dengan CoinCalculator keywords
    final category = CoinCalculator.habitCategory(title);

    // Map kategori coins ke index
    if (category.label.contains('Fisik')) {
      setState(() => _selectedCategoryIndex = 2); // Olahraga
    } else if (category.label.contains('Mindfulness')) {
      setState(() => _selectedCategoryIndex = 0); // Ibadah (spiritual)
    } else if (category.label.contains('Produktif')) {
      setState(() => _selectedCategoryIndex = 1); // Bekerja
    } else if (category.label.contains('Rumah')) {
      setState(() => _selectedCategoryIndex = 3); // Kebersihan (or similar)
    } else if (category.label.contains('Kesehatan')) {
      setState(() => _selectedCategoryIndex = 4); // Kesehatan
    } else if (category.label.contains('Relasi')) {
      setState(() => _selectedCategoryIndex = 5); // Sosial
    } else {
      setState(() => _selectedCategoryIndex = -1);
    }
  }

  Future<void> _save() async {
    final trimmed = _titleController.text.trim();
    if (trimmed.isEmpty) return;
    setState(() => _isLoading = true);

    final provider = context.read<HabitProvider>();
    if (_isEditing) {
      await provider.editHabit(
        id: widget.editHabit!.id,
        title: trimmed,
        coins: _calculatedCoins,
        color: _selectedColor,
      );
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    // Add path: run through validator
    final result = await provider.addHabit(
      title: trimmed,
      coins: _calculatedCoins,
      color: _selectedColor,
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
      // Soft warning — habit was already saved, inform user
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
          _isEditing ? 'Edit Habit' : 'Tambah Habit',
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

            // Judul habit
            _buildLabel('Nama Habit'),
            const SizedBox(height: 8),
            _buildTitleInput(),
            const SizedBox(height: 16),

            // Reward koin otomatis (info only)
            _buildCoinInfo(),
            const SizedBox(height: 24),

            // Category chips (hanya untuk add, bukan edit) — otomatis terdeteksi dari judul
            if (!_isEditing) ...[
              _buildCategorySection(),
            ],

            // Pilih warna
            _buildLabel('Warna Kartu'),
            const SizedBox(height: 8),
            _buildColorPicker(),
            const SizedBox(height: 40),

            // Tombol simpan
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
                    : Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Habit'),
              ),
            ),

            if (_isEditing) ...[
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
                  onPressed: () => _confirmDelete(),
                  child: Text(
                    'Hapus Habit',
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _titleController.text.isEmpty
                  ? 'Nama habit kamu...'
                  : _titleController.text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha:
                    _titleController.text.isEmpty ? 0.6 : 1.0),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  '$_calculatedCoins',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Coins',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Panel info koin otomatis — update live saat judul berubah
  Widget _buildCoinInfo() {
    final cat = CoinCalculator.habitCategory(_titleController.text.trim());
    final coins = cat.coins;

    // Warna berdasarkan besaran koin
    Color accent;
    if (coins >= 50) {
      accent = Colors.orange.shade600;
    } else if (coins >= 35) {
      accent = Colors.purple.shade400;
    } else if (coins >= 30) {
      accent = Colors.blue.shade500;
    } else if (coins >= 25) {
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
                'Koin ditentukan otomatis berdasarkan jenis & tingkat kesulitan habit',
            child: Icon(Icons.info_outline, color: accent.withValues(alpha: 0.5), size: 18),
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

  Widget _buildTitleInput() {
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
        controller: _titleController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Contoh: Olahraga 30 menit',
          hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        maxLength: 60,
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

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Kategori'),
            if (_selectedCategoryIndex >= 0)
              Text(
                '✓ Terdeteksi',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Horizontal scrollable category chips
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _habitCategories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final cat = _habitCategories[i];
              final isSelected = _selectedCategoryIndex == i;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategoryIndex = isSelected ? -1 : i;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    '${cat.emoji} ${cat.name}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Show suggestion chips for selected category
        if (_selectedCategoryIndex >= 0) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _habitCategories[_selectedCategoryIndex].suggestions.map((s) {
              return GestureDetector(
                onTap: () => setState(() {
                  _titleController.text = s;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    s,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Habit?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Habit "${widget.editHabit!.title}" akan dihapus permanen.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () async {
              final dialogCtx = ctx;
              final provider = context.read<HabitProvider>();
              final habitId = widget.editHabit!.id;
              await provider.deleteHabit(habitId);
              if (!mounted) return;
              Navigator.pop(dialogCtx);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text('Hapus',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Category data for habit suggestion chips
class _HabitCategory {
  final String emoji;
  final String name;
  final List<String> suggestions;
  const _HabitCategory(this.emoji, this.name, this.suggestions);
}

const _habitCategories = [
  _HabitCategory('🕌', 'Ibadah', [
    'Sholat 5 Waktu',
    'Baca Quran',
    'Dzikir Pagi/Sore',
    'Sedekah',
    'Puasa Sunnah',
    'Sholat Tahajud',
  ]),
  _HabitCategory('💼', 'Bekerja', [
    'Selesaikan Task',
    'Review Kode',
    'Meeting Produktif',
    'Dokumentasi',
    'Belajar Skill Baru',
  ]),
  _HabitCategory('🏃', 'Olahraga', [
    'Lari Pagi',
    'Push-up',
    'Gym',
    'Yoga',
    'Stretching',
    'Jalan Kaki 30 Min',
  ]),
  _HabitCategory('📚', 'Belajar', [
    'Baca Buku',
    'Kursus Online',
    'Latihan Soal',
    'Catat Ringkasan',
  ]),
  _HabitCategory('💧', 'Kesehatan', [
    'Minum Air 8 Gelas',
    'Tidur 7-8 Jam',
    'Makan Sayur',
    'Vitamin',
  ]),
  _HabitCategory('👨‍👩‍👦', 'Sosial', [
    'Hubungi Orang Tua',
    'Bantu Tetangga',
    'Kunjungi Keluarga',
  ]),
];
