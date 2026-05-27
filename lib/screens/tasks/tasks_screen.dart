import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/models/subject_model.dart';
import 'package:studentology/models/task_model.dart';
import 'package:studentology/core/navigation/slide_route.dart';
import 'package:studentology/providers/auth_provider.dart';
import 'package:studentology/providers/schedule_provider.dart';
import 'package:studentology/providers/subject_provider.dart';
import 'package:studentology/providers/task_provider.dart';
import 'package:studentology/screens/tasks/task_detail_screen.dart';
import 'package:studentology/widgets/task_card.dart';

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
}

// ── TasksScreen ────────────────────────────────────────────────────────────

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isSelectMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_isSelectMode) {
      setState(() {
        _isSelectMode = false;
        _selectedIds.clear();
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _openForm([TaskModel? task]) {
    final userId = context.read<AuthProvider>().userId ?? '';

    SubjectModel? initialSubject;
    if (task?.subjectId != null) {
      final subjects = context.read<SubjectProvider>().subjects;
      try {
        initialSubject = subjects.firstWhere((s) => s.id == task!.subjectId);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskFormSheet(
        task: task,
        initialSubject: initialSubject,
        userId: userId,
      ),
    );
  }

  Future<void> _deleteSelected(List<TaskModel> items) async {
    final count = _selectedIds.length;
    final confirmed = await _showDeleteConfirmation(
      context,
      '$count item${count == 1 ? '' : 's'}',
      false,
    );
    if (confirmed != true || !mounted) return;
    final tp = context.read<TaskProvider>();
    final ids = Set<String>.from(_selectedIds);
    setState(() {
      _isSelectMode = false;
      _selectedIds.clear();
    });
    for (final id in ids) {
      await tp.deleteTask(id);
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

  Widget _buildActionBar(List<TaskModel> items) {
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
              onPressed:
                  _selectedIds.isEmpty ? null : () => _deleteSelected(items),
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

  Widget _buildList({
    required List<TaskModel> tasks,
    required TaskProvider tp,
    required IconData emptyIcon,
    required String emptyMessage,
  }) {
    if (tasks.isEmpty) {
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
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final task = tasks[i];
        final isSelected = _selectedIds.contains(task.id);
        return TaskCard(
          task: task,
          heroEnabled: !_isSelectMode,
          selectMode: _isSelectMode,
          isSelected: isSelected,
          onToggle: () => tp.toggleComplete(task.id),
          onDelete: () async {
            final confirmed = await _showDeleteConfirmation(
                ctx, task.title, !task.isCompleted);
            if (confirmed == true && ctx.mounted) {
              ctx.read<TaskProvider>().deleteTask(task.id);
            }
          },
          onTap: () async {
            final action = await Navigator.of(ctx).push<TaskDetailAction>(
              slideRoute(TaskDetailScreen(task: task)),
            );
            if (action == TaskDetailAction.edit && ctx.mounted) {
              _openForm(task);
            }
          },
          onLongPress: _isSelectMode
              ? null
              : () => setState(() {
                    _isSelectMode = true;
                    _selectedIds.clear();
                    _selectedIds.add(task.id);
                  }),
          onSelectTap: () => setState(() {
            if (_selectedIds.contains(task.id)) {
              _selectedIds.remove(task.id);
              if (_selectedIds.isEmpty) _isSelectMode = false;
            } else {
              _selectedIds.add(task.id);
            }
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TaskProvider>();
    final pending = tp.pendingTasks;
    final completed = tp.completedTasks;
    final overdue = tp.overdueTasks;
    final currentItems = switch (_tabController.index) {
      0 => pending,
      1 => completed,
      _ => overdue,
    };

    return PopScope(
      canPop: !_isSelectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() {
            _isSelectMode = false;
            _selectedIds.clear();
          });
        }
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
                        fontSize: 15),
                  ),
                ),
                leadingWidth: 90,
                title: Text(
                  '${_selectedIds.length} Selected',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w700, color: context.textPrimary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => setState(() {
                      if (_selectedIds.length == currentItems.length &&
                          currentItems.isNotEmpty) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds = currentItems.map((t) => t.id).toSet();
                      }
                    }),
                    child: Text(
                      _selectedIds.length == currentItems.length &&
                              currentItems.isNotEmpty
                          ? 'Deselect All'
                          : 'Select All',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryAccent,
                          fontSize: 15),
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: 'Pending (${pending.length})'),
                      Tab(text: 'Completed (${completed.length})'),
                      Tab(text: 'Overdue (${overdue.length})'),
                    ],
                  ),
                ),
              )
            : AppBar(
                backgroundColor: context.bgColor,
                elevation: 0,
                iconTheme: IconThemeData(color: context.textPrimary),
                title:
                    Text('Tasks', style: GoogleFonts.ultra(color: context.textPrimary)),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: 'Pending (${pending.length})'),
                      Tab(text: 'Completed (${completed.length})'),
                      Tab(text: 'Overdue (${overdue.length})'),
                    ],
                  ),
                ),
              ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(
                    tasks: pending,
                    tp: tp,
                    emptyIcon: Icons.task_alt_outlined,
                    emptyMessage: 'All caught up! No pending tasks.',
                  ),
                  _buildList(
                    tasks: completed,
                    tp: tp,
                    emptyIcon: Icons.check_circle_outline_rounded,
                    emptyMessage: 'No completed tasks yet.',
                  ),
                  _buildList(
                    tasks: overdue,
                    tp: tp,
                    emptyIcon: Icons.warning_amber_outlined,
                    emptyMessage: 'No overdue tasks. Nice work!',
                  ),
                ],
              ),
            ),
            if (_isSelectMode) _buildActionBar(currentItems),
          ],
        ),
        floatingActionButton: _isSelectMode
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add Task'),
              ),
      ),
    );
  }
}

