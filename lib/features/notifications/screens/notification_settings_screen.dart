import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/providers/notification_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  String _userName = '';
  bool _testSent = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('user_name') ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Notifikasi',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              if (provider.activeCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_active_rounded,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.activeCount} aktif',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              // ── Info banner ───────────────────────────────────────────────
              _buildInfoBanner(),
              const SizedBox(height: 20),

              // ── Morning Reminder ──────────────────────────────────────────
              _buildSectionLabel('Pengingat Pagi'),
              const SizedBox(height: 10),
              _buildNotifCard(
                icon: '🌅',
                title: 'Morning Reminder',
                subtitle: 'Pengingat mulai habit di pagi hari',
                previewText:
                    'Selamat pagi, $_userName! Yuk mulai habit harianmu!',
                enabled: provider.morningEnabled,
                time: provider.formatTime(
                    provider.morningHour, provider.morningMinute),
                onToggle: (val) async {
                  await provider.setMorningEnabled(val, userName: _userName);
                },
                onTimeTap: () => _pickMorningTime(provider),
              ),
              const SizedBox(height: 20),

              // ── Evening Warning ───────────────────────────────────────────
              _buildSectionLabel('Peringatan Streak'),
              const SizedBox(height: 10),
              _buildNotifCard(
                icon: '🔥',
                title: 'Streak Warning',
                subtitle: 'Peringatan malam jika habit belum selesai',
                previewText:
                    'Jangan putuskan streakmu! Masih ada habit yang belum selesai.',
                enabled: provider.eveningEnabled,
                time: provider.formatTime(
                    provider.eveningHour, provider.eveningMinute),
                onToggle: (val) async {
                  await provider.setEveningEnabled(val);
                },
                onTimeTap: () => _pickEveningTime(provider),
              ),
              const SizedBox(height: 28),

              // ── Test button ───────────────────────────────────────────────
              _buildTestButton(),
              const SizedBox(height: 16),

              // ── Tips ──────────────────────────────────────────────────────
              _buildTips(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('📲', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aktifkan notifikasi untuk tetap konsisten dengan habit harianmu.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF2E7D32),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildNotifCard({
    required String icon,
    required String title,
    required String subtitle,
    required String previewText,
    required bool enabled,
    required String time,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTimeTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: enabled
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                  activeThumbColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            height: 1,
            color: Colors.grey.withValues(alpha: 0.1),
          ),

          // Time row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: enabled ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Jam ',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: enabled ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (enabled)
                  GestureDetector(
                    onTap: onTimeTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Ubah',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Preview message (when enabled)
          if (enabled)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notifications_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      previewText,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _testSent ? null : _sendTestNotif,
        icon: Icon(
          _testSent ? Icons.check_circle_rounded : Icons.send_rounded,
          size: 18,
        ),
        label: Text(
          _testSent ? 'Notifikasi terkirim!' : 'Coba Kirim Notifikasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor:
              _testSent ? Colors.green : AppColors.primary,
          side: BorderSide(
            color: _testSent
                ? Colors.green.withValues(alpha: 0.4)
                : AppColors.primary.withValues(alpha: 0.4),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: _testSent
              ? Colors.green.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Tips',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTipItem('Set reminder pagi 30 menit setelah bangun tidur'),
          _buildTipItem(
              'Set peringatan malam 1-2 jam sebelum tidur untuk review habit'),
          _buildTipItem(
              'Pastikan izin notifikasi diaktifkan di pengaturan HP'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.orange[700])),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.orange[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickMorningTime(NotificationProvider provider) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: provider.morningTime,
      helpText: 'Jam pengingat pagi',
      builder: (context, child) => _timePickerTheme(child),
    );
    if (picked != null) {
      await provider.setMorningTime(picked, userName: _userName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar(
            'Morning reminder diubah ke ${provider.formatTime(picked.hour, picked.minute)}'));
      }
    }
  }

  Future<void> _pickEveningTime(NotificationProvider provider) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: provider.eveningTime,
      helpText: 'Jam peringatan malam',
      builder: (context, child) => _timePickerTheme(child),
    );
    if (picked != null) {
      await provider.setEveningTime(picked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar(
            'Streak warning diubah ke ${provider.formatTime(picked.hour, picked.minute)}'));
      }
    }
  }

  Future<void> _sendTestNotif() async {
    await NotificationService().showTestNotification();
    setState(() => _testSent = true);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _testSent = false);
  }

  Widget _timePickerTheme(Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
      ),
      child: child!,
    );
  }

  SnackBar _buildSnackBar(String message) {
    return SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(message,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13)),
      ]),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    );
  }
}
