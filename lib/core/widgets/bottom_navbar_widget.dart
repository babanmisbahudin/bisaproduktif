import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../../data/providers/admin_provider.dart';
import '../../data/providers/reward_provider.dart';
import '../../features/report/screens/report_screen.dart';
import '../../features/rewards/screens/reward_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/admin/screens/admin_reward_claims_screen.dart';
import '../utils/app_transition.dart';

class BottomNavBar extends StatelessWidget {
  final int activeIndex; // 0=Home, 1=Report, 2=Reward, 3=Admin, 4=Profile

  const BottomNavBar({
    super.key,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, _) {
        final navItems = <Widget>[
          _buildNavItem(
            context: context,
            icon: Icons.home_rounded,
            isActive: activeIndex == 0,
            badge: 0,
            onTap: () {
              if (activeIndex != 0) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.bar_chart_rounded,
            isActive: activeIndex == 1,
            badge: 0,
            onTap: () {
              if (activeIndex != 1) {
                Navigator.push(
                  context,
                  AppTransition.slideRight(child: const ReportScreen()),
                );
              }
            },
          ),
          _buildNavItem(
            context: context,
            icon: Icons.shopping_bag_outlined,
            isActive: activeIndex == 2,
            badge: 0,
            onTap: () {
              if (activeIndex != 2) {
                Navigator.push(
                  context,
                  AppTransition.slideRight(child: const RewardScreen()),
                );
              }
            },
          ),
          if (adminProvider.isAdmin)
            Builder(
              builder: (ctx) {
                final rewardProvider = ctx.read<RewardProvider>();
                final pendingCount = adminProvider.getPendingCount(rewardProvider);
                return _buildNavItem(
                  context: context,
                  icon: Icons.admin_panel_settings,
                  isActive: activeIndex == 3,
                  badge: pendingCount,
                  onTap: () {
                    if (activeIndex != 3) {
                      Navigator.push(
                        context,
                        AppTransition.slideRight(
                          child: const AdminRewardClaimsScreen(),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          _buildNavItem(
            context: context,
            icon: Icons.person_outlined,
            isActive: activeIndex == (adminProvider.isAdmin ? 4 : 3),
            badge: 0,
            onTap: () {
              final expectedIndex = adminProvider.isAdmin ? 4 : 3;
              if (activeIndex != expectedIndex) {
                Navigator.push(
                  context,
                  AppTransition.slideRight(child: const ProfileScreen()),
                );
              }
            },
          ),
        ];

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: navItems,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required bool isActive,
    required int badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1.2,
              ),
            ),
            child: Icon(
              icon,
              color: isActive
                  ? AppColors.primary
                  : const Color(0xFF9CA3AF),
              size: 24,
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -4,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$badge',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
