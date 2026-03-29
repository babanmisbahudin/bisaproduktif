import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/providers/goal_provider.dart';
import '../../../data/providers/habit_provider.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: goal.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: goal.color.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${goal.completedTasks}/${goal.totalTasks} kegiatan selesai',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      goal.isCompleted ? '✅ Selesai' : '🔄 Aktif',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goal.progressPercent,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 12),

              // Deadline
              if (goal.deadline != null) ...[
                Text(
                  '📅 Target: ${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Tasks list
              if (goal.tasks.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: goal.tasks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final task = entry.value;
                      final isLast = index == goal.tasks.length - 1;

                      return Column(
                        children: [
                          _buildTaskTile(context, goal, task),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                )
              ] else
                Center(
                  child: Text(
                    'Belum ada kegiatan. Tap untuk tambah!',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, GoalModel goal, dynamic task) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              if (task.completed) {
                context.read<GoalProvider>().uncompleteTask(
                      goalId: goal.id,
                      taskId: task.id,
                      habitProvider: context.read<HabitProvider>(),
                    );
              } else {
                context.read<GoalProvider>().completeTask(
                      goalId: goal.id,
                      taskId: task.id,
                      habitProvider: context.read<HabitProvider>(),
                    );
              }
            },
            child: Checkbox(
              value: task.completed,
              onChanged: (_) {
                if (task.completed) {
                  context.read<GoalProvider>().uncompleteTask(
                        goalId: goal.id,
                        taskId: task.id,
                        habitProvider: context.read<HabitProvider>(),
                      );
                } else {
                  context.read<GoalProvider>().completeTask(
                        goalId: goal.id,
                        taskId: task.id,
                        habitProvider: context.read<HabitProvider>(),
                      );
                }
              },
              fillColor: WidgetStateProperty.all(Colors.white),
              checkColor: goal.color,
            ),
          ),
          const SizedBox(width: 8),
          // Task name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                Text(
                  '+${task.coins} koin',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
