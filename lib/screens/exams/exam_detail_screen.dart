import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/models/exam_model.dart';
import 'package:studentology/providers/exam_provider.dart';

/// Signals returned by [ExamDetailScreen] via [Navigator.pop].
enum ExamDetailAction { edit, addScore }

class ExamDetailScreen extends StatelessWidget {
  final ExamModel exam;

  const ExamDetailScreen({super.key, required this.exam});

  String _formatDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (context, ep, _) {
        final live = ep.exams.firstWhere(
          (e) => e.id == exam.id,
          orElse: () => exam,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Exam Detail'),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(ExamDetailAction.edit),
                child: const Text('Edit'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              // ── Hero subject chip ────────────────────────────────────────
              Hero(
                tag: 'exam-subject-${live.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryAccent.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        live.subjectName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryAccent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Exam title ───────────────────────────────────────────────
              Text(
                live.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              // ── Score badge (if recorded) ────────────────────────────────
              if (live.hasScore) ...[
                _ScoreSection(exam: live),
                const SizedBox(height: 16),
              ],

              // ── Info rows ────────────────────────────────────────────────
              _InfoCard(
                children: [
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: _formatDate(live.examDate),
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    label: 'Start Time',
                    value: _formatTime(live.startTime),
                  ),
                  if (live.room.isNotEmpty) ...[
                    const Divider(height: 1),
                    _InfoRow(
                      icon: Icons.room_outlined,
                      label: 'Room',
                      value: live.room,
                    ),
                  ],
                  if (live.seatNumber.isNotEmpty) ...[
                    const Divider(height: 1),
                    _InfoRow(
                      icon: Icons.event_seat_outlined,
                      label: 'Seat',
                      value: live.seatNumber,
                    ),
                  ],
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

              // ── Add Score button (past exam, no score yet) ────────────────
              if (live.isPast && !live.hasScore)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(ExamDetailAction.addScore),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text('Add Score'),
                    style: ElevatedButton.styleFrom(
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

class _ScoreSection extends StatelessWidget {
  final ExamModel exam;
  const _ScoreSection({required this.exam});

  @override
  Widget build(BuildContext context) {
    final passed = (exam.percentage ?? 0) >= 75;
    final color = passed ? AppTheme.successColor : AppTheme.errorColor;
    final score = exam.score!;
    final total = exam.totalScore!;
    final pct = exam.percentage!;
    final scoreStr =
        '${_clean(score)} / ${_clean(total)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scoreStr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%  ·  ${passed ? 'Passed' : 'Failed'}',
                style: TextStyle(
                  fontSize: 13,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _clean(double d) =>
      d == d.truncateToDouble() ? d.toInt().toString() : d.toString();
}

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

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
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
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
