import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/models/subject_model.dart';
import 'package:studentology/providers/auth_provider.dart';
import 'package:studentology/providers/subject_provider.dart';
import 'package:studentology/widgets/task_card.dart' show SelectCircleCheckbox;

// ── TimetableScreen ────────────────────────────────────────────────────────

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String _selectedWeek = 'Both';
  String _selectedDay = 'Mon';

  bool _selectMode = false;
  Set<String> _selectedSubjectIds = {};

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _dayMap = {
    'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6, 'Sun': 7,
  };

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday;
    _selectedDay = _days[(today.clamp(1, 7)) - 1];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) context.read<SubjectProvider>().init(userId);
    });
  }

  // ── Select mode ──────────────────────────────────────────────────────────

  void _onLongPress(String id) {
    setState(() {
      _selectMode = true;
      _selectedSubjectIds.add(id);
    });
  }

  void _onSelectTap(String id) {
    setState(() {
      if (_selectedSubjectIds.contains(id)) {
        _selectedSubjectIds.remove(id);
        if (_selectedSubjectIds.isEmpty) _selectMode = false;
      } else {
        _selectedSubjectIds.add(id);
      }
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selectedSubjectIds.clear();
    });
  }

  // ── Filtering ────────────────────────────────────────────────────────────

  List<SubjectModel> _filteredSubjects(List<SubjectModel> all) {
    final dayNumber = _dayMap[_selectedDay]!;
    return all.where((s) {
      final dayMatch = s.dayOfWeek == dayNumber;
      final weekMatch = _selectedWeek == 'Both'
          ? true
          : _selectedWeek == 'Week A'
              ? s.weekType == WeekType.weekA || s.weekType == WeekType.both
              : s.weekType == WeekType.weekB || s.weekType == WeekType.both;
      return dayMatch && weekMatch;
    }).toList()
      ..sort((a, b) {
          final aTime = a.startTime.hour * 60 + a.startTime.minute;
          final bTime = b.startTime.hour * 60 + b.startTime.minute;
          return aTime.compareTo(bTime);
        });
  }

  // ── Delete selected ──────────────────────────────────────────────────────

  Future<void> _deleteSelected(SubjectProvider sp) async {
    final count = _selectedSubjectIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF5350),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    side: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
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
                  onPressed: () => Navigator.of(ctx).pop(false),
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
    );
    if (confirmed != true || !mounted) return;
    final ids = Set<String>.from(_selectedSubjectIds);
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

  // ── Open form ────────────────────────────────────────────────────────────

  void _openAddSubjectSheet() {
    final userId = context.read<AuthProvider>().userId ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSubjectSheet(
        userId: userId,
        initialDay: _dayMap[_selectedDay]!,
        initialWeek: _selectedWeek,
      ),
    );
  }

  // ── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildWeekToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
        ],
      ),
      child: Row(
        children: ['Week A', 'Week B', 'Both'].map((label) {
          final isSelected = _selectedWeek == label;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectMode) _exitSelectMode();
                setState(() => _selectedWeek = label);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFB347)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: _days.map((day) {
          final isSelected = _selectedDay == day;
          return GestureDetector(
            onTap: () {
              if (_selectMode) _exitSelectMode();
              setState(() => _selectedDay = day);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? const Color(0xFFFFB347)
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                day,
                style: GoogleFonts.inter(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 14,
                  color: isSelected
                      ? const Color(0xFFFFB347)
                      : Theme.of(context).textTheme.bodySmall!.color,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(List<SubjectModel> filtered) {
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 52, color: context.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No classes this day',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap + to add a subject',
                style: GoogleFonts.inter(
                    fontSize: 14, color: context.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final subject = filtered[i];
        final isSelected = _selectedSubjectIds.contains(subject.id);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: _selectMode ? null : () => _onLongPress(subject.id),
          onTap: _selectMode ? () => _onSelectTap(subject.id) : null,
          child: _SubjectPillCard(
            subject: subject,
            selectMode: _selectMode,
            isSelected: isSelected,
          ),
        );
      },
    );
  }

  Widget _buildActionBar(SubjectProvider sp) {
    final count = _selectedSubjectIds.length;
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
              '$count item${count == 1 ? '' : 's'} selected',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodySmall!.color,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: count == 0 ? null : () => _deleteSelected(sp),
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white, size: 18),
              label: Text('Delete',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w700, color: Colors.white)),
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<SubjectProvider>(
      builder: (ctx, sp, __) {
        final filtered = _filteredSubjects(sp.subjects.toList());
        final allSelected =
            _selectedSubjectIds.length == filtered.length && filtered.isNotEmpty;

        return PopScope(
          canPop: !_selectMode,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _selectMode) _exitSelectMode();
          },
          child: Scaffold(
            appBar: _selectMode
                ? AppBar(
                    automaticallyImplyLeading: false,
                    centerTitle: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    elevation: 0,
                    leading: TextButton(
                      onPressed: _exitSelectMode,
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
                      '${_selectedSubjectIds.length} Selected',
                      style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => setState(() {
                          if (allSelected) {
                            _selectedSubjectIds.clear();
                          } else {
                            _selectedSubjectIds =
                                filtered.map((s) => s.id).toSet();
                          }
                        }),
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
                  )
                : AppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: context.bgColor,
                    elevation: 0,
                    title: Text('Timetable',
                        style: GoogleFonts.ultra(color: context.textPrimary)),
                  ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeekToggle(),
                _buildDayTabs(),
                const Divider(height: 1),
                Expanded(
                  child: sp.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(filtered),
                ),
                if (_selectMode) _buildActionBar(sp),
              ],
            ),
            floatingActionButton: _selectMode
                ? null
                : FloatingActionButton.extended(
                    onPressed: _openAddSubjectSheet,
                    backgroundColor: const Color(0xFFFFB347),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(
                        side: BorderSide(color: Colors.black, width: 1.5)),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Add Subject',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

// ── Subject pill card ──────────────────────────────────────────────────────

class _SubjectPillCard extends StatelessWidget {
  final SubjectModel subject;
  final bool selectMode;
  final bool isSelected;

  const _SubjectPillCard({
    required this.subject,
    this.selectMode = false,
    this.isSelected = false,
  });

  static String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  String _subtitle() {
    final parts = <String>[
      if (subject.code.isNotEmpty) subject.code,
      '${_fmt(subject.startTime)} – ${_fmt(subject.endTime)}',
      if (subject.room.isNotEmpty) subject.room,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectColor = subject.displayColor;
    final secondary = Theme.of(context).colorScheme.onSurface.withOpacity(0.52);
    final outlineColor =
        isDark ? AppTheme.cartoonBorderDark : AppTheme.cartoonBorder;

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
            boxShadow: isDark ? const [] : AppTheme.cartoonShadow,
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
            decoration:
                BoxDecoration(color: subjectColor, shape: BoxShape.circle),
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
                  _subtitle(),
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

// ── Add Subject bottom sheet ───────────────────────────────────────────────

class _AddSubjectSheet extends StatefulWidget {
  final String userId;
  final int initialDay;
  final String initialWeek;

  const _AddSubjectSheet({
    required this.userId,
    required this.initialDay,
    required this.initialWeek,
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
  late String _selectedWeek;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);

  static const _presetColors = [
    Color(0xFFFFB347),
    Color(0xFF7C4DFF),
    Color(0xFFFF6B6B),
    Color(0xFF26C6DA),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
  ];

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

  @override
  void initState() {
    super.initState();
    _selectedColor = _presetColors.first;
    _selectedDay = widget.initialDay;
    _selectedWeek = widget.initialWeek;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  WeekType _weekTypeFromLabel(String label) {
    switch (label) {
      case 'Week A':
        return WeekType.weekA;
      case 'Week B':
        return WeekType.weekB;
      default:
        return WeekType.both;
    }
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
        name: _nameCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        color: _selectedColor.value,
        weekType: _weekTypeFromLabel(_selectedWeek),
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

  Widget _buildWeekToggle() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: cs.outline, width: 1.5),
      ),
      child: Row(
        children: ['Week A', 'Week B', 'Both'].map((label) {
          final isSelected = _selectedWeek == label;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedWeek = label),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFB347)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isSelected ? Colors.white : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
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
                    color: cs.outline,
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
                  color: cs.onSurface,
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
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedColor = c),
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
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),

              const _FieldLabel('Week'),
              const SizedBox(height: 8),
              _buildWeekToggle(),
              const SizedBox(height: 14),

              const _FieldLabel('Day of Week'),
              const SizedBox(height: 8),
              _FormDropdown<int>(
                value: _selectedDay,
                items: [
                  for (int i = 1; i <= 7; i++)
                    DropdownMenuItem(value: i, child: Text(_dayNames[i])),
                ],
                onChanged: (v) => setState(() => _selectedDay = v!),
                validator: (_) => null,
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
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
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppTheme.primaryAccent, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppTheme.errorColor, width: 1.5),
        ),
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        floatingLabelStyle:
            const TextStyle(color: AppTheme.primaryAccent, fontSize: 12),
        errorStyle: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
      ),
    );
  }
}

class _FormDropdown<T> extends StatelessWidget {
  final T value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const _FormDropdown({
    required this.value,
    this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
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
      validator: validator,
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
          borderSide: BorderSide(color: AppTheme.primaryAccent, width: 1.5),
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
                const Icon(Icons.schedule_outlined,
                    size: 16, color: AppTheme.primaryAccent),
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
