import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/models/thesis_idea_model.dart';
import 'package:studentology/providers/auth_provider.dart';
import 'package:studentology/services/firestore_service.dart';
import 'package:studentology/services/studentology_ai_service.dart';

// Holds a parsed idea split into title + description.
class _ParsedIdea {
  final String title;
  final String description;
  const _ParsedIdea(this.title, this.description);
}

// ── ThesisScreen ──────────────────────────────────────────────────────────────

class ThesisScreen extends StatefulWidget {
  const ThesisScreen({super.key});

  @override
  State<ThesisScreen> createState() => _ThesisScreenState();
}

class _ThesisScreenState extends State<ThesisScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _customCourseCtrl = TextEditingController();
  final _interestsCtrl = TextEditingController();
  String? _selectedCourse;
  bool _isGenerating = false;
  List<_ParsedIdea> _parsedIdeas = [];
  Set<String> _savedIdeaTitles = {};
  List<ThesisIdeaModel> _savedIdeas = [];
  StreamSubscription<List<ThesisIdeaModel>>? _savedIdeasSub;
  String? _error;
  late final ScrollController _scrollCtrl;

  static const _courses = [
    'BS Information Technology',
    'BS Computer Science',
    'BS Information Systems',
    'BS Computer Engineering',
    'BS Electronics Engineering',
    'BS Electrical Engineering',
    'BS Civil Engineering',
    'BS Mechanical Engineering',
    'BS Architecture',
    'BS Accountancy',
    'BS Business Administration',
    'BS Marketing Management',
    'BS Tourism Management',
    'BS Hospitality Management',
    'BS Nursing',
    'BS Medical Technology',
    'BS Pharmacy',
    'BS Psychology',
    'AB Communication',
    'AB Political Science',
    'AB English Language Studies',
    'BS Education',
    'BS Social Work',
    'Other',
  ];

  final _ai = StudentologyAIService();
  final _firestore = FirestoreService();
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollCtrl = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().userId;
      if (userId == null) return;
      _savedIdeasSub = _firestore.streamThesisIdeas(userId).listen((ideas) {
        if (!mounted) return;
        setState(() {
          _savedIdeas = ideas;
          _savedIdeaTitles = ideas.map((i) => i.title).toSet();
        });
      });
    });
  }

  @override
  void dispose() {
    _savedIdeasSub?.cancel();
    _tabController.dispose();
    _customCourseCtrl.dispose();
    _interestsCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String get _effectiveCourse {
    if (_selectedCourse == 'Other') return _customCourseCtrl.text.trim();
    return _selectedCourse ?? '';
  }

  Future<void> _generateIdeas() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'For best results, use the Android app. Web may have connection issues.'),
          backgroundColor: Color(0xFFFFB347),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (_selectedCourse == null) {
      setState(() => _error = 'Please select your Course / Degree Program.');
      return;
    }
    if (_selectedCourse == 'Other' && _customCourseCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your custom course/program name.');
      return;
    }
    if (_interestsCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your interests and topics.');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _parsedIdeas = [];
    });

    try {
      final rawIdeas = await _ai.generateThesisIdeas(
        _effectiveCourse,
        _interestsCtrl.text.trim(),
      );
      setState(() => _parsedIdeas = rawIdeas.map(_parseIdea).toList());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _toggleSave(int index) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final idea = _parsedIdeas[index];

    if (_savedIdeaTitles.contains(idea.title)) {
      // Unsave — immediately reflect in UI, then delete from Firestore
      setState(() => _savedIdeaTitles.remove(idea.title));

      ThesisIdeaModel? saved;
      try {
        saved = _savedIdeas.firstWhere((s) => s.title == idea.title);
      } catch (_) {
        return;
      }

      try {
        await _firestore.deleteThesisIdea(user.id, saved.id);
      } catch (e) {
        if (!mounted) return;
        setState(() => _savedIdeaTitles.add(idea.title));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to remove: $e'),
          backgroundColor: AppTheme.errorColor,
        ));
      }
    } else {
      // Save — immediately reflect in UI, then write to Firestore
      setState(() => _savedIdeaTitles.add(idea.title));

      final model = ThesisIdeaModel(
        id: _uuid.v4(),
        userId: user.id,
        title: idea.title,
        description: idea.description,
        course: _effectiveCourse,
        keywords: [],
        isSaved: true,
        generatedAt: DateTime.now(),
      );

      try {
        await _firestore.saveThesisIdea(user.id, model.id, model.toMap());
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Idea saved!')));
      } catch (e) {
        if (!mounted) return;
        setState(() => _savedIdeaTitles.remove(idea.title));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppTheme.errorColor,
        ));
      }
    }
  }

  // Parses a numbered idea string into title + description.
  // Handles **bold** titles, "Title: desc" format, or first-sentence fallback.
  static _ParsedIdea _parseIdea(String raw) {
    final cleaned = raw.replaceFirst(RegExp(r'^\d+[.)]\s*'), '');

    // **Bold title** followed by description
    final bold = RegExp(r'^\*\*(.+?)\*\*\s*(.*)$', dotAll: true)
        .firstMatch(cleaned);
    if (bold != null) {
      return _ParsedIdea(bold.group(1)!.trim(), bold.group(2)!.trim());
    }

    // "Title: description" pattern
    final colon =
        RegExp(r'^([^:]{5,120}):\s+(.+)$', dotAll: true).firstMatch(cleaned);
    if (colon != null) {
      return _ParsedIdea(colon.group(1)!.trim(), colon.group(2)!.trim());
    }

    // First sentence as title, remainder as description
    final sentence =
        RegExp(r'^(.{10,120}[.!?])\s+(.+)$', dotAll: true)
            .firstMatch(cleaned);
    if (sentence != null) {
      return _ParsedIdea(
          sentence.group(1)!.trim(), sentence.group(2)!.trim());
    }

    return _ParsedIdea(
      cleaned.length > 100 ? '${cleaned.substring(0, 100)}…' : cleaned,
      '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().userId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Thesis Ideas',
          style: GoogleFonts.ultra(color: context.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryAccent,
          unselectedLabelColor: context.textSecondary,
          indicatorColor: AppTheme.primaryAccent,
          tabs: const [
            Tab(text: 'Generate'),
            Tab(text: 'Saved Ideas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenerateTab(context),
          _buildSavedTab(context, userId),
        ],
      ),
    );
  }

  // ── Generate tab ────────────────────────────────────────────────────────────

  Widget _buildGenerateTab(BuildContext context) {
    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.secondaryAccent.withOpacity(0.25)),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppTheme.secondaryAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thesis & Capstone Ideas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AI-powered by Studentology AI',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Course / Program dropdown
        DropdownButtonFormField<String>(
          value: _selectedCourse,
          decoration: InputDecoration(
            labelText: 'Course / Program *',
            prefixIcon: const Icon(Icons.school_outlined),
            fillColor: context.inputFill,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: AppTheme.primaryAccent, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withOpacity(0.5)),
            ),
          ),
          items: _courses
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: _isGenerating
              ? null
              : (v) => setState(() {
                    _selectedCourse = v;
                    if (v != 'Other') _customCourseCtrl.clear();
                  }),
        ),

        // Custom course input when "Other" is selected
        if (_selectedCourse == 'Other') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _customCourseCtrl,
            enabled: !_isGenerating,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Enter your course/program *',
              prefixIcon: Icon(Icons.edit_outlined),
              hintText: 'e.g. BS Data Science',
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Interests & Topics
        TextFormField(
          controller: _interestsCtrl,
          enabled: !_isGenerating,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Interests & Topics *',
            prefixIcon: Icon(Icons.lightbulb_outline),
            hintText:
                'e.g. machine learning, mental health, mobile apps, agriculture',
            alignLabelWithHint: true,
          ),
        ),

        // Error card — styled with red border and light red background
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.errorColor.withOpacity(0.45)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline,
                    color: AppTheme.errorColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: _generateIdeas,
              icon: const Icon(Icons.refresh_rounded,
                  color: Color(0xFFFFB347)),
              label: Text(
                'Try Again',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFB347),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: Color(0xFFFFB347), width: 1.5),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Generate button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isGenerating ? null : _generateIdeas,
            child: _isGenerating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Generate Ideas ✨'),
          ),
        ),

        // Generated idea cards
        if (_parsedIdeas.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text('Generated Ideas',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          for (int i = 0; i < _parsedIdeas.length; i++)
            _GeneratedIdeaCard(
              index: i,
              idea: _parsedIdeas[i],
              isSaved: _savedIdeaTitles.contains(_parsedIdeas[i].title),
              onSave: () => _toggleSave(i),
            ),
        ],
      ],
    );
  }

  // ── Saved ideas tab ─────────────────────────────────────────────────────────

  Widget _buildSavedTab(BuildContext context, String? userId) {
    if (userId == null) return const SizedBox();

    return StreamBuilder<List<ThesisIdeaModel>>(
      stream: _firestore.streamThesisIdeas(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final ideas = snapshot.data ?? [];

        if (ideas.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 52,
                    color: context.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved ideas yet 📌',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Generate ideas and tap "Save Idea" to keep them here.',
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

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          itemCount: ideas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _SavedIdeaCard(
            idea: ideas[i],
            onDelete: () async {
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
                          offset: Offset(5, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bookmark_remove_outlined,
                                  color: AppTheme.primaryAccent, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'Remove from saved?',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Theme.of(ctx).textTheme.bodyLarge!.color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This idea will be removed from your saved list. You can always save it again from the Generate tab.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Theme.of(ctx).textTheme.bodySmall!.color,
                              height: 1.5,
                            ),
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
                              child: Text(
                                'Remove',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
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
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Theme.of(ctx).textTheme.bodyLarge!.color,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              if (confirmed != true || !mounted) return;
              await _firestore.deleteThesisIdea(userId, ideas[i].id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Idea removed from saved'),
                    behavior: SnackBarBehavior.floating,
                    shape: StadiumBorder(),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}

// ── Generated idea card ───────────────────────────────────────────────────────

class _GeneratedIdeaCard extends StatelessWidget {
  final int index;
  final _ParsedIdea idea;
  final bool isSaved;
  final VoidCallback onSave;

  const _GeneratedIdeaCard({
    required this.index,
    required this.idea,
    required this.isSaved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor =
        isDark ? AppTheme.cartoonBorderDark : AppTheme.cartoonBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSaved ? AppTheme.primaryAccent : outlineColor,
          width: 1.5,
        ),
        boxShadow: isDark ? const [] : AppTheme.cartoonShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Purple left accent bar
            Container(
                width: 5,
                color: isSaved
                    ? AppTheme.primaryAccent
                    : AppTheme.secondaryAccent),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge + title
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        14, 14, 8, idea.description.isEmpty ? 14 : 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.only(top: 1, right: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.secondaryAccent.withOpacity(0.14),
                            border: Border.all(
                                color: AppTheme.secondaryAccent.withOpacity(0.4),
                                width: 1),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppTheme.secondaryAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            idea.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: onSave,
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved
                                ? AppTheme.successColor
                                : AppTheme.primaryAccent,
                            size: 20,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  if (idea.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                      child: Text(
                        idea.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Saved idea card ───────────────────────────────────────────────────────────

class _SavedIdeaCard extends StatelessWidget {
  final ThesisIdeaModel idea;
  final VoidCallback onDelete;

  const _SavedIdeaCard({required this.idea, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor =
        isDark ? AppTheme.cartoonBorderDark : AppTheme.cartoonBorder;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outlineColor, width: 1.5),
        boxShadow: isDark ? const [] : AppTheme.cartoonShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            idea.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(
                            Icons.bookmark,
                            color: AppTheme.successColor,
                            size: 22,
                          ),
                        ),
                      ],
                    ),

                    if (idea.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        idea.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],

                    if (idea.keywords.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: idea.keywords
                            .map(
                              (k) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primaryAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                      color: AppTheme.primaryAccent
                                          .withOpacity(0.4)),
                                ),
                                child: Text(
                                  k,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
