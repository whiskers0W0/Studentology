import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/models/task_model.dart';
import 'package:studentology/providers/task_provider.dart';

/// Signals returned by [TaskDetailScreen] via [Navigator.pop].
enum TaskDetailAction { edit }

class TaskDetailScreen extends StatelessWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return AppTheme.errorColor;
      case TaskPriority.medium:
        return AppTheme.warningColor;
      case TaskPriority.low:
        return AppTheme.successColor;
    }
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Use the live task from the provider so toggling completion updates the UI.
    return Consumer<TaskProvider>(
      builder: (context, tp, _) {
        final live = tp.tasks.firstWhere(
          (t) => t.id == task.id,
          orElse: () => task,
        );
        final priorityColor = _priorityColor(live.priority);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Detail'),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(TaskDetailAction.edit),
                child: const Text('Edit'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // ── Hero title ──────────────────────────────────────────────
              Hero(
                tag: 'task-title-${live.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    live.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          decoration: live.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: live.isCompleted
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.4)
                              : null,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Info cards ──────────────────────────────────────────────
              _InfoCard(
                children: [
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    label: 'Due Date',
                    value: _formatDate(live.dueDate),
                    valueColor:
                        live.isOverdue ? AppTheme.errorColor : null,
                  ),
                  if (live.subjectName != null &&
                      live.subjectName!.isNotEmpty) ...[
                    const Divider(height: 1),
                    _InfoRow(
                      icon: Icons.class_outlined,
                      label: 'Subject',
                      value: live.subjectName!,
                      valueColor: AppTheme.primaryAccent,
                    ),
                  ],
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.flag_outlined,
                    label: 'Priority',
                    value: _priorityLabel(live.priority),
                    valueColor: priorityColor,
                  ),
                ],
              ),

              if (live.notes != null && live.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.55),
                                  letterSpacing: 0.5,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            live.notes!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // ── Toggle completion ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => tp.toggleComplete(live.id),
                  icon: Icon(
                    live.isCompleted
                        ? Icons.undo_rounded
                        : Icons.check_circle_outline,
                    size: 20,
                  ),
                  label: Text(
                    live.isCompleted ? 'Mark as Pending' : 'Mark as Complete',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: live.isCompleted
                        ? Theme.of(context).colorScheme.outline
                        : AppTheme.successColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Private helpers ────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5)),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
