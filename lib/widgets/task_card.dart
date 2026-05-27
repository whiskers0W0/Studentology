import 'package:flutter/material.dart';
import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final bool heroEnabled;
  final bool selectMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
    this.heroEnabled = false,
    this.selectMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onSelectTap,
  });

  Widget _buildTitle(BuildContext context, Color dimColor) {
    final text = Text(
      task.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? dimColor : null,
          ),
    );
    if (!heroEnabled || selectMode) return text;
    return Hero(
      tag: 'task-title-${task.id}',
      child: Material(color: Colors.transparent, child: text),
    );
  }

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

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(date.year, date.month, date.day);
    final diff = taskDay.difference(today).inDays;
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff == -1) return 'Due yesterday';
    if (diff < 0) return 'Overdue by ${-diff}d';
    if (diff <= 7) return 'Due in ${diff}d';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priorityColor = _priorityColor(task.priority);
    final borderColor =
        isDark ? AppTheme.cartoonBorderDark : AppTheme.cartoonBorder;
    final dimColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.38);

    final BoxDecoration decoration = selectMode
        ? BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFB347).withOpacity(0.08)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFB347)
                  : Colors.black.withOpacity(0.12),
              width: isSelected ? 2.0 : 1.5,
            ),
            boxShadow: isDark ? const [] : AppTheme.cartoonShadow,
          )
        : BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: task.isOverdue
                  ? AppTheme.errorColor.withOpacity(0.7)
                  : borderColor,
              width: 1.5,
            ),
            boxShadow: isDark ? const [] : AppTheme.cartoonShadow,
          );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selectMode ? onSelectTap : onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: decoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (selectMode) ...[
              SelectCircleCheckbox(isSelected: isSelected),
              const SizedBox(width: 10),
            ],
            // Priority dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
                border: selectMode
                    ? null
                    : Border.all(color: borderColor, width: 1.0),
              ),
            ),
            const SizedBox(width: 12),
            // Title + metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(context, dimColor),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 12,
                        color: task.isOverdue
                            ? AppTheme.errorColor
                            : dimColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatDueDate(task.dueDate),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: task.isOverdue
                                  ? AppTheme.errorColor
                                  : null,
                            ),
                      ),
                      if (task.subjectName != null &&
                          task.subjectName!.isNotEmpty) ...[
                        Text(
                          ' · ',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Flexible(
                          child: Text(
                            task.subjectName!,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.primaryAccent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!selectMode) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => onToggle(),
                  activeColor: AppTheme.primaryAccent,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  side: const BorderSide(
                      color: AppTheme.primaryAccent, width: 1.5),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Shared circle checkbox used across list screens in select mode
class SelectCircleCheckbox extends StatelessWidget {
  final bool isSelected;
  const SelectCircleCheckbox({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFFFFB347) : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFFB347)
              : Colors.black.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : null,
    );
  }
}
