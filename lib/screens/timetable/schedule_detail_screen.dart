import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/models/schedule_model.dart';
import 'package:studentology/models/subject_model.dart';
import 'package:studentology/providers/auth_provider.dart';
import 'package:studentology/providers/subject_provider.dart';
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

// ── Schedule Detail Screen ─────────────────────────────────────────────────

class ScheduleDetailScreen extends StatefulWidget {
  final ScheduleModel schedule;

  const ScheduleDetailScreen({super.key, required this.schedule});

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  bool _selectMode = false;
  Set<String> _selectedIds = {};
  String _selectedDay = 'ALL';

  static const _dayLabels = [
    '', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static int _chipToDay(String chip) {
    const map = {'MON': 1, 'TUE': 2, 'WED': 3, 'THU': 4, 'FRI': 5, 'SAT': 6, 'SUN': 7};
    return map[chip] ?? 1;
  }

  void _onLongPress(String id) {
    setState(() {
      _selectMode = true;
      _selectedDay = 'ALL';
      _selectedIds.add(id);
    });
  }

  void _onSelectTap(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final sp = context.read<SubjectProvider>();
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
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
                  'Delete $count item${count == 1 ? '' : 's'}?',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Theme.of(ctx).textTheme.bodyLarge!.color),
                ),
                const SizedBox(height: 12),
                Text(
                  'This will permanently remove the selected subjects.',
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
                      foregroundColor: Theme.of(ctx).textTheme.bodyLarge!.color,
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
    if (confirmed != true || !mounted) return;
    final ids = List<String>.from(_selectedIds);
    _exitSelectMode();
    for (final id in ids) {
      await sp.deleteSubject(id);
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

  void _openAddSubjectSheet() {
    final userId = context.read<AuthProvider>().userId ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSubjectSheet(
        userId: userId,
        scheduleId: widget.schedule.id,
      ),
    );
  }


  Widget _subjectCard(
    SubjectModel subject,
    SubjectProvider sp,
    BuildContext ctx,
  ) {
    final isSelected = _selectedIds.contains(subject.id);
    return GestureDetector(
      onLongPress: _selectMode ? null : () => _onLongPress(subject.id),
      onTap: _selectMode ? () => _onSelectTap(subject.id) : null,
      child: _SubjectDetailCard(
        subject: subject,
        selectMode: _selectMode,
        isSelected: isSelected,
        onDelete: () async {
          final confirmed =
              await _showDeleteConfirmation(ctx, subject.name, true);
          if (confirmed == true) sp.deleteSubject(subject.id);
        },
      ),
    );
  }

  Widget _buildGroupedListView(
    List<SubjectModel> subjects,
    SubjectProvider sp,
    BuildContext ctx,
  ) {
    final grouped = <int, List<SubjectModel>>{};
    for (final s in subjects) {
      grouped.putIfAbsent(s.dayOfWeek, () => []).add(s);
    }
    for (final list in grouped.values) {
      list.sort((a, b) =>
          (a.startTime.hour * 60 + a.startTime.minute)
              .compareTo(b.startTime.hour * 60 + b.startTime.minute));
    }

    final items = <Widget>[];
    for (int day = 1; day <= 7; day++) {
      final daySubjects = grouped[day];
      if (daySubjects == null || daySubjects.isEmpty) continue;
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB347),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _dayLabels[day],
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFFB347),
                ),
              ),
            ],
          ),
        ),
      );
      for (final subject in daySubjects) {
        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _subjectCard(subject, sp, ctx),
          ),
        );
      }
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: items,
    );
  }

  Widget _buildFilteredListView(
    List<SubjectModel> subjects,
    SubjectProvider sp,
    BuildContext ctx,
  ) {
    final dayInt = _chipToDay(_selectedDay);
    final filtered = subjects.where((s) => s.dayOfWeek == dayInt).toList()
      ..sort((a, b) =>
          (a.startTime.hour * 60 + a.startTime.minute)
              .compareTo(b.startTime.hour * 60 + b.startTime.minute));

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined, size: 40, color: ctx.textSecondary),
            const SizedBox(height: 10),
            Text(
              'No subjects on $_selectedDay',
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ctx.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _subjectCard(filtered[i], sp, ctx),
    );
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_selectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectMode) _exitSelectMode();
      },
      child: Consumer<SubjectProvider>(
      builder: (ctx, sp, __) {
        final subjects = sp.getSubjectsForSchedule(widget.schedule.id);

        final appBar = _selectMode
            ? AppBar(
                backgroundColor: ctx.bgColor,
                elevation: 0,
                automaticallyImplyLeading: false,
                centerTitle: true,
                title: Text(
                  '${_selectedIds.length} Selected',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    color: ctx.textPrimary,
                  ),
                ),
                leading: TextButton(
                  onPressed: () => setState(() {
                    _selectMode = false;
                    _selectedIds.clear();
                  }),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryAccent,
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => setState(
                      () => _selectedIds = subjects.map((s) => s.id).toSet(),
                    ),
                    child: Text(
                      'Select All',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                  ),
                ],
              )
            : AppBar(
                backgroundColor: ctx.bgColor,
                elevation: 0,
                iconTheme: IconThemeData(color: ctx.textPrimary),
                title: Text(
                  widget.schedule.name,
                  style: GoogleFonts.ultra(color: ctx.textPrimary),
                ),
              );

        return Scaffold(
          appBar: appBar,
          body: subjects.isEmpty
              ? const _EmptySubjects()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Row(
                        children: [
                          for (final day in [
                            'ALL', 'MON', 'TUE', 'WED', 'THU',
                            'FRI', 'SAT', 'SUN',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(
                                  day,
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedDay == day
                                        ? Colors.white
                                        : ctx.textSecondary,
                                  ),
                                ),
                                selected: _selectedDay == day,
                                onSelected: (_) =>
                                    setState(() => _selectedDay = day),
                                selectedColor: AppTheme.primaryAccent,
                                backgroundColor: ctx.cardBg,
                                showCheckmark: false,
                                shape: const StadiumBorder(),
                                side: BorderSide(
                                  color: _selectedDay == day
                                      ? AppTheme.primaryAccent
                                      : ctx.cardBorder,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _selectedDay == 'ALL'
                          ? _buildGroupedListView(subjects, sp, ctx)
                          : _buildFilteredListView(subjects, sp, ctx),
                    ),
                  ],
                ),
          floatingActionButton: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: _selectMode
                ? FloatingActionButton(
                    key: const ValueKey('delete-fab'),
                    onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                    backgroundColor: const Color(0xFFEF5350),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  )
                : FloatingActionButton.extended(
                    key: const ValueKey('add-fab'),
                    onPressed: _openAddSubjectSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Subject'),
                  ),
          ),
        );
      },
      ),
    );
  }
}

