import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/providers/auth_provider.dart';
import 'package:studentology/providers/exam_provider.dart';
import 'package:studentology/providers/grade_provider.dart';
import 'package:studentology/providers/subject_provider.dart';
import 'package:studentology/providers/task_provider.dart';
import 'package:studentology/screens/exams/exams_screen.dart';
import 'package:studentology/screens/tasks/tasks_screen.dart';
import 'package:studentology/screens/timetable/timetable_screen.dart';
import 'package:studentology/services/quote_service.dart';
import 'package:studentology/widgets/exam_card.dart';
import 'package:studentology/widgets/section_header.dart';
import 'package:studentology/widgets/task_card.dart';

import '../../models/subject_model.dart';

// ── HomeScreen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;
  String? _initializedUserId;
  final _dashboardKey = GlobalKey<_DashboardTabState>();

  @override
  void initState() {
    super.initState();
    _tabs = [
      _DashboardTab(key: _dashboardKey, onTabSwitch: _switchTab),
      const TimetableScreen(),
      const TasksScreen(),
      const ExamsScreen(),
    ];
  }

  void _switchTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      setState(() => _currentIndex = index);
    }
  }

  void _initProviders(String userId) {
    if (_initializedUserId == userId) return;
    _initializedUserId = userId;
    context.read<SubjectProvider>().init(userId);
    context.read<TaskProvider>().init(userId);
    context.read<ExamProvider>().init(userId);
    context.read<GradeProvider>().init(userId);
  }

  void _showMore() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _MoreSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch AuthProvider so build() re-runs when currentUser loads asynchronously
    // after login (loadUser() is a Firestore fetch that completes after navigation).
    final userId = context.watch<AuthProvider>().userId;
    if (userId != null && userId.isNotEmpty && userId != _initializedUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initProviders(userId);
      });
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 4) {
            _showMore();
          } else {
            if (i == 0 && _currentIndex != 0) {
              _dashboardKey.currentState?._loadQuote();
            }
            _switchTab(i);
          }
        },
        backgroundColor: context.bgColor,
        selectedItemColor: const Color(0xFFFFB347),
        unselectedItemColor: context.isDark
            ? const Color(0xFF6B7280)
            : const Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_week_outlined),
            activeIcon: Icon(Icons.calendar_view_week_rounded),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_outlined),
            activeIcon: Icon(Icons.checklist_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school_rounded),
            label: 'Exams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard tab ──────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  final void Function(int) onTabSwitch;

  const _DashboardTab({super.key, required this.onTabSwitch});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  final _scrollController = ScrollController();
  bool _isScrolled = false;

  Map<String, String>? _quote;
  bool _quoteLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadQuote();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    setState(() => _quoteLoading = true);
    final q = await QuoteService.fetchRandomQuote();
    if (mounted) setState(() { _quote = q; _quoteLoading = false; });
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 4;
    if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formattedDate() {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildQuoteCard() {
    final isDark = context.isDark;
    const cardBg = Color(0xFFE8DCFF);
    const cardBgDark = Color(0xFF2A1A4A);
    const accentColor = Color(0xFF4527A0);
    const accentColorDark = Color(0xFFB39DDB);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? cardBgDark : cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 0,
                  offset: Offset(4, 4),
                ),
              ],
      ),
      child: _quoteLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: isDark ? accentColorDark : accentColor,
                  size: 20,
                ),
                const SizedBox(height: 8),
                Text(
                  '"${_quote?['quote'] ?? ''}"',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark ? accentColorDark : accentColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '— ${_quote?['author'] ?? ''}',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: (isDark ? accentColorDark : accentColor)
                        .withOpacity(0.75),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayDay = now.weekday;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── App bar ────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: _isScrolled
                  ? Theme.of(context).scaffoldBackgroundColor
                  : Colors.transparent,
              elevation: _isScrolled ? 2 : 0,
              shadowColor: Colors.black.withOpacity(0.08),
              surfaceTintColor: Colors.transparent,
              title: Hero(
                tag: 'app-logo',
                // Cross-fade during the flight — avoids jarring size morph
                // between the large login title and the compact AppBar text.
                flightShuttleBuilder: (_, animation, __, ___, toCtx) =>
                    FadeTransition(
                  opacity: animation,
                  child: DefaultTextStyle(
                    style: DefaultTextStyle.of(toCtx).style,
                    child: toCtx.widget,
                  ),
                ),
                child: Text(
                  'Studentology',
                  style: GoogleFonts.ultra(
                    fontSize: 22,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              actions: [
                Consumer<AuthProvider>(
                  builder: (_, auth, __) => GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed('/profile'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryAccent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _initials(auth.currentUser?.name),
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Body ───────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Greeting ─────────────────────────────────────────
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()},',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            auth.currentUser?.name ?? 'Student',
                            style: GoogleFonts.ultra(
                              fontSize: 20,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formattedDate(),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Quick stats ───────────────────────────────────────
                  Consumer3<SubjectProvider, TaskProvider, ExamProvider>(
                    builder: (_, subjects, tasks, exams, __) => Row(
                      children: [
                        _StatCard(
                          label: 'Classes\nToday',
                          value: '${subjects.subjects.where((s) => s.dayOfWeek == todayDay).map((s) => '${s.name}_${s.startTime.hour}_${s.startTime.minute}').toSet().length}',
                          icon: Icons.class_outlined,
                          lightBg: const Color(0xFFDCEEFF),
                          darkBg: const Color(0xFF1A3A5C),
                          accentColor: const Color(0xFF1565C0),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Pending\nTasks',
                          value: '${tasks.pendingTasks.length}',
                          icon: Icons.checklist_rounded,
                          lightBg: const Color(0xFFFFF3DC),
                          darkBg: const Color(0xFF3A2800),
                          accentColor: const Color(0xFFE65100),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Upcoming\nExams',
                          value: '${exams.nearingExams.length}',
                          icon: Icons.school_outlined,
                          lightBg: const Color(0xFFFFDCDC),
                          darkBg: const Color(0xFF3A0000),
                          accentColor: const Color(0xFFC62828),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Motivational quote ────────────────────────────────
                  _buildQuoteCard(),
                  const SizedBox(height: 28),

                  // ── Today's schedule ──────────────────────────────────
                  SectionHeader(
                    title: "Today's Schedule",
                    actionLabel: 'Full Schedule',
                    onAction: () => widget.onTabSwitch(1),
                  ),
                  const SizedBox(height: 12),
                  Consumer<SubjectProvider>(
                    builder: (_, sp, __) {
                      // All subjects for today, deduplicated by name+time.
                      final allToday = sp.subjects
                          .where((s) => s.dayOfWeek == todayDay)
                          .toList()
                        ..sort((a, b) {
                            final aMin =
                                a.startTime.hour * 60 + a.startTime.minute;
                            final bMin =
                                b.startTime.hour * 60 + b.startTime.minute;
                            return aMin.compareTo(bMin);
                          });
                      final seen = <String>{};
                      final todaySubjects = allToday.where((s) {
                        final key =
                            '${s.name}_${s.startTime.hour}_${s.startTime.minute}';
                        return seen.add(key);
                      }).toList();

                      if (todaySubjects.isEmpty) {
                        return const _EmptyCard(
                          message: 'No classes today 🎉',
                          icon: Icons.celebration_outlined,
                        );
                      }
                      return SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: todaySubjects.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) =>
                              _SubjectCard(subject: todaySubjects[i]),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── Upcoming tasks ────────────────────────────────────
                  SectionHeader(
                    title: 'Upcoming Tasks',
                    actionLabel: 'View all',
                    onAction: () => widget.onTabSwitch(2),
                  ),
                  const SizedBox(height: 12),
                  Consumer<TaskProvider>(
                    builder: (context, tp, _) {
                      final upcoming = tp.pendingTasks.take(3).toList();
                      if (upcoming.isEmpty) {
                        return const _EmptyCard(
                          message: "You're all caught up!",
                          icon: Icons.task_alt_outlined,
                        );
                      }
                      return Column(
                        children: [
                          for (final t in upcoming) ...[
                            TaskCard(
                              task: t,
                              // heroEnabled stays false — the dashboard and
                              // the Tasks tab are both alive in the IndexedStack,
                              // so enabling Hero here would create duplicate tags.
                              onToggle: () => tp.toggleComplete(t.id),
                              onDelete: () {}, // delete from Tasks screen
                              onTap: () => widget.onTabSwitch(2),
                            ),
                            if (t != upcoming.last)
                              const SizedBox(height: 10),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // ── Upcoming exams ────────────────────────────────────
                  SectionHeader(
                    title: 'Upcoming Exams',
                    actionLabel: 'View all',
                    onAction: () => widget.onTabSwitch(3),
                  ),
                  const SizedBox(height: 12),
                  Consumer<ExamProvider>(
                    builder: (_, ep, __) {
                      final upcoming = ep.nearingExams.take(2).toList();
                      if (upcoming.isEmpty) {
                        return const _EmptyCard(
                          message: 'No exams in the next 7 days',
                          icon: Icons.event_available_outlined,
                        );
                      }
                      return Column(
                        children: [
                          for (final e in upcoming) ...[
                            ExamCard(exam: e),
                            if (e != upcoming.last)
                              const SizedBox(height: 10),
                          ],
                        ],
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color lightBg;
  final Color darkBg;
  final Color accentColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.lightBg,
    required this.darkBg,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? darkBg : lightBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: isDark
              ? const []
              : const [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 0,
                    spreadRadius: 0,
                    offset: Offset(4, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accentColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.ultra(
                fontSize: 28,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: accentColor.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectModel subject;

  const _SubjectCard({required this.subject});

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = subject.displayColor;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.cartoonBorderDark : AppTheme.cartoonBorder,
          width: 1.5,
        ),
        boxShadow: isDark ? const [] : AppTheme.cartoonShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color dot + room
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: subjectColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subject.room.isEmpty ? 'No room' : subject.room,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),

          // Subject name
          Text(
            subject.name,
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Time range
          Text(
            '${_formatTime(subject.startTime)} – ${_formatTime(subject.endTime)}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: subjectColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyCard({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.cartoonBorderDark : AppTheme.cartoonBorder,
          width: 1.5,
        ),
        boxShadow: isDark ? const [] : AppTheme.cartoonShadow,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── More bottom sheet ──────────────────────────────────────────────────────

class _MoreSheet extends StatelessWidget {
  const _MoreSheet();

  @override
  Widget build(BuildContext context) {
    final moreItems = [
      {
        'icon': Icons.bar_chart_rounded,
        'label': 'Grades',
        'subtitle': 'Track your GWA & records',
        'color': const Color(0xFFDCEEFF),
        'iconColor': const Color(0xFF1565C0),
        'route': '/grades',
      },
      {
        'icon': Icons.timer_rounded,
        'label': 'Focus Timer',
        'subtitle': 'Pomodoro study sessions',
        'color': const Color(0xFFFFE4DC),
        'iconColor': const Color(0xFFBF360C),
        'route': '/timer',
      },
      {
        'icon': Icons.lightbulb_outline_rounded,
        'label': 'Thesis Ideas',
        'subtitle': 'AI-powered suggestions',
        'color': const Color(0xFFE8DCFF),
        'iconColor': const Color(0xFF4527A0),
        'route': '/thesis',
      },
      {
        'icon': Icons.person_outline_rounded,
        'label': 'Profile',
        'subtitle': 'Account & settings',
        'color': const Color(0xFFDCFFE8),
        'iconColor': const Color(0xFF1B5E20),
        'route': '/profile',
      },
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'More',
              style: GoogleFonts.ultra(
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...moreItems.map((item) => ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black,
                            blurRadius: 0,
                            offset: Offset(2, 2)),
                      ],
                    ),
                    child: Icon(item['icon'] as IconData,
                        color: item['iconColor'] as Color, size: 22),
                  ),
                  title: Text(
                    item['label'] as String,
                    style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge!.color),
                  ),
                  subtitle: Text(
                    item['subtitle'] as String,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall!.color),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: Theme.of(context).textTheme.bodySmall!.color),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, item['route'] as String);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
