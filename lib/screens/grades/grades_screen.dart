import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/models/grade_model.dart';
import 'package:studentology/providers/auth_provider.dart';
import 'package:studentology/providers/grade_provider.dart';
import 'package:studentology/widgets/grade_tile.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  static const _prefKey = 'grading_system';

  String _gradingSystem = 'percentage';
  bool _systemLoaded = false;

  bool _isSelectMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadSystem();
  }

  Future<void> _loadSystem() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey) ?? 'percentage';
    if (mounted) {
      setState(() {
        _gradingSystem = saved;
        _systemLoaded = true;
      });
      context.read<GradeProvider>().setGradingSystem(saved);
    }
  }

  Future<void> _setSystem(String system) async {
    setState(() => _gradingSystem = system);
    context.read<GradeProvider>().setGradingSystem(system);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, system);
  }

  void _openForm(String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GradeFormSheet(
        gradingSystem: _gradingSystem,
        userId: userId,
      ),
    );
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
    setState(() {
      _isSelectMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
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
                  'This will permanently remove the selected grades.',
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
    if (confirmed != true || !mounted) return;
    final gp = context.read<GradeProvider>();
    final ids = List<String>.from(_selectedIds);
    _exitSelectMode();
    for (final id in ids) {
      await gp.deleteGrade(id);
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

  Widget _buildGWACard(List<GradeModel> grades, double? gwa, String system) {
    final hasGrades = grades.isNotEmpty && gwa != null;
    final gwaDisplay = hasGrades ? _formatGWA(gwa!, system) : '--';
    final gwaLabel = hasGrades
        ? GradeModel.getGWALabel(gwa!, system)
        : 'Add grades to see your GWA';
    final gwaColor =
        hasGrades ? GradeModel.getGWAColor(gwa!, system) : Colors.grey;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'General Weighted Average',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall!.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            gwaDisplay,
            style: GoogleFonts.ultra(fontSize: 42, color: gwaColor),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gwaColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  gwaLabel,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: gwaColor,
                  ),
                ),
              ),
              Text(
                '${grades.length} subject${grades.length == 1 ? '' : 's'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall!.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatGWA(double gwa, String system) {
    if (system == 'percentage') return '${gwa.toStringAsFixed(1)}%';
    return gwa.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    if (!_systemLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_isSelectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelectMode) _exitSelectMode();
      },
      child: Consumer2<GradeProvider, AuthProvider>(
      builder: (context, gp, auth, _) {
        final userId = auth.userId ?? '';
        final currentGrades = gp.gradesForSelectedTerm;
        final allSelected =
            _selectedIds.length == currentGrades.length && currentGrades.isNotEmpty;

        final appBar = _isSelectMode
            ? AppBar(
                backgroundColor: context.bgColor,
                elevation: 0,
                automaticallyImplyLeading: false,
                centerTitle: true,
                title: Text(
                  '${_selectedIds.length} Selected',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                leading: TextButton(
                  onPressed: () => setState(() {
                    _isSelectMode = false;
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
                leadingWidth: 90,
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (allSelected) {
                          _selectedIds.clear();
                        } else {
                          _selectedIds = currentGrades.map((g) => g.id).toSet();
                        }
                      });
                    },
                    child: Text(
                      allSelected ? 'Deselect All' : 'Select All',
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
                backgroundColor: context.bgColor,
                elevation: 0,
                iconTheme: IconThemeData(color: context.textPrimary),
                title: Text(
                  'Grades',
                  style: GoogleFonts.ultra(color: context.textPrimary),
                ),
              );

        return Scaffold(
          appBar: appBar,
          body: Column(
            children: [
              _SystemSelector(
                system: _gradingSystem,
                onChanged: _setSystem,
              ),
              _buildGWACard(
                gp.gradesForSelectedTerm,
                GradeModel.computeGWA(
                    gp.gradesForSelectedTerm, _gradingSystem),
                _gradingSystem,
              ),
              _TermFilter(gp: gp),
              Expanded(
                child: _GradeBody(
                  gp: gp,
                  gradingSystem: _gradingSystem,
                  isSelectMode: _isSelectMode,
                  selectedIds: _selectedIds,
                  onLongPress: _onLongPress,
                  onSelectTap: _onSelectTap,
                ),
              ),
            ],
          ),
          floatingActionButton: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: _isSelectMode
                ? FloatingActionButton(
                    key: const ValueKey('delete-fab'),
                    onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                    backgroundColor: const Color(0xFFEF5350),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  )
                : FloatingActionButton.extended(
                    key: const ValueKey('add-fab'),
                    onPressed: () => _openForm(userId),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Grade'),
                  ),
          ),
        );
      },
      ),
    );
  }
}