// ── Subject detail card ────────────────────────────────────────────────────

class _SubjectDetailCard extends StatelessWidget {
  final SubjectModel subject;
  final bool selectMode;
  final bool isSelected;
  final VoidCallback onDelete;

  const _SubjectDetailCard({
    required this.subject,
    required this.selectMode,
    required this.isSelected,
    required this.onDelete,
  });

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  static const _dayNames = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _subtitleText() {
    final parts = <String>[
      if (subject.code.isNotEmpty) subject.code,
      _dayNames[subject.dayOfWeek],
      '${_formatTime(subject.startTime)} – ${_formatTime(subject.endTime)}',
      if (subject.room.isNotEmpty) subject.room,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor =
        isDark ? AppTheme.cartoonBorderDark : AppTheme.cartoonBorder;
    final subjectColor = subject.displayColor;
    final secondary =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.52);

    final decoration = selectMode
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
            boxShadow: isSelected ? const [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 0,
                offset: const Offset(3, 3),
              ),
            ],
          )
        : BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: outlineColor, width: 1.5),
            boxShadow: isDark ? const [] : AppTheme.cartoonShadow,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: decoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (selectMode) ...[
            SelectCircleCheckbox(isSelected: isSelected),
            const SizedBox(width: 10),
          ],
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: subjectColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
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
        ],
      ),
    );
  }
}

