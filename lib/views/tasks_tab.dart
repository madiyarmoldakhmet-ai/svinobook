import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_card_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  String _filter = 'All';

  List<TaskCardModel> _applyFilter(List<TaskCardModel> tasks) {
    if (_filter == 'Open') {
      return tasks
          .where((task) => task.status.toLowerCase() == 'open')
          .toList();
    }
    if (_filter == 'Done') {
      return tasks
          .where((task) => task.status.toLowerCase() == 'done')
          .toList();
    }
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      color: AppColors.bgDarkest,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Tasks',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'All', label: Text('All')),
                  ButtonSegment(value: 'Open', label: Text('In work')),
                  ButtonSegment(value: 'Done', label: Text('Done')),
                ],
                selected: {_filter},
                onSelectionChanged: (selection) {
                  setState(() => _filter = selection.first);
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<TaskCardModel>>(
                stream: firestore.getTasksStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.neonCyan,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading tasks: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  final tasks = _applyFilter(snapshot.data ?? []);
                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        'No tasks in this filter',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  }

                  final openTasks = tasks
                      .where((task) => task.status.toLowerCase() == 'open')
                      .toList();
                  final doneTasks = tasks
                      .where((task) => task.status.toLowerCase() == 'done')
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    children: [
                      if (openTasks.isNotEmpty)
                        _buildSection('In work', openTasks),
                      if (doneTasks.isNotEmpty)
                        _buildSection('Completed', doneTasks),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<TaskCardModel> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        ...tasks.map((task) => _buildTaskTile(task)),
      ],
    );
  }

  Widget _buildTaskTile(TaskCardModel task) {
    final isDone = task.status.toLowerCase() == 'done';
    final firestore = context.read<FirestoreService>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => firestore.toggleTaskStatus(task.id, !isDone),
                icon: Icon(
                  isDone ? Icons.undo_rounded : Icons.check_circle_rounded,
                  color: isDone ? AppColors.textMuted : AppColors.neonCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.success.withValues(alpha: 0.14)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isDone ? 'Done' : 'In work',
                  style: TextStyle(
                    color: isDone ? AppColors.success : AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: task.priority == 'High'
                      ? Colors.red.withValues(alpha: 0.14)
                      : task.priority == 'Low'
                      ? Colors.green.withValues(alpha: 0.14)
                      : Colors.orange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(
                    color: task.priority == 'High'
                        ? Colors.red.shade300
                        : task.priority == 'Low'
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
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
