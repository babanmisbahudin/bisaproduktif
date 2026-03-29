import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/goal_model.dart';
import '../models/goal_task_model.dart';

class GoalProvider extends ChangeNotifier {
  static const String _boxName = 'goals';

  late Box<GoalModel> _box;
  List<GoalModel> _goals = [];
  bool _isLoaded = false;

  List<GoalModel> get goals => List.unmodifiable(_goals);
  bool get isLoaded => _isLoaded;

  List<GoalModel> get activeGoals =>
      _goals.where((g) => g.status == GoalStatus.active).toList();
  List<GoalModel> get completedGoals =>
      _goals.where((g) => g.isCompleted).toList();

  int get totalGoals => _goals.length;
  int get completedCount => completedGoals.length;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _box = await Hive.openBox<GoalModel>(_boxName);
    _loadGoals();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> clearUserData() async {
    _goals.clear();
    await _box.clear();
    _isLoaded = false;
    notifyListeners();
  }

  void _loadGoals() {
    _goals = _box.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  // ── Add Goal (Manual) ─────────────────────────────────────────────────────

  Future<void> addGoal({
    required String title,
    required int coins,
    required Color color,
    DateTime? deadline,
  }) async {
    final goal = GoalModel(
      id: const Uuid().v4(),
      title: title,
      tasks: [],
      coins: coins,
      status: GoalStatus.active,
      colorValue: color.toARGB32(),
      createdAt: DateTime.now(),
      deadline: deadline,
      order: _goals.length,
    );

    await _box.put(goal.id, goal);
    _goals.add(goal);
    _goals.sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  // ── Add Task to Goal ──────────────────────────────────────────────────────

  Future<void> addTaskToGoal({
    required String goalId,
    required String taskName,
    required int coins,
  }) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);

    final task = GoalTask(
      id: const Uuid().v4(),
      name: taskName,
      coins: coins,
      createdAt: DateTime.now(),
    );

    goal.tasks.add(task);
    await _box.put(goal.id, goal);
    notifyListeners();
  }

  // ── Complete Task ─────────────────────────────────────────────────────────

  Future<void> completeTask({
    required String goalId,
    required String taskId,
    dynamic habitProvider, // untuk add coins
  }) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final task = goal.tasks.firstWhere((t) => t.id == taskId);

    task.completed = true;
    task.completedAt = DateTime.now();

    // Add coins ke user
    if (habitProvider != null) {
      await habitProvider.addCoins(task.coins);
    }

    // Check if goal is completed (all tasks done)
    if (goal.completedTasks == goal.totalTasks) {
      goal.status = GoalStatus.completed;
      // Bonus coins untuk goal selesai
      if (habitProvider != null) {
        await habitProvider.addCoins(goal.coins);
      }
    }

    await _box.put(goal.id, goal);
    notifyListeners();
  }

  // ── Uncomplete Task ───────────────────────────────────────────────────────

  Future<void> uncompleteTask({
    required String goalId,
    required String taskId,
    dynamic habitProvider, // untuk deduct coins
  }) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final task = goal.tasks.firstWhere((t) => t.id == taskId);

    // Deduct coins
    if (habitProvider != null && task.completed) {
      await habitProvider.deductCoins(task.coins);
    }

    task.completed = false;
    task.completedAt = null;

    // Reset goal status jika sebelumnya completed
    if (goal.status == GoalStatus.completed) {
      goal.status = GoalStatus.active;
      // Deduct goal bonus coins
      if (habitProvider != null) {
        await habitProvider.deductCoins(goal.coins);
      }
    }

    await _box.put(goal.id, goal);
    notifyListeners();
  }

  // ── Delete Task ───────────────────────────────────────────────────────────

  Future<void> deleteTask({
    required String goalId,
    required String taskId,
    dynamic habitProvider,
  }) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final task = goal.tasks.firstWhere((t) => t.id == taskId);

    // Deduct coins jika task sudah completed
    if (habitProvider != null && task.completed) {
      await habitProvider.deductCoins(task.coins);
    }

    goal.tasks.removeWhere((t) => t.id == taskId);

    // Reset goal completed status jika tidak semua tasks done
    if (goal.status == GoalStatus.completed && goal.completedTasks < goal.totalTasks) {
      goal.status = GoalStatus.active;
      if (habitProvider != null) {
        await habitProvider.deductCoins(goal.coins);
      }
    }

    await _box.put(goal.id, goal);
    notifyListeners();
  }

  // ── Delete Goal ───────────────────────────────────────────────────────────

  Future<void> deleteGoal({
    required String goalId,
    dynamic habitProvider,
  }) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);

    // Deduct coins dari completed tasks
    if (habitProvider != null) {
      for (final task in goal.tasks) {
        if (task.completed) {
          await habitProvider.deductCoins(task.coins);
        }
      }
      // Deduct goal bonus jika goal completed
      if (goal.status == GoalStatus.completed) {
        await habitProvider.deductCoins(goal.coins);
      }
    }

    _goals.removeWhere((g) => g.id == goalId);
    await _box.delete(goalId);

    // Reorder
    for (int i = 0; i < _goals.length; i++) {
      _goals[i].order = i;
      await _box.put(_goals[i].id, _goals[i]);
    }

    notifyListeners();
  }

  // ── Update Goal Title ─────────────────────────────────────────────────────

  Future<void> updateGoalTitle({
    required String goalId,
    required String newTitle,
  }) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    goal.title = newTitle;
    await _box.put(goal.id, goal);
    notifyListeners();
  }

  // ── Update Goal Deadline ──────────────────────────────────────────────────

  Future<void> updateGoalDeadline({
    required String goalId,
    DateTime? deadline,
  }) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    goal.deadline = deadline;
    await _box.put(goal.id, goal);
    notifyListeners();
  }
}