// ── Grading system selector ───────────────────────────────────────────────────

class _SystemSelector extends StatelessWidget {
  final String system;
  final ValueChanged<String> onChanged;
  const _SystemSelector({required this.system, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: DropdownButtonFormField<String>(
        value: system,
        decoration: InputDecoration(
          labelText: 'Grading System',
          prefixIcon: Icon(
            Icons.school_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          fillColor: context.inputFill,
          filled: true,
        ),
        items: const [
          DropdownMenuItem(
            value: 'percentage',
            child: Text('Percentage (60–100)'),
          ),
          DropdownMenuItem(
            value: 'semestral',
            child: Text('Semestral (UP Scale)'),
          ),
          DropdownMenuItem(
            value: 'trimestral',
            child: Text('Trimestral (NU Scale)'),
          ),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

// ── Term filter ───────────────────────────────────────────────────────────────

class _TermFilter extends StatelessWidget {
  final GradeProvider gp;
  const _TermFilter({required this.gp});

  @override
  Widget build(BuildContext context) {
    final terms = gp.availableTerms;
    if (terms.length <= 1) return const SizedBox.shrink();

    final selected =
        terms.contains(gp.selectedTerm) ? gp.selectedTerm : terms.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: DropdownButtonFormField<String>(
        value: selected,
        decoration: InputDecoration(
          labelText: 'Semester / Term',
          prefixIcon: Icon(
            Icons.filter_list_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          fillColor: context.inputFill,
          filled: true,
        ),
        items: terms
            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
            .toList(),
        onChanged: (t) {
          if (t != null) context.read<GradeProvider>().selectTerm(t);
        },
      ),
    );
  }
}

// ── Grade body ────────────────────────────────────────────────────────────────

class _GradeBody extends StatelessWidget {
  final GradeProvider gp;
  final String gradingSystem;
  final bool isSelectMode;
  final Set<String> selectedIds;
  final void Function(String id) onLongPress;
  final void Function(String id) onSelectTap;

  const _GradeBody({
    required this.gp,
    required this.gradingSystem,
    required this.isSelectMode,
    required this.selectedIds,
    required this.onLongPress,
    required this.onSelectTap,
  });

  @override
  Widget build(BuildContext context) {
    if (gp.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (gp.grades.isEmpty) {
      return const _EmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'No grades recorded',
        subtitle: 'Tap + to add your first grade entry.',
      );
    }

    final grades = gp.gradesForSelectedTerm;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        if (grades.isEmpty)
          const _EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No grades for this term',
            subtitle: 'Tap + to add a grade for this semester.',
          )
        else
          ...grades.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GradeTile(
                grade: g,
                gradingSystem: gradingSystem,
                onDelete: () => context.read<GradeProvider>().deleteGrade(g.id),
                selectMode: isSelectMode,
                isSelected: selectedIds.contains(g.id),
                onLongPress: isSelectMode ? null : () => onLongPress(g.id),
                onSelectTap: () => onSelectTap(g.id),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: context.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add grade form ────────────────────────────────────────────────────────────

class _GradeFormSheet extends StatefulWidget {
  final String gradingSystem;
  final String userId;
  const _GradeFormSheet({required this.gradingSystem, required this.userId});

  @override
  State<_GradeFormSheet> createState() => _GradeFormSheetState();
}

class _GradeFormSheetState extends State<_GradeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _schoolYearCtrl = TextEditingController();

  String _termType = 'Semester';
  String _termNumber = '1st';
  bool _isIncomplete = false;
  bool _isSaving = false;

  static const _termTypes = ['Semester', 'Trimester', 'Quarter'];

  List<String> get _termNumbers {
    switch (_termType) {
      case 'Trimester':
        return ['1st', '2nd', '3rd'];
      case 'Quarter':
        return ['1st', '2nd', '3rd', '4th'];
      default:
        return ['1st', '2nd', 'Summer'];
    }
  }

  String get _computedSemester {
    if (_termType == 'Trimester') return 'Term ${_ordinal(_termNumber)}';
    if (_termType == 'Quarter') return 'Quarter ${_ordinal(_termNumber)}';
    if (_termNumber == 'Summer') return 'Summer';
    return '$_termNumber Sem';
  }

  int _ordinal(String n) => const {'1st': 1, '2nd': 2, '3rd': 3, '4th': 4}[n] ?? 1;

  @override
  void initState() {
    super.initState();
    _schoolYearCtrl.text = _defaultSchoolYear();
    _schoolYearCtrl.addListener(() => setState(() {}));
    _gradeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _unitsCtrl.dispose();
    _gradeCtrl.dispose();
    _schoolYearCtrl.dispose();
    super.dispose();
  }

  String _defaultSchoolYear() {
    final now = DateTime.now();
    final y = now.month >= 8 ? now.year : now.year - 1;
    return '$y-${y + 1}';
  }

  String get _gradeLabel {
    switch (widget.gradingSystem) {
      case 'semestral':
        return 'Raw Grade (0–100) *';
      case 'trimestral':
        return 'Raw Grade (0–100) *';
      default:
        return 'Raw Grade (60–100) *';
    }
  }

  String get _gradeHint {
    switch (widget.gradingSystem) {
      case 'semestral':
        return 'e.g. 91';
      case 'trimestral':
        return 'e.g. 85';
      default:
        return 'e.g. 88';
    }
  }

  String? _validateGrade(String? val) {
    if (widget.gradingSystem == 'semestral' && _isIncomplete) return null;
    if (val == null || val.trim().isEmpty) return 'Required';
    final g = double.tryParse(val.trim());
    if (g == null) return 'Enter a valid number';
    switch (widget.gradingSystem) {
      case 'semestral':
        if (g < 0 || g > 100) return 'Enter 0–100';
      case 'trimestral':
        if (g < 0 || g > 100) return 'Enter 0–100';
      default:
        if (g < 60 || g > 100) return 'Enter 60–100';
    }
    return null;
  }

  String? _validateUnits(String? val) {
    if (val == null || val.trim().isEmpty) return 'Required';
    final u = double.tryParse(val.trim());
    if (u == null || u <= 0) return 'Enter a positive number';
    return null;
  }

  Widget _buildLivePreview() {
    final sys = widget.gradingSystem;
    final text = _gradeCtrl.text.trim();

    if (sys == 'semestral') {
      if (_isIncomplete) {
        return _PreviewChip(
          text: '= 4.00 — Conditional',
          color: const Color(0xFFFFC107),
        );
      }
      final g = double.tryParse(text);
      if (g == null || text.isEmpty) return const SizedBox.shrink();
      final eq = GradeModel.getSemestralEquivalent(g);
      final lbl = GradeModel.getEquivalentLabel(g, 'semestral');
      final col = GradeModel.getGWAColor(eq, 'semestral');
      return _PreviewChip(
        text: '= ${eq.toStringAsFixed(2)} — $lbl',
        color: col,
      );
    }

    if (sys == 'trimestral') {
      final g = double.tryParse(text);
      if (g == null || text.isEmpty) return const SizedBox.shrink();
      final eq = GradeModel.getNUEquivalent(g);
      final lbl = GradeModel.getEquivalentLabel(g, 'trimestral');
      final col = GradeModel.getGWAColor(eq, 'trimestral');
      return _PreviewChip(
        text: '= ${eq.toStringAsFixed(1)} — $lbl',
        color: col,
      );
    }

    final g = double.tryParse(text);
    if (g == null || text.isEmpty) return const SizedBox.shrink();
    final lbl = GradeModel.getEquivalentLabel(g, 'percentage');
    final col = GradeModel.getGWAColor(g, 'percentage');
    return _PreviewChip(text: lbl, color: col);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final gp = context.read<GradeProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final gradingSystem = GradingSystem.values.firstWhere(
      (g) => g.name == widget.gradingSystem,
      orElse: () => GradingSystem.percentage,
    );

    final gradeValue =
        _isIncomplete ? 0.0 : double.parse(_gradeCtrl.text.trim());

    final grade = GradeModel(
      id: '',
      userId: widget.userId,
      subjectName: _nameCtrl.text.trim(),
      subjectCode: _codeCtrl.text.trim(),
      units: double.parse(_unitsCtrl.text.trim()),
      grade: gradeValue,
      isIncomplete: _isIncomplete,
      gradingSystem: gradingSystem,
      semester: _computedSemester,
      schoolYear: _schoolYearCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    await gp.addGrade(grade);

    if (!mounted) return;
    if (gp.errorMessage != null) {
      setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(
        content: Text(gp.errorMessage!),
        backgroundColor: AppTheme.errorColor,
      ));
      gp.clearError();
      return;
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Grade added!')));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final sys = widget.gradingSystem;
    final isSemestral = sys == 'semestral';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text('Add Grade',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Subject Name *',
                  hintText: 'e.g. Mathematics',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Subject Code',
                  hintText: 'e.g. MATH101',
                ),
              ),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Units *',
                        hintText: 'e.g. 3',
                      ),
                      validator: _validateUnits,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _gradeCtrl,
                      enabled: !(isSemestral && _isIncomplete),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: InputDecoration(
                        labelText: _gradeLabel,
                        hintText: _gradeHint,
                      ),
                      validator: _validateGrade,
                    ),
                  ),
                ],
              ),

              if (isSemestral) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _isIncomplete = !_isIncomplete;
                    if (_isIncomplete) _gradeCtrl.clear();
                  }),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isIncomplete,
                        onChanged: (v) => setState(() {
                          _isIncomplete = v ?? false;
                          if (_isIncomplete) _gradeCtrl.clear();
                        }),
                      ),
                      const Text('Incomplete (INC) — 4.00'),
                    ],
                  ),
                ),
              ],

              if (_gradeCtrl.text.isNotEmpty || (isSemestral && _isIncomplete)) ...[
                const SizedBox(height: 8),
                _buildLivePreview(),
              ],
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _termType,
                      decoration:
                          const InputDecoration(labelText: 'Term Type'),
                      items: _termTypes
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _termType = v;
                          _termNumber = _termNumbers.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _termNumbers.contains(_termNumber)
                          ? _termNumber
                          : _termNumbers.first,
                      decoration: const InputDecoration(labelText: 'Term'),
                      items: _termNumbers
                          .map((n) =>
                              DropdownMenuItem(value: n, child: Text(n)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _termNumber = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _schoolYearCtrl,
                decoration: const InputDecoration(
                  labelText: 'School Year *',
                  hintText: '2024-2025',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),

              Text(
                'Will be saved as: $_computedSemester ${_schoolYearCtrl.text.trim()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryAccent,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Grade'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Live preview chip ─────────────────────────────────────────────────────────

class _PreviewChip extends StatelessWidget {
  final String text;
  final Color color;
  const _PreviewChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
