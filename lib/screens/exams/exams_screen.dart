import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/models/exam_model.dart';
import 'package:studentology/models/subject_model.dart';
import 'package:studentology/core/navigation/slide_route.dart';
import 'package:studentology/providers/auth_provider.dart';
import 'package:studentology/providers/exam_provider.dart';
import 'package:studentology/providers/schedule_provider.dart';
import 'package:studentology/providers/subject_provider.dart';
import 'package:studentology/screens/exams/exam_detail_screen.dart';
import 'package:studentology/widgets/task_card.dart' show SelectCircleCheckbox;

Future<bool?> _showDeleteConfirmation(
  BuildContext context,
  String itemName,
  bool isActive,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                spreadRadius: 0,
                offset: Offset(5, 5)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete $itemName?',
                style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Theme.of(ctx).textTheme.bodyLarge!.color),
              ),
              const SizedBox(height: 12),
              Text(
                isActive
                    ? 'This item is still active. Are you sure you want to delete it?'
                    : 'This will permanently remove this item from your records.',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(ctx).textTheme.bodySmall!.color,
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF5350),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    side: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  child: Text('Delete',
                      style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor:
                        Theme.of(ctx).textTheme.bodyLarge!.color,
                  ),
                  child: Text('Cancel',
                      style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Theme.of(ctx).textTheme.bodyLarge!.color)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ── ExamsScreen ────────────────────────────────────────────────────────────

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isSelectMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_isSelectMode) _exitSelectMode();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onLongPress(String id) {
    setState(() {
      _isSelectMode = true;
      _selectedIds.add(id);
    });
  }

  void _onSelectTap(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelectMode() {
    if (!_isSelectMode) return;
    setState(() {
      _isSelectMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await _showDeleteConfirmation(
      context,
      '$count item${count == 1 ? '' : 's'}',
      false,
    );
    if (confirmed != true || !mounted) return;
    final ep = context.read<ExamProvider>();
    final ids = Set<String>.from(_selectedIds);
    _exitSelectMode();
    for (final id in ids) {
      await ep.deleteExam(id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count item${count == 1 ? '' : 's'} deleted'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
      ),
    );
  }

  void _openForm([ExamModel? exam]) {
    final userId = context.read<AuthProvider>().userId ?? '';

    SubjectModel? initialSubject;
    if (exam?.subjectId != null) {
      final subjects = context.read<SubjectProvider>().subjects;
      try {
        initialSubject =
            subjects.firstWhere((s) => s.id == exam!.subjectId);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExamFormSheet(
        exam: exam,
        initialSubject: initialSubject,
        userId: userId,
      ),
    );
  }

  void _showScoreDialog(BuildContext ctx, ExamModel exam) {
    showDialog(
      context: ctx,
      builder: (_) => _ScoreDialog(exam: exam),
    );
  }

  Widget _buildActionBar() {
    return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.1), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 0,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              '${_selectedIds.length} item${_selectedIds.length == 1 ? '' : 's'} selected',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall!.color,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white, size: 18),
              label: Text(
                'Delete',
                style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                disabledBackgroundColor: Colors.grey.shade400,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
                side: BorderSide(
                    color: Colors.black.withOpacity(0.15), width: 1.5),
              ),
            ),
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<ExamProvider>();
    final currentExams = _tabController.index == 0
        ? ep.upcomingExams
        : ep.pastExams.reversed.toList();
    final allSelected =
        _selectedIds.length == currentExams.length && currentExams.isNotEmpty;
    return PopScope(
      canPop: !_isSelectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelectMode) _exitSelectMode();
      },
      child: Scaffold(
      appBar: _isSelectMode
          ? AppBar(
              automaticallyImplyLeading: false,
              centerTitle: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              leading: TextButton(
                onPressed: () => setState(() {
                  _isSelectMode = false;
                  _selectedIds.clear();
                }),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryAccent,
                    fontSize: 15,
                  ),
                ),
              ),
              leadingWidth: 90,
              title: Text(
                '${_selectedIds.length} Selected',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (allSelected) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds =
                            currentExams.map((e) => e.id).toSet();
                      }
                    });
                  },
                  child: Text(
                    allSelected ? 'Deselect All' : 'Select All',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryAccent,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Upcoming (${ep.upcomingExams.length})'),
                    Tab(text: 'Past (${ep.pastExams.length})'),
                  ],
                ),
              ),
            )
          : AppBar(
              backgroundColor: context.bgColor,
              elevation: 0,
              iconTheme: IconThemeData(color: context.textPrimary),
              title: Text(
                'Exams',
                style: GoogleFonts.ultra(color: context.textPrimary),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Consumer<ExamProvider>(
                  builder: (_, ep, __) => TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: 'Upcoming (${ep.upcomingExams.length})'),
                      Tab(text: 'Past (${ep.pastExams.length})'),
                    ],
                  ),
                ),
              ),
            ),
      body: Consumer<ExamProvider>(
        builder: (_, ep, __) => Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ExamList(
                    exams: ep.upcomingExams,
                    emptyIcon: Icons.event_available_outlined,
                    emptyMessage: 'No upcoming exams. Enjoy the break!',
                    onEdit: _openForm,
                    onAddScore: _showScoreDialog,
                    isSelectMode: _isSelectMode,
                    selectedIds: _selectedIds,
                    onLongPress: _onLongPress,
                    onSelectTap: _onSelectTap,
                  ),
                  _ExamList(
                    exams: ep.pastExams.reversed.toList(),
                    emptyIcon: Icons.history_edu_outlined,
                    emptyMessage: 'No past exams recorded yet.',
                    onEdit: _openForm,
                    onAddScore: _showScoreDialog,
                    isSelectMode: _isSelectMode,
                    selectedIds: _selectedIds,
                    onLongPress: _onLongPress,
                    onSelectTap: _onSelectTap,
                  ),
                ],
              ),
            ),
            if (_isSelectMode) _buildActionBar(),
          ],
        ),
      ),
      floatingActionButton: _isSelectMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Exam'),
            ),
      ),
    );
  }
}

