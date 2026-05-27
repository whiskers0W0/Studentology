import 'package:flutter/material.dart';
import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/models/exam_model.dart';

class ExamCard extends StatelessWidget {
  final ExamModel exam;
  final VoidCallback? onAddScore;
  final VoidCallback onDelete;

  const ExamCard({
    super.key,
    required this.exam,
    this.onAddScore,
    required this.onDelete,
  });

  String _formatScheduled(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour > 12
        ? d.hour - 12
        : (d.hour == 0 ? 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day}, ${d.year}  $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysUntil = exam.daysUntil;
    final borderColor = (!exam.isPast && daysUntil <= 3)
        ? AppTheme.warningColor
        : (isDark ? AppTheme.cartoonBorderDark : AppTheme.cartoonBorder);
    final borderWidth = (!exam.isPast && daysUntil <= 3) ? 2.0 : 1.5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: isDark ? const [] : AppTheme.cartoonShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject chip + title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject pill chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.cartoonBorderDark
                              : AppTheme.cartoonBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        exam.subjectName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryAccent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exam.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Badges + delete
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (exam.hasScore)
                        _ScoreBadge(
                          score: exam.score!.toInt(),
                          total: exam.totalScore!.toInt(),
                          passed: (exam.percentage ?? 0) >= 75,
                          isDark: isDark,
                        ),
                      if (!exam.isPast && daysUntil <= 3)
                        _UrgencyChip(daysUntil: daysUntil),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 10),

          // ── Details row ────────────────────────────────────────────────────
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _DetailChip(
                icon: Icons.schedule_outlined,
                label: _formatScheduled(exam.scheduledAt),
              ),
              if (exam.room.isNotEmpty)
                _DetailChip(
                  icon: Icons.room_outlined,
                  label: 'Room ${exam.room}',
                ),
              if (exam.seatNumber.isNotEmpty)
                _DetailChip(
                  icon: Icons.event_seat_outlined,
                  label: 'Seat ${exam.seatNumber}',
                ),
            ],
          ),

          // ── Add Score button ───────────────────────────────────────────────
          if (exam.isPast && !exam.hasScore && onAddScore != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onAddScore,
                icon: const Icon(Icons.add_circle_outline, size: 15),
                label: const Text('Add Score'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryAccent,
                  side: const BorderSide(color: AppTheme.primaryAccent, width: 1.5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final int score;
  final int total;
  final bool passed;
  final bool isDark;

  const _ScoreBadge({
    required this.score,
    required this.total,
    required this.passed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppTheme.successColor : AppTheme.errorColor;
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Text(
        '$score/$total',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  final int daysUntil;

  const _UrgencyChip({required this.daysUntil});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.13),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppTheme.warningColor, width: 1.2),
      ),
      child: Text(
        daysUntil == 0 ? 'Today' : 'In ${daysUntil}d',
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.warningColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.55);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
