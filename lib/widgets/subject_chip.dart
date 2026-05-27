import 'package:flutter/material.dart';
import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/models/subject_model.dart';

class SubjectChip extends StatelessWidget {
  final SubjectModel subject;
  final bool isSelected;
  final VoidCallback onTap;

  const SubjectChip({
    super.key,
    required this.subject,
    required this.isSelected,
    required this.onTap,
  });

  // Use the subject code when available; otherwise abbreviate the name.
  String get _label {
    if (subject.code.isNotEmpty) return subject.code;
    final name = subject.name;
    return name.length > 6 ? name.substring(0, 6) : name;
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = subject.displayColor;
    final borderColor = isSelected
        ? AppTheme.primaryAccent
        : subjectColor.withOpacity(0.4);
    final bgColor = isSelected
        ? subjectColor
        : subjectColor.withOpacity(0.13);
    final textColor = isSelected ? Colors.white : subjectColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          _label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