// ── Exam list ──────────────────────────────────────────────────────────────

class _ExamList extends StatelessWidget {
  final List<ExamModel> exams;
  final IconData emptyIcon;
  final String emptyMessage;
  final void Function([ExamModel?]) onEdit;
  final void Function(BuildContext, ExamModel) onAddScore;
  final bool isSelectMode;
  final Set<String> selectedIds;
  final void Function(String) onLongPress;
  final void Function(String) onSelectTap;

  const _ExamList({
    required this.exams,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.onEdit,
    required this.onAddScore,
    required this.isSelectMode,
    required this.selectedIds,
    required this.onLongPress,
    required this.onSelectTap,
  });

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 48, color: context.textSecondary),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: exams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final exam = exams[i];
        final isSelected = selectedIds.contains(exam.id);
        return _ExamCard(
          exam: exam,
          selectMode: isSelectMode,
          isSelected: isSelected,
          onAddScore: isSelectMode ? null : () => onAddScore(ctx, exam),
          onLongPress: isSelectMode ? null : () => onLongPress(exam.id),
          onSelectTap: () => onSelectTap(exam.id),
          onTap: () async {
            final action =
                await Navigator.of(ctx).push<ExamDetailAction>(
              slideRoute(ExamDetailScreen(exam: exam)),
            );
            if (!ctx.mounted) return;
            if (action == ExamDetailAction.edit) onEdit(exam);
            if (action == ExamDetailAction.addScore) {
              onAddScore(ctx, exam);
            }
          },
        );
      },
    );
  }
}

