import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/models/grade_model.dart';
import 'package:studentology/widgets/task_card.dart' show SelectCircleCheckbox;

class GradeTile extends StatelessWidget {
  final GradeModel grade;
  final String gradingSystem;
  final VoidCallback onDelete;
  final bool selectMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectTap;

  const GradeTile({
    super.key,
    required this.grade,
    required this.gradingSystem,
    required this.onDelete,
    this.selectMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onSelectTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final secondary = cs.onSurface.withOpacity(0.52);
    final borderColor =
        isDark ? AppTheme.cartoonBorderDark : AppTheme.cartoonBorder;

    final color = GradeModel.getGradeColor(
      grade.grade,
      gradingSystem,
      context,
      isIncomplete: grade.isIncomplete,
    );
    final label = GradeModel.getEquivalentLabel(
      grade.grade,
      gradingSystem,
      isIncomplete: grade.isIncomplete,
    );

    final BoxDecoration decoration = selectMode
        ? BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFB347).withOpacity(0.08)
                : cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFB347)
                  : Colors.black.withOpacity(0.12),
              width: isSelected ? 2.0 : 1.5,
            ),
            boxShadow: (isDark || isSelected) ? const [] : AppTheme.cartoonShadow,
          )
        : BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isDark ? const [] : AppTheme.cartoonShadow,
          );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selectMode ? onSelectTap : null,
      onLongPress: onLongPress,
      child: Container(
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (selectMode) ...[
              SelectCircleCheckbox(isSelected: isSelected),
              const SizedBox(width: 10),
            ],
            // Left: subject info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.subjectName,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _subtitleText(),
                    style: GoogleFonts.inter(fontSize: 11, color: secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Right: grade display
            _GradeDisplay(
              grade: grade,
              gradingSystem: gradingSystem,
              color: color,
              label: label,
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _subtitleText() {
    final parts = <String>[
      if (grade.subjectCode.isNotEmpty) grade.subjectCode,
      '${grade.units % 1 == 0 ? grade.units.toInt() : grade.units} units',
      grade.semester,
    ];
    return parts.join(' · ');
  }


}

// ── System-specific grade display ─────────────────────────────────────────────

class _GradeDisplay extends StatelessWidget {
  final GradeModel grade;
  final String gradingSystem;
  final Color color;
  final String label;

  const _GradeDisplay({
    required this.grade,
    required this.gradingSystem,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _gradeValueRow(),
        const SizedBox(height: 4),
        _LabelChip(label: label, color: color),
      ],
    );
  }

  Widget _gradeValueRow() {
    if (gradingSystem == 'semestral') {
      return _SemestralGradeRow(grade: grade, color: color);
    }
    if (gradingSystem == 'trimestral') {
      return _TrimestralGradeRow(grade: grade, color: color);
    }
    return Text(
      _fmtPct(grade.grade),
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.1,
      ),
    );
  }

  static String _fmtPct(double v) =>
      '${v % 1 == 0 ? v.toInt() : v}%';
}

class _TrimestralGradeRow extends StatelessWidget {
  final GradeModel grade;
  final Color color;
  const _TrimestralGradeRow({required this.grade, required this.color});

  @override
  Widget build(BuildContext context) {
    final rawDisplay = grade.grade % 1 == 0
        ? '${grade.grade.toInt()}'
        : '${grade.grade}';
    final eq = GradeModel.getNUEquivalent(grade.grade);
    final eqDisplay = '→ ${eq.toStringAsFixed(1)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          rawDisplay,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.1,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          eqDisplay,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SemestralGradeRow extends StatelessWidget {
  final GradeModel grade;
  final Color color;
  const _SemestralGradeRow({required this.grade, required this.color});

  @override
  Widget build(BuildContext context) {
    final rawDisplay = grade.isIncomplete
        ? 'INC'
        : (grade.grade % 1 == 0
            ? '${grade.grade.toInt()}'
            : '${grade.grade}');
    final eqDisplay = grade.isIncomplete
        ? '→ 4.00'
        : '→ ${GradeModel.getSemestralEquivalent(grade.grade).toStringAsFixed(2)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          rawDisplay,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.1,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          eqDisplay,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String label;
  final Color color;
  const _LabelChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