// ── Empty subjects state ───────────────────────────────────────────────────

class _EmptySubjects extends StatelessWidget {
  const _EmptySubjects();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.book_outlined,
              size: 52,
              color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text('No subjects added yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Tap + to add! 📖',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Subject bottom sheet ───────────────────────────────────────────────

class _AddSubjectSheet extends StatefulWidget {
  final String userId;
  final String scheduleId;

  const _AddSubjectSheet({
    required this.userId,
    required this.scheduleId,
  });

  @override
  State<_AddSubjectSheet> createState() => _AddSubjectSheetState();
}

class _AddSubjectSheetState extends State<_AddSubjectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();

  late Color _selectedColor;
  late int _selectedDay;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);

  static const _presetColors = [
    Color(0xFFFFB347), // orange
    Color(0xFF7C4DFF), // purple
    Color(0xFFFF6B6B), // coral
    Color(0xFF26C6DA), // teal
    Color(0xFF42A5F5), // blue
    Color(0xFF66BB6A), // green
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = _presetColors.first;
    _selectedDay = DateTime.now().weekday.clamp(1, 7);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  bool _endAfterStart() {
    return (_endTime.hour * 60 + _endTime.minute) >
        (_startTime.hour * 60 + _startTime.minute);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_endAfterStart()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final sp = context.read<SubjectProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await sp.addSubject(
      SubjectModel(
        id: '',
        userId: widget.userId,
        scheduleId: widget.scheduleId,
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        color: _selectedColor.value,
        weekType: WeekType.both,
        dayOfWeek: _selectedDay,
        startTime: _startTime,
        endTime: _endTime,
        room: _roomCtrl.text.trim(),
      ),
    );

    if (!mounted) return;
    if (sp.errorMessage != null) {
      messenger.showSnackBar(SnackBar(
        content: Text(sp.errorMessage!),
        backgroundColor: AppTheme.errorColor,
      ));
      sp.clearError();
      return;
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Subject added!')));
  }

  static String _dayName(int d) {
    const names = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return d >= 1 && d <= 7 ? names[d] : '';
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
                'Add Subject',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              _FormTextField(
                controller: _nameCtrl,
                label: 'Subject Name *',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              _FormTextField(
                controller: _codeCtrl,
                label: 'Subject Code *',
                hint: 'e.g. CS 401',
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 18),

              const _FieldLabel('Color'),
              const SizedBox(height: 10),
              Row(
                children: _presetColors
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedColor = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColor.value == c.value
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: _selectedColor.value == c.value
                                    ? [
                                        BoxShadow(
                                          color: c.withOpacity(0.55),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 18),

              const _FieldLabel('Day of Week'),
              const SizedBox(height: 8),
              _FormDropdown<int>(
                value: _selectedDay,
                items: [
                  for (int i = 1; i <= 7; i++)
                    DropdownMenuItem(value: i, child: Text(_dayName(i))),
                ],
                onChanged: (v) => setState(() => _selectedDay = v!),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: 'Start',
                      time: _startTime,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeTile(
                      label: 'End',
                      time: _endTime,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _FormTextField(
                controller: _roomCtrl,
                label: 'Room (optional)',
                hint: 'e.g. Room 301',
              ),
              const SizedBox(height: 24),

              Consumer<SubjectProvider>(
                builder: (_, sp, __) => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: sp.isLoading ? null : _submit,
                    child: sp.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : const Text('Add Subject'),
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

class _FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const _FormTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.textCapitalization = TextCapitalization.words,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      validator: validator,
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
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppTheme.primaryAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppTheme.errorColor, width: 1.5),
        ),
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        floatingLabelStyle:
            const TextStyle(color: AppTheme.primaryAccent, fontSize: 12),
        errorStyle:
            const TextStyle(color: AppTheme.errorColor, fontSize: 12),
      ),
    );
  }
}

class _FormDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _FormDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      value: value,
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
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide:
              BorderSide(color: AppTheme.primaryAccent, width: 1.5),
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: AppTheme.primaryAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  _format(time),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
