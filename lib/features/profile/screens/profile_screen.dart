// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_responsive.dart';
import '../../../core/widgets/bottom_navbar_widget.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/admin_provider.dart';
import '../../../data/providers/user_profile_provider.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../data/providers/theme_provider.dart';
import '../../../data/providers/habit_provider.dart';
import '../../../data/providers/goal_provider.dart';
import '../../../data/providers/memo_provider.dart';
import '../../../data/providers/focus_timer_provider.dart';
import '../../admin/screens/admin_panel_screen.dart';
import '../../notifications/screens/notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _adminSetupDone = false;

  @override
  void initState() {
    super.initState();
    // Auto-setup admin jika user login dengan email admin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAdminIfNeeded();
    });
  }

  Future<void> _setupAdminIfNeeded() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final adminProvider = context.read<AdminProvider>();
    final profileProvider = context.read<UserProfileProvider>();
    final habitProvider = context.read<HabitProvider>();

    // Hanya jalankan sekali dan jika user sudah login
    if (!_adminSetupDone && authProvider.isLoggedIn) {
      _adminSetupDone = true;
      await authProvider.completeGoogleLoginSetup(
        adminProvider: adminProvider,
        profileProvider: profileProvider,
        habitProvider: habitProvider,
      );
    }
  }

  // ── Helper Methods for Theme-Aware Colors ──────────────────────────────

  Color _getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F0F0F)
        : AppColors.background;
  }

  Color _getContainerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A1A)
        : Colors.white;
  }

  Color _getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppColors.textPrimary;
  }

  Color _getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB0B0B0)
        : AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final profileProvider = context.watch<UserProfileProvider>();

    return Scaffold(
      backgroundColor: _getBackgroundColor(context),
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // ── Google Account Section (Readonly) ──────────────────────────────
          if (authProvider.isLoggedIn)
            _buildGoogleAccountCard(authProvider)
          else
            _buildLoginCard(context, authProvider),

          const SizedBox(height: 16),

          // ── Profile Section ────────────────────────────────────────────────
          _buildProfileInfoCard(profileProvider),

          const SizedBox(height: 16),

          // ── Edit Profile Button (hanya jika login) ──────────────────────────
          if (authProvider.isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () => _showEditProfileDialog(context, profileProvider),
                icon: const Icon(Icons.edit),
                label: Text(
                  'Edit Profil',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ── Notification Settings ──────────────────────────────────────────────
          Consumer<NotificationProvider>(
            builder: (_, notifProvider, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                title: Text(
                  'Pengaturan Notifikasi',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _getTextPrimaryColor(context),
                  ),
                ),
                subtitle: Text(
                  '${notifProvider.activeCount} notifikasi aktif',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _getTextSecondaryColor(context),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Theme Settings ─────────────────────────────────────────────────
          Consumer<ThemeProvider>(
            builder: (_, themeProvider, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Mode Gelap/Terang',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _getTextPrimaryColor(context),
                  ),
                ),
                subtitle: Text(
                  themeProvider.isDarkMode ? 'Mode Gelap' : 'Mode Terang',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _getTextSecondaryColor(context),
                  ),
                ),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Admin Panel Access (hanya untuk admin) ──────────────────────────
          if (adminProvider.isAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                ),
                icon: const Icon(Icons.admin_panel_settings),
                label: Text(
                  'Admin Panel (${adminProvider.adminEmail})',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ── Developer Info ─────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.padding(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tentang Aplikasi',
                  style: GoogleFonts.poppins(
                    fontSize: context.fontSize(14),
                    fontWeight: FontWeight.w700,
                    color: _getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoTile(
                  icon: Icons.info_outline,
                  label: 'Aplikasi',
                  value: 'BisaProduktif v1.0',
                ),
                _buildInfoTile(
                  icon: Icons.code,
                  label: 'Developer',
                  value: 'Tim Bisaproduktif',
                ),
                _buildInfoTile(
                  icon: Icons.language,
                  label: 'Website',
                  value: 'https://bisaproduktif.com',
                ),
                _buildInfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: 'hello@bisaproduktif.com',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Logout Button ──────────────────────────────────────────────────
          if (authProvider.isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final habitProvider = context.read<HabitProvider>();
                  final goalProvider = context.read<GoalProvider>();
                  final memoProvider = context.read<MemoProvider>();
                  final focusProvider = context.read<FocusTimerProvider>();

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Text('Logout',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      content: Text(
                        'Yakin ingin logout? Semua data (koin, habit, goal, memo, focus) akan direset.',
                        style: GoogleFonts.poppins(),
                      ),
                      actions: [
                        // Horizontal aligned buttons dengan equal width
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.textSecondary),
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
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Logout',
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
                  if (confirm == true && mounted) {
                    await habitProvider.clearUserData();
                    await goalProvider.clearUserData();
                    await memoProvider.clearUserData();
                    await focusProvider.clearUserData();
                    // signOut() akan trigger onLogoutNavigate callback dari HomeScreen
                    await authProvider.signOut();
                    // Jangan call nav.pop() — callback akan handle navigation
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout, color: AppColors.danger),
                label: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavBar(activeIndex: 3),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Builder(
        builder: (context) => Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('👤', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Text('Profil',
                style: GoogleFonts.poppins(
                    fontSize: context.fontSize(18),
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _getContainerColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _getTextSecondaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard(UserProfileProvider profileProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getContainerColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Pribadi',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 16),
          _buildProfileField(
            icon: Icons.person,
            label: 'Nama',
            value: profileProvider.name.isEmpty ? 'Belum diisi' : profileProvider.name,
          ),
          const SizedBox(height: 12),
          _buildProfileField(
            icon: Icons.location_on,
            label: 'Alamat',
            value: profileProvider.address.isEmpty ? 'Belum diisi' : profileProvider.address,
          ),
          const SizedBox(height: 12),
          _buildProfileField(
            icon: Icons.phone,
            label: 'WhatsApp',
            value: profileProvider.whatsapp.isEmpty ? 'Belum diisi' : profileProvider.whatsapp,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _getTextSecondaryColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build Google Account Card (Readonly)
  Widget _buildGoogleAccountCard(AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getContainerColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Akun Google (Read-only)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _getTextPrimaryColor(context),
                ),
              ),
              const Spacer(),
              Icon(Icons.verified, color: Colors.green, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          _buildProfileField(
            icon: Icons.person,
            label: 'Nama Google',
            value: authProvider.displayName.isEmpty ? '-' : authProvider.displayName,
          ),
          const SizedBox(height: 12),
          _buildProfileField(
            icon: Icons.email,
            label: 'Email',
            value: authProvider.email.isEmpty ? '-' : authProvider.email,
          ),
          const SizedBox(height: 12),
          Text(
            '💡 Data dari Google Account tidak bisa diubah di sini. Edit dari akun Google Anda.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: _getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Login Card (when not logged in)
  Widget _buildLoginCard(BuildContext context, AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔐 Login dengan Google',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sync data Anda ke Google Cloud & akses di perangkat lain',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: authProvider.isLoading
                  ? null
                  : () async {
                      final success = await authProvider.signInWithGoogle();
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ Login berhasil!',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              icon: authProvider.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.login),
              label: Text(
                authProvider.isLoading ? 'Sedang login...' : 'Login Google',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProfileProvider profileProvider) {
    final nameCtrl = TextEditingController(text: profileProvider.name);
    final addressCtrl = TextEditingController(text: profileProvider.address);
    final whatsappCtrl = TextEditingController(text: profileProvider.whatsapp);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profil',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nama Lengkap',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Contoh: Ahmad Ridho',
                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Alamat',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Contoh: Jl. Merdeka No. 123, Jakarta',
                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nomor WhatsApp',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: whatsappCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Contoh: +6281234567890 (opsional)',
                  hintStyle: GoogleFonts.poppins(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              if (nameCtrl.text.isEmpty || addressCtrl.text.isEmpty) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Nama dan alamat harus diisi',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }

              await profileProvider.updateProfile(
                name: nameCtrl.text,
                address: addressCtrl.text,
                whatsapp: whatsappCtrl.text,
              );

              if (!mounted) return;
              nav.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    '✅ Profil berhasil diperbarui',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('Simpan', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }


}