// ── Exam card (local) ──────────────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  final VoidCallback? onAddScore;
  final VoidCallback? onTap;
  final bool selectMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectTap;

  const _ExamCard({
    required this.exam,
    this.onAddScore,
    this.onTap,
    this.selectMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onSelectTap,
  });

  String _formatScheduled(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = d.hour > 12
        ? d.hour - 12
        : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day}, ${d.year}  $h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final daysUntil = exam.daysUntil;
    final isUrgent = !exam.isPast && daysUntil <= 3;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final BoxDecoration decoration = selectMode
        ? BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFB347).withOpacity(0.08)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isUrgent
                  ? AppTheme.warningColor
                  : (isDark
                      ? AppTheme.cartoonBorderDark
                      : AppTheme.cartoonBorder),
              width: isUrgent ? 2.0 : 1.5,
            ),
            boxShadow:
                isDark ? const [] : AppTheme.cartoonShadow,
          );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: selectMode ? onSelectTap : onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectMode) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 10),
                      child: SelectCircleCheckbox(isSelected: isSelected),
                    ),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Hero(
                                    tag: 'exam-subject-${exam.id}',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Text(
                                        exam.subjectName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primaryAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(exam.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!selectMode && exam.hasScore)
                              _ScoreBadge(exam: exam),
                            if (!selectMode && isUrgent)
                              _UrgencyChip(daysUntil: daysUntil),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 14,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!selectMode && exam.isPast && !exam.hasScore) ...[
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'No score yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: onAddScore,
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: const Text('Add Score'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryAccent,
                        side: const BorderSide(
                            color: AppTheme.primaryAccent, width: 1.5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final ExamModel exam;
  const _ScoreBadge({required this.exam});

  @override
  Widget build(BuildContext context) {
    final passed = (exam.percentage ?? 0) >= 75;
    final color = passed ? AppTheme.successColor : AppTheme.errorColor;
    final scoreText =
        '${_clean(exam.score!)}/${_clean(exam.totalScore!)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        scoreText,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  static String _clean(double d) =>
      d == d.truncateToDouble() ? d.toInt().toString() : d.toString();
}

class _UrgencyChip extends StatelessWidget {
  final int daysUntil;
  const _UrgencyChip({required this.daysUntil});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        daysUntil == 0 ? 'Today' : 'In ${daysUntil}d',
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.warningColor,
          fontWeight: FontWeight.w600,
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
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
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

// ── Score dialog ───────────────────────────────────────────────────────────

class _ScoreDialog extends StatefulWidget {
  final ExamModel exam;
  const _ScoreDialog({required this.exam});

  @override
  State<_ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends State<_ScoreDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _scoreCtrl;
  late final TextEditingController _totalCtrl;

  static String _numStr(double? d) {
    if (d == null) return '';
    return d == d.truncateToDouble()
        ? d.toInt().toString()
        : d.toString();
  }

  @override
  void initState() {
    super.initState();
    _scoreCtrl = TextEditingController(text: _numStr(widget.exam.score));
    _totalCtrl =
        TextEditingController(text: _numStr(widget.exam.totalScore));
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final score = double.parse(_scoreCtrl.text);
    final total = double.parse(_totalCtrl.text);
    await context
        .read<ExamProvider>()
        .addScore(widget.exam.id, score, total);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                spreadRadius: 0,
                offset: Offset(5, 5)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Score',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Theme.of(context).textTheme.bodyLarge!.color),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.exam.title,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall!.color),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _scoreCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Your Score'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '/',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _totalCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Total'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final n = double.tryParse(v);
                          if (n == null || n <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Consumer<ExamProvider>(
                  builder: (_, ep, __) => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ep.isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        side: const BorderSide(
                            color: Colors.black, width: 1.5),
                      ),
                      child: ep.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Save',
                              style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 15)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 1.5),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor:
                          Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .color)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Exam form bottom sheet ─────────────────────────────────────────────────

class _ExamFormSheet extends StatefulWidget {
  final ExamModel? exam;
  final SubjectModel? initialSubject;
  final String userId;

  const _ExamFormSheet({this.exam, this.initialSubject, required this.userId});

  @override
  State<_ExamFormSheet> createState() => _ExamFormSheetState();
}

class _ExamFormSheetState extends State<_ExamFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subjectNameCtrl;
  late final TextEditingController _roomCtrl;
  late final TextEditingController _seatCtrl;
  late final TextEditingController _notesCtrl;

  SubjectModel? _selectedSubject;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  bool get _isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    final e = widget.exam;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _subjectNameCtrl = TextEditingController(
      text: widget.initialSubject?.name ?? e?.subjectName ?? '',
    );
    _roomCtrl = TextEditingController(text: e?.room ?? '');
    _seatCtrl = TextEditingController(text: e?.seatNumber ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _selectedSubject = widget.initialSubject;
    _selectedDate =
        e?.examDate ?? DateTime.now().add(const Duration(days: 7));
    _selectedTime =
        e?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectNameCtrl.dispose();
    _roomCtrl.dispose();
    _seatCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final subjectName =
        _selectedSubject?.name ?? _subjectNameCtrl.text.trim();
    final subjectId = _selectedSubject?.id;
    final ep = context.read<ExamProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (_isEditing) {
      await ep.updateExam(
        widget.exam!.copyWith(
          title: _titleCtrl.text.trim(),
          subjectId: subjectId,
          subjectName: subjectName,
          examDate: _selectedDate,
          startTime: _selectedTime,
          room: _roomCtrl.text.trim(),
          seatNumber: _seatCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        ),
      );
    } else {
      await ep.addExam(
        ExamModel(
          id: '',
          userId: widget.userId,
          subjectId: subjectId,
          subjectName: subjectName,
          title: _titleCtrl.text.trim(),
          examDate: _selectedDate,
          startTime: _selectedTime,
          room: _roomCtrl.text.trim(),
          seatNumber: _seatCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
    }

    if (!mounted) return;

    if (ep.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(ep.errorMessage!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      ep.clearError();
      return;
    }

    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Exam updated!' : 'Exam added!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPad),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? 'Edit Exam' : 'Add Exam',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _SheetTextField(
                controller: _titleCtrl,
                label: 'Exam Title',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('Subject'),
              const SizedBox(height: 8),
              Consumer2<SubjectProvider, ScheduleProvider>(
                builder: (_, sp, schedProv, __) {
                  final scheduleIds =
                      schedProv.schedules.map((s) => s.id).toSet();
                  final subjects = sp.subjects
                      .where((s) =>
                          s.scheduleId.isEmpty ||
                          scheduleIds.contains(s.scheduleId))
                      .toList();
                  if (_selectedSubject != null &&
                      !subjects
                          .any((s) => s.id == _selectedSubject!.id)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedSubject = null);
                    });
                  }
                  if (subjects.isEmpty) {
                    return _SheetTextField(
                      controller: _subjectNameCtrl,
                      label: 'Subject Name',
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SheetDropdown<SubjectModel?>(
                        value: _selectedSubject,
                        hint: 'Select subject',
                        items: [
                          const DropdownMenuItem<SubjectModel?>(
                            value: null,
                            child: Text('Custom...'),
                          ),
                          ...subjects.map(
                            (s) => DropdownMenuItem<SubjectModel?>(
                              value: s,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: s.displayColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(s.name),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _selectedSubject = v;
                          if (v != null) _subjectNameCtrl.text = v.name;
                        }),
                      ),
                      if (_selectedSubject == null) ...[
                        const SizedBox(height: 10),
                        _SheetTextField(
                          controller: _subjectNameCtrl,
                          label: 'Subject Name',
                          validator: (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Date'),
                        const SizedBox(height: 8),
                        _DateTile(
                            date: _selectedDate, onTap: _pickDate),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Start Time'),
                        const SizedBox(height: 8),
                        _TimeTile(
                            time: _selectedTime, onTap: _pickTime),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SheetTextField(
                      controller: _roomCtrl,
                      label: 'Room (optional)',
                      hint: 'e.g. 301',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetTextField(
                      controller: _seatCtrl,
                      label: 'Seat (optional)',
                      hint: 'e.g. A-12',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SheetTextField(
                controller: _notesCtrl,
                label: 'Notes (optional)',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Consumer<ExamProvider>(
                builder: (_, ep, __) => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: ep.isLoading ? null : _submit,
                    child: ep.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : Text(
                            _isEditing ? 'Save Changes' : 'Add Exam'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Form helper widgets ────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final int? maxLines;

  const _SheetTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(color: cs.onSurface, fontSize: 15),
      cursorColor: AppTheme.primaryAccent,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        fillColor: cs.surface,
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.outline)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.outline)),
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide:
                BorderSide(color: AppTheme.primaryAccent, width: 1.5)),
        errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: AppTheme.errorColor)),
        focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide:
                BorderSide(color: AppTheme.errorColor, width: 1.5)),
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        floatingLabelStyle:
            const TextStyle(color: AppTheme.primaryAccent, fontSize: 12),
        errorStyle:
            const TextStyle(color: AppTheme.errorColor, fontSize: 12),
      ),
    );
  }
}

class _SheetDropdown<T> extends StatelessWidget {
  final T value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _SheetDropdown({
    required this.value,
    this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      value: value,
      hint: hint != null
          ? Text(hint!,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15))
          : null,
      items: items,
      onChanged: onChanged,
      dropdownColor: cs.surface,
      style: TextStyle(color: cs.onSurface, fontSize: 15),
      icon: Icon(Icons.expand_more_rounded, color: cs.onSurfaceVariant),
      decoration: InputDecoration(
        fillColor: cs.surface,
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: cs.outline)),
        enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: cs.outline)),
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide:
                BorderSide(color: AppTheme.primaryAccent, width: 1.5)),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DateTile({required this.date, required this.onTap});

  static String _format(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppTheme.primaryAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _format(date),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeTile({required this.time, required this.onTap});

  String _format(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_outlined,
                size: 16, color: AppTheme.primaryAccent),
            const SizedBox(width: 8),
            Text(
              _format(time),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