// ── Task form bottom sheet ─────────────────────────────────────────────────

class _TaskFormSheet extends StatefulWidget {
  final TaskModel? task;
  final SubjectModel? initialSubject;
  final String userId;

  const _TaskFormSheet({this.task, this.initialSubject, required this.userId});

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;

  late DateTime _selectedDate;
  late TaskPriority _selectedPriority;
  SubjectModel? _selectedSubject;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    _selectedDate = t?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedPriority = t?.priority ?? TaskPriority.medium;
    _selectedSubject = widget.initialSubject;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final tp = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();

    if (_isEditing) {
      await tp.updateTask(
        widget.task!.copyWith(
          title: _titleCtrl.text.trim(),
          subjectId: _selectedSubject?.id,
          subjectName: _selectedSubject?.name,
          dueDate: _selectedDate,
          priority: _selectedPriority,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ),
      );
    } else {
      await tp.addTask(
        TaskModel(
          id: '',
          userId: widget.userId,
          title: _titleCtrl.text.trim(),
          subjectId: _selectedSubject?.id,
          subjectName: _selectedSubject?.name,
          dueDate: _selectedDate,
          priority: _selectedPriority,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          createdAt: now,
        ),
      );
    }

    if (!mounted) return;

    if (tp.errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(tp.errorMessage!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      tp.clearError();
      return;
    }

    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Task updated!' : 'Task added!')),
    );
  }

  static Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return AppTheme.errorColor;
      case TaskPriority.medium:
        return AppTheme.warningColor;
      case TaskPriority.low:
        return AppTheme.successColor;
    }
  }

  static String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
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
                _isEditing ? 'Edit Task' : 'Add Task',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _SheetTextField(
                controller: _titleCtrl,
                label: 'Title',
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
                      !subjects.any((s) => s.id == _selectedSubject!.id)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedSubject = null);
                    });
                  }
                  return _SheetDropdown<SubjectModel?>(
                    value: _selectedSubject,
                    hint: 'None',
                    items: [
                      const DropdownMenuItem<SubjectModel?>(
                        value: null,
                        child: Text('None'),
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
                    onChanged: (v) => setState(() => _selectedSubject = v),
                  );
                },
              ),
              const SizedBox(height: 14),
              const _FieldLabel('Due Date'),
              const SizedBox(height: 8),
              _DateTile(date: _selectedDate, onTap: _pickDate),
              const SizedBox(height: 14),
              const _FieldLabel('Priority'),
              const SizedBox(height: 8),
              _SheetDropdown<TaskPriority>(
                value: _selectedPriority,
                items: TaskPriority.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _priorityColor(p),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_priorityLabel(p)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedPriority = v!),
              ),
              const SizedBox(height: 14),
              _SheetTextField(
                controller: _notesCtrl,
                label: 'Notes (optional)',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Consumer<TaskProvider>(
                builder: (_, tp, __) => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: tp.isLoading ? null : _submit,
                    child: tp.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(_isEditing ? 'Save Changes' : 'Add Task'),
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
  final String? Function(String?)? validator;
  final int? maxLines;

  const _SheetTextField({
    required this.controller,
    required this.label,
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
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day} ${d.year}';
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
                size: 18, color: AppTheme.primaryAccent),
            const SizedBox(width: 10),
            Text(
              _format(date),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface),
            ),
            const Spacer(),
            Icon(Icons.edit_calendar_outlined,
                size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
