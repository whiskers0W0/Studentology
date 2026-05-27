import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/providers/timer_provider.dart';

// ── TimerScreen ───────────────────────────────────────────────────────────────

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late final TimerProvider _timer;

  @override
  void initState() {
    super.initState();
    _timer = context.read<TimerProvider>();
    _timer.addListener(_onTimerChange);
  }

  @override
  void dispose() {
    _timer.removeListener(_onTimerChange);
    super.dispose();
  }

  void _onTimerChange() {
    if (_timer.pendingLongBreakPrompt && mounted) {
      // Clear the flag first so the callback doesn't fire again.
      _timer.clearLongBreakPrompt();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showLongBreakDialog();
      });
    }
  }

  void _showLongBreakDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
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
                  'Great work! 🎉',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Theme.of(ctx).textTheme.bodyLarge!.color),
                ),
                const SizedBox(height: 12),
                Text(
                  "You've completed 4 focus sessions! Take a long break to recharge.",
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(ctx).textTheme.bodySmall!.color,
                      height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _timer.resetSessions();
                      _timer.startTimer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      side: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                    child: Text('Take Long Break',
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
                    onPressed: () {
                      Navigator.pop(ctx);
                      _timer.startTimer();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 1.5),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor:
                          Theme.of(ctx).textTheme.bodyLarge!.color,
                    ),
                    child: Text('Keep Going',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Pomodoro',
          style: GoogleFonts.ultra(color: context.textPrimary),
        ),
      ),
      body: Consumer<TimerProvider>(
        builder: (_, timer, __) => _TimerBody(timer: timer),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _TimerBody extends StatelessWidget {
  final TimerProvider timer;
  const _TimerBody({required this.timer});

  int get _sessionNumber => timer.completedSessions % 4 + 1;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 28),

            // Session counter + dot indicators
            _SessionIndicator(
              current: _sessionNumber,
              total: 4,
              isFocus: timer.isFocusMode,
            ),

            const SizedBox(height: 36),

            // Ring — color transitions smoothly between focus (blue) and break (green)
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                begin: AppTheme.primaryAccent,
                end: timer.isFocusMode
                    ? AppTheme.primaryAccent
                    : AppTheme.successColor,
              ),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              builder: (_, color, __) => _TimerRing(
                progress: timer.progress,
                time: timer.formattedTime,
                color: color ?? AppTheme.primaryAccent,
              ),
            ),

            const SizedBox(height: 24),

            // Phase label
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                key: ValueKey(timer.isFocusMode),
                timer.isFocusMode ? 'FOCUS' : 'BREAK',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: timer.isFocusMode
                          ? AppTheme.primaryAccent
                          : AppTheme.successColor,
                      fontSize: 13,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),

            const SizedBox(height: 48),

            // Reset | Play/Pause | Skip
            _Controls(timer: timer),

            const SizedBox(height: 36),

            _SettingsSection(timer: timer),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Session indicator ─────────────────────────────────────────────────────────

class _SessionIndicator extends StatelessWidget {
  final int current;
  final int total;
  final bool isFocus;

  const _SessionIndicator({
    required this.current,
    required this.total,
    required this.isFocus,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isFocus ? AppTheme.primaryAccent : AppTheme.successColor;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final done = i < current - 1;
            final active = i == current - 1;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: done
                    ? AppTheme.primaryAccent.withOpacity(0.45)
                    : active
                        ? activeColor
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.12),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          'Session $current of $total',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(letterSpacing: 0.5),
        ),
      ],
    );
  }
}

// ── Timer ring ────────────────────────────────────────────────────────────────

class _TimerRing extends StatelessWidget {
  final double progress;
  final String time;
  final Color color;

  const _TimerRing({
    required this.progress,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.22),
            blurRadius: 54,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 90,
            spreadRadius: 20,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _TimerRingPainter(progress: progress, color: color),
        child: Center(
          child: Text(
            time,
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -2,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _TimerRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 14;
    const strokeWidth = 14.0;

    // Track ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc (12 o'clock → clockwise)
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Controls ──────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final TimerProvider timer;
  const _Controls({required this.timer});

  @override
  Widget build(BuildContext context) {
    final isFocus = timer.isFocusMode;
    final accentColor =
        isFocus ? AppTheme.primaryAccent : AppTheme.successColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left: Reset
        _CircleButton(
          icon: Icons.replay_rounded,
          color: onSurface.withOpacity(0.35),
          size: 52,
          onPressed: timer.resetTimer,
          tooltip: 'Reset',
        ),

        const SizedBox(width: 28),

        // Center: Play / Pause (large)
        _PlayPauseButton(
          isRunning: timer.isRunning,
          color: accentColor,
          onPressed: timer.isRunning ? timer.pauseTimer : timer.startTimer,
        ),

        const SizedBox(width: 28),

        // Right: Skip — advances to the next phase immediately
        _CircleButton(
          icon: Icons.skip_next_rounded,
          color: onSurface.withOpacity(0.35),
          size: 52,
          onPressed: timer.skipPhase,
          tooltip: isFocus ? 'Skip to Break' : 'Skip to Focus',
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isRunning;
  final Color color;
  final VoidCallback onPressed;

  const _PlayPauseButton({
    required this.isRunning,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.45),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            key: ValueKey(isRunning),
            isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onPressed;
  final String? tooltip;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
    return tooltip != null
        ? Tooltip(message: tooltip!, child: button)
        : button;
  }
}

// ── Settings section ──────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final TimerProvider timer;
  const _SettingsSection({required this.timer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timer Settings',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          _DurationSlider(
            label: 'Focus Duration',
            value: timer.focusMinutes.toDouble(),
            min: 5,
            max: 60,
            color: AppTheme.primaryAccent,
            onChanged: (v) =>
                context.read<TimerProvider>().setFocusDuration(v.round()),
          ),
          const SizedBox(height: 8),
          _DurationSlider(
            label: 'Break Duration',
            value: timer.breakMinutes.toDouble(),
            min: 1,
            max: 30,
            color: AppTheme.successColor,
            onChanged: (v) =>
                context.read<TimerProvider>().setBreakDuration(v.round()),
          ),
        ],
      ),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  const _DurationSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()} min',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.15),
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
            trackHeight: 4,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
