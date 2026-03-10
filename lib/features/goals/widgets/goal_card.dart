import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/goal_model.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSendForReview;
  final ValueChanged<int>? onProgressChanged;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onLongPress,
    this.onSendForReview,
    this.onProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: goal.color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: goal.color.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  _buildStatusBadge(),
                  const SizedBox(width: 10),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (goal.targetDescription.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            goal.targetDescription,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Coin badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on,
                            color: Colors.amber, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '${goal.coins}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: goal.progressPercent,
                      minHeight: 7,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(goal.progressPercent * 100).toInt()}% selesai',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      if (goal.deadline != null)
                        Text(
                          'Deadline: ${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions (hanya untuk active & progress 100%)
            if (goal.status == GoalStatus.active &&
                goal.currentProgress >= goal.targetProgress &&
                onSendForReview != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: goal.color,
                      minimumSize: const Size(double.infinity, 38),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      'Kirim untuk Review',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: onSendForReview,
                  ),
                ),
              )
            else
              const SizedBox(height: 14),

            // Review notes
            if (goal.reviewNotes.isNotEmpty &&
                goal.status == GoalStatus.active)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          goal.reviewNotes,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    IconData icon;
    switch (goal.status) {
      case GoalStatus.active:
        icon = Icons.flag_rounded;
        break;
      case GoalStatus.sentForReview:
        icon = Icons.hourglass_top_rounded;
        break;
      case GoalStatus.completed:
        icon = Icons.check_circle_rounded;
        break;
      case GoalStatus.approved:
        icon = Icons.verified_rounded;
        break;
    }
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}
