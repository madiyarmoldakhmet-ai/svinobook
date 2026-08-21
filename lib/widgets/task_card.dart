import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task_card_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';

class TaskCard extends StatelessWidget {
  final TaskCardModel task;

  const TaskCard({super.key, required this.task});

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red.shade300;
      case 'low':
        return Colors.green.shade300;
      default:
        return Colors.orange.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final isDone = task.status.toLowerCase() == 'done';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgMid,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _priorityColor(task.priority).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _priorityColor(task.priority).withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(
                    color: _priorityColor(task.priority),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDone
                      ? Colors.green.withValues(alpha: 0.2)
                      : AppColors.neonCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isDone ? 'Done' : 'Open',
                  style: TextStyle(
                    color: isDone ? Colors.green.shade300 : AppColors.neonCyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  await firestore.toggleTaskStatus(task.id, !isDone);
                },
                icon: Icon(
                  isDone ? Icons.undo_rounded : Icons.check_circle_rounded,
                  color: isDone ? AppColors.textMuted : AppColors.neonCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
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
          if (task.dueDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event_rounded, size: 16, color: AppColors.neonCyan),
                const SizedBox(width: 6),
                Text(
                  'Due ${DateFormat.yMMMd().format(task.dueDate!)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                task.assigneeName,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat.yMMMd().add_jm().format(task.createdAt),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
