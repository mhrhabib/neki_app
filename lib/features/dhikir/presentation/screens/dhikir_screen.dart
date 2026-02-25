// ignore_for_file: use_build_context_synchronously

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../points/presentation/cubit/points_cubit.dart';
import '../cubit/dhikir_cubit.dart';

// ═══════════════════════════════════════════════════════════════
//  BEAD PAINTER
// ═══════════════════════════════════════════════════════════════
class _BeadPainter extends CustomPainter {
  final int total;
  final int counted;
  final double animProgress;
  final int animatingIndex;
  final Color beadColor;

  _BeadPainter({
    required this.total,
    required this.counted,
    required this.animProgress,
    required this.animatingIndex,
    required this.beadColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
  // Arc geometry — position the bead arc so it sweeps from
  // slightly bottom-left to top-right with a gentler, more straight appearance.
  final cx = size.width * 0.5; // center horizontally
  final cy = size.height * 0.45; // slightly lower so the arc starts from bottom-left
  final radius = math.min(size.width, size.height) * 0.45; // slightly larger responsive radius

  // Make the arc cover 90% of a circle (324°) so beads form a nearly-full
  // circular arc. Start at ~220° (slightly bottom-left) and sweep 324°.
  final startAngle = 220.0 * math.pi / 80;
  final span = 324.0 * math.pi / 180; // 90% of 360°

    // Thread
    final threadPaint = Paint()
      ..color = const Color(0xFF7A4F2E)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i <= 120; i++) {
      final t = i / 120;
      final angle = startAngle + span * t;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, threadPaint);

    // Beads
    for (int i = 0; i < total; i++) {
      final t = (i + 0.5) / total;
      final angle = startAngle + span * t;
      final bx = cx + radius * math.cos(angle);
      final by = cy + radius * math.sin(angle);

      final isCounted = i < counted;
      final isAnimating = i == animatingIndex;

      double scale = 1.0;
      if (isAnimating) {
        scale = 1.0 + 0.38 * math.sin(animProgress * math.pi);
      }

  // Increase bead sizes slightly so they are more visible when centered
  final beadRadius = (total > 50 ? 12.0 : total > 33 ? 14.0 : 16.0) * scale;

      if (isCounted) {
        _drawFilledBead(canvas, Offset(bx, by), beadRadius, isAnimating, beadColor);
      } else {
        _drawGhostBead(canvas, Offset(bx, by), beadRadius, beadColor);
      }
    }
  }

  void _drawFilledBead(Canvas canvas, Offset center, double r, bool glowing, Color color) {
    // Drop shadow
    canvas.drawCircle(
      center + const Offset(1.5, 3),
      r,
      Paint()
        ..color = Colors.black.withValues(alpha:  0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Glow pulse when tapped
    if (glowing) {
      canvas.drawCircle(
        center,
        r * 1.45,
        Paint()
          ..color = color.withValues(alpha: 0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Bead body — radial gradient for 3D look
    final hsl = HSLColor.fromColor(color);
    final highlight = hsl.withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0)).toColor();
    final shadow = hsl.withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0)).toColor();

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.42),
          radius: 0.88,
          colors: [highlight, color, shadow],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Specular dot
    canvas.drawCircle(
      center + Offset(-r * 0.29, -r * 0.30),
      r * 0.27,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.58)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _drawGhostBead(Canvas canvas, Offset center, double r, Color color) {
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = color.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_BeadPainter old) =>
      old.counted != counted ||
      old.animProgress != animProgress ||
      old.animatingIndex != animatingIndex ||
      old.beadColor != beadColor;
}

// ═══════════════════════════════════════════════════════════════
//  POUCH PAINTER
// ═══════════════════════════════════════════════════════════════
class _PouchPainter extends CustomPainter {
  final double fillRatio; // 1.0 = full, 0.0 = empty
  final double pulseAnim;

  _PouchPainter({required this.fillRatio, required this.pulseAnim});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final pouchPath = Path()
      ..moveTo(w * 0.18, h * 0.30)
      ..cubicTo(w * 0.06, h * 0.26, w * 0.01, h * 0.52, w * 0.09, h * 0.80)
      ..cubicTo(w * 0.16, h * 1.04, w * 0.84, h * 1.04, w * 0.91, h * 0.80)
      ..cubicTo(w * 0.99, h * 0.52, w * 0.94, h * 0.26, w * 0.82, h * 0.30)
      ..cubicTo(w * 0.72, h * 0.18, w * 0.28, h * 0.18, w * 0.18, h * 0.30)
      ..close();

    // Shadow
    canvas.save();
    canvas.translate(2, 4);
    canvas.drawPath(
      pouchPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.restore();

    // Body
    canvas.drawPath(
      pouchPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFFD4A574), const Color(0xFF8B6240), 1 - fillRatio)!,
            const Color(0xFF5C3317),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Fabric stitch lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 4; i++) {
      final y = h * (0.38 + i * 0.13);
      canvas.drawLine(Offset(w * 0.20, y), Offset(w * 0.80, y), linePaint);
    }

    // Dark overlay as beads drain
    if (fillRatio < 1.0) {
      canvas.save();
      canvas.clipPath(pouchPath);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = Colors.black.withOpacity(0.28 * (1 - fillRatio)),
      );
      canvas.restore();
    }

    // Drawstring neck
    canvas.drawLine(
      Offset(w * 0.18, h * 0.28),
      Offset(w * 0.82, h * 0.28),
      Paint()
        ..color = const Color(0xFF4A2810)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Knot
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.20),
      5.5 + pulseAnim * 1.5,
      Paint()..color = const Color(0xFF6B3A18),
    );

    // Empty label
    if (fillRatio <= 0.05) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'EMPTY',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(w / 2 - tp.width / 2, h * 0.50));
    }
  }

  @override
  bool shouldRepaint(_PouchPainter old) =>
      old.fillRatio != fillRatio || old.pulseAnim != pulseAnim;
}

// ═══════════════════════════════════════════════════════════════
//  BACKGROUND PATTERN PAINTER
// ═══════════════════════════════════════════════════════════════
class _BgPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC4A882).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    const spacing = 30.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 3.5, paint);
        if (x + spacing < size.width && y + spacing < size.height) {
          canvas.drawLine(Offset(x, y), Offset(x + spacing, y + spacing), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BgPatternPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════
//  BEAD COLOR PRESETS
// ═══════════════════════════════════════════════════════════════
const _beadColors = [
  Color(0xFFC49A6C), // Wood (default)
  Color(0xFF1A1A1A), // Black
  Color(0xFF3D8B6E), // Green marble
  Color(0xFF7B3F8C), // Purple amethyst
  Color(0xFFCCCCCC), // White marble
];

// ═══════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════
class DhikirScreen extends StatefulWidget {
  const DhikirScreen({super.key});

  @override
  State<DhikirScreen> createState() => _DhikirScreenState();
}

class _DhikirScreenState extends State<DhikirScreen> with TickerProviderStateMixin {
  // Bead pop animation
  late AnimationController _beadController;
  // Pouch pulse animation
  late AnimationController _pouchController;
  // Completion celebration
  late AnimationController _completionController;
  late Animation<double> _completionAnimation;

  int _animatingBeadIndex = -1;
  Color _selectedBeadColor = _beadColors[0];
  bool _completionDialogShown = false;

  String? _selectedDhikir;
  int _targetCount = 33;

  @override
  void initState() {
    super.initState();

    _beadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _pouchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      lowerBound: 0,
      upperBound: 1,
    )..repeat(reverse: true);

    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _completionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _completionController, curve: Curves.easeOut),
    );

    final authState = context.read<AuthCubit>().state;
    final userId = authState is Authenticated ? authState.user.id : null;
    if (userId != null) {
      context.read<DhikirCubit>().loadCurrentSession(userId);
    }
  }

  @override
  void dispose() {
    _beadController.dispose();
    _pouchController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  void _onCounterTap(String userId, String sessionId, int currentCount) {
    HapticFeedback.lightImpact();
    setState(() => _animatingBeadIndex = currentCount);
    _beadController.forward(from: 0).then((_) {
      if (mounted) setState(() => _animatingBeadIndex = -1);
    });
    context.read<DhikirCubit>().incrementCount(userId, sessionId);
  }

  void _startNewSession(String userId) {
    if (_selectedDhikir != null) {
      context.read<DhikirCubit>().startDhikirSession(
        userId: userId,
        dhikirText: _selectedDhikir!,
        targetCount: _targetCount,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DhikirCubit, DhikirState>(
      listener: (context, state) async {
        if (state is DhikirSessionCompleted && !_completionDialogShown) {
          // Ensure we only show the dialog once per completion
          setState(() => _completionDialogShown = true);
          _completionController.forward(from: 0);
          final authState = context.read<AuthCubit>().state;
          if (authState is Authenticated) {
            context.read<PointsCubit>().loadUserPoints(authState.user.id);
          }

          // Small delay for animation to settle
          await Future.delayed(const Duration(milliseconds: 600));
          if (!mounted) return;

          // Show dialog and wait for it to be dismissed, then navigate back
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              title: Text(
                '🎉 Dhikir Completed!',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
              content: Text(
                'You earned ${state.pointsEarned} points for completing "${state.dhikirText}"!',
                style: TextStyle(fontSize: 15.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Continue',
                      style: TextStyle(color: AppColors.primaryGreen, fontSize: 15.sp, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );

          if (!mounted) return;
          // After dialog is closed, return to previous screen
          Navigator.of(context).maybePop();
        }
      },
      builder: (context, state) {
        final authState = context.watch<AuthCubit>().state;
        final userId = authState is Authenticated ? authState.user.id : null;

        if (userId == null) {
          return const Scaffold(
            body: Center(child: Text('Please login to use Dhikir counter')),
          );
        }

        if (state is DhikirLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (state is DhikirSessionActive) {
          return _buildTasbihScreen(
            userId: userId,
            sessionId: state.sessionId,
            dhikirText: state.dhikirText,
            targetCount: state.targetCount,
            currentCount: state.currentCount,
            pointsEarned: state.pointsEarned,
            isCompleted: state.isCompleted,
          );
        } else if (state is DhikirSessionCompleted) {
          return _buildTasbihScreen(
            userId: userId,
            sessionId: state.sessionId,
            dhikirText: state.dhikirText,
            targetCount: state.targetCount,
            currentCount: state.targetCount,
            pointsEarned: state.pointsEarned,
            isCompleted: true,
          );
        } else if (state is DhikirHistoryLoaded) {
          return _buildHistoryScreen(userId, state.sessions);
        } else if (state is DhikirError) {
          return _buildErrorScreen(state.message, userId);
        } else {
          return _buildInitialScreen(userId);
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  TASBIH / BEAD SCREEN
  // ─────────────────────────────────────────────────────────────
  Widget _buildTasbihScreen({
    required String userId,
    required String sessionId,
    required String dhikirText,
    required int targetCount,
    required int currentCount,
    required int pointsEarned,
    required bool isCompleted,
  }) {
    final fillRatio = ((targetCount - currentCount) / targetCount).clamp(0.0, 1.0);
    final roundsComplete = currentCount ~/ targetCount;
    final totalCount = currentCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP BAR ─────────────────────────────────────────
            _buildTopBar(userId),

            // ── DHIKR INFO CARD ──────────────────────────────────
            _buildDhikrCard(dhikirText, currentCount, targetCount, roundsComplete, totalCount),

            SizedBox(height: 6.h),

            // ── ARC + POUCH AREA ─────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: isCompleted ? null : () => _onCounterTap(userId, sessionId, currentCount),
                behavior: HitTestBehavior.opaque,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_beadController, _pouchController]),
                  builder: (context, _) {
                    return Stack(
                      children: [
                        // Background lattice
                        Positioned.fill(
                          child: CustomPaint(painter: _BgPatternPainter()),
                        ),

                        // Bead arc
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BeadPainter(
                              total: targetCount,
                              counted: currentCount,
                              animProgress: _beadController.value,
                              animatingIndex: _animatingBeadIndex,
                              beadColor: _selectedBeadColor,
                            ),
                          ),
                        ),

                        // Pouch (bottom-right)
                        Positioned(
                          right: 20.w,
                          bottom: 10.h,
                          width: 70.w,
                          height: 90.h,
                          child: CustomPaint(
                            painter: _PouchPainter(
                              fillRatio: fillRatio,
                              pulseAnim: _pouchController.value,
                            ),
                          ),
                        ),

                        // Tap hint
                        if (!isCompleted && currentCount == 0)
                          Positioned(
                            bottom: 110.h,
                            left: 0,
                            right: 100.w,
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  'Tap anywhere to count',
                                  style: TextStyle(fontSize: 12.sp, color: Colors.brown[400]),
                                ),
                              ),
                            ),
                          ),

                        // Points badge (mid-session)
                        if (pointsEarned > 0 && !isCompleted)
                          Positioned(
                            top: 12.h,
                            right: 12.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB8860B).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(color: const Color(0xFFB8860B).withOpacity(0.3)),
                              ),
                              child: Text(
                                '⭐ $pointsEarned pts',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB8860B),
                                ),
                              ),
                            ),
                          ),

                        // Completion overlay
                        if (isCompleted)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _completionAnimation,
                              builder: (_, __) => Opacity(
                                opacity: _completionAnimation.value.clamp(0.0, 1.0),
                                child: Container(
                                  color: Colors.white.withOpacity(0.88),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Transform.scale(
                                        scale: _completionAnimation.value,
                                        child: const Text('🎉', style: TextStyle(fontSize: 72)),
                                      ),
                                      SizedBox(height: 12.h),
                                      Text(
                                        'Session Complete!',
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFB8860B).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(16.r),
                                        ),
                                        child: Text(
                                          '+$pointsEarned Points Earned!',
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFB8860B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── BEAD COLOR SELECTOR ──────────────────────────────
            _buildBeadColorSelector(),

            // ── ACTION BUTTONS ───────────────────────────────────
            _buildActionButtons(context, sessionId, userId),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(String userId) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          _iconButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          Text(
            'Tashbih',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          _iconButton(
            icon: Icons.history_rounded,
            onTap: () => context.read<DhikirCubit>().loadDhikirHistory(userId),
          ),
        ],
      ),
    );
  }

  Widget _buildDhikrCard(
      String dhikirText, int currentCount, int targetCount, int roundsComplete, int totalCount) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Durood',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[500], letterSpacing: 0.3)),
                SizedBox(height: 2.h),
                Text(
                  dhikirText,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    // Animated bead icon + count
                    AnimatedBuilder(
                      animation: _beadController,
                      builder: (_, __) {
                        final scale = 1.0 + 0.18 * math.sin(_beadController.value * math.pi);
                        return Transform.scale(
                          scale: scale,
                          child: Row(
                            children: [
                              const Text('🟤', style: TextStyle(fontSize: 14)),
                              SizedBox(width: 4.w),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$currentCount',
                                      style: TextStyle(
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' /$targetCount',
                                      style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 14.w),
                    Text(
                      'Round: ${roundsComplete + 1}  Total: $totalCount',
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, size: 16.w, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildBeadColorSelector() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ..._beadColors.map((color) {
            final isSelected = _selectedBeadColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedBeadColor = color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: 5.w),
                width: isSelected ? 44.w : 38.w,
                height: isSelected ? 44.w : 38.w,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(isSelected ? 0.5 : 0.25),
                      blurRadius: isSelected ? 10 : 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () {
              // Could open color picker or close
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 5.w),
              width: 38.w,
              height: 38.w,
              decoration: const BoxDecoration(
                color: Color(0xFF333333),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 17.w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String sessionId, String userId) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.read<DhikirCubit>().completeSession(sessionId),
              icon: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              label: Text(
                'Complete',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          ElevatedButton.icon(
            onPressed: () => context.read<DhikirCubit>().deleteSession(sessionId),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            label: Text(
              'Reset',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  INITIAL SCREEN
  // ─────────────────────────────────────────────────────────────
  Widget _buildInitialScreen(String userId) {
    final suggestions = context.read<DhikirCubit>().getDhikirSuggestions();

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        title: Text('Tashbih',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryGreen),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20.h),
            // Decorative bead icon
            Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8C49A), Color(0xFF8B6240)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC49A6C).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: Icon(Icons.brightness_5_rounded, size: 44.w, color: Colors.white),
            ),
            SizedBox(height: 20.h),
            Text('Dhikir Counter',
                style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
            SizedBox(height: 8.h),
            Text('Choose a dhikir and set your target',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                textAlign: TextAlign.center),
            SizedBox(height: 32.h),

            // Dhikir Dropdown
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: DropdownButton<String>(
                value: _selectedDhikir,
                hint: Text('Select Dhikir', style: TextStyle(fontSize: 15.sp, color: Colors.grey[500])),
                isExpanded: true,
                underline: const SizedBox(),
                items: suggestions.map((d) {
                  return DropdownMenuItem<String>(
                    value: d,
                    child: Text(d,
                        style: TextStyle(fontSize: 15.sp),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedDhikir = v),
              ),
            ),

            SizedBox(height: 28.h),

            // Target Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Target Count',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '$_targetCount',
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Slider(
              value: _targetCount.toDouble(),
              min: 10,
              max: 100,
              divisions: 9,
              activeColor: AppColors.primaryGreen,
              inactiveColor: AppColors.primaryGreen.withOpacity(0.2),
              onChanged: (v) => setState(() => _targetCount = v.toInt()),
            ),

            SizedBox(height: 36.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDhikir != null ? () => _startNewSession(userId) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  elevation: 0,
                ),
                child: Text('Start Session',
                    style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),

            const Spacer(),

            TextButton.icon(
              onPressed: () => context.read<DhikirCubit>().loadDhikirHistory(userId),
              icon: Icon(Icons.history, size: 20.w, color: AppColors.primaryGreen),
              label: Text('View History',
                  style: TextStyle(fontSize: 15.sp, color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HISTORY SCREEN
  // ─────────────────────────────────────────────────────────────
  Widget _buildHistoryScreen(String userId, List<Map<String, dynamic>> sessions) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18.w, color: const Color(0xFF1A1A2E)),
          onPressed: () => context.read<DhikirCubit>().loadCurrentSession(userId),
        ),
        title: Text('Dhikir History',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
      ),
      body: sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📿', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16.h),
                  Text('No sessions yet',
                      style: TextStyle(fontSize: 18.sp, color: Colors.grey[500])),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final s = sessions[index];
                final isCompleted = s['isCompleted'] as bool? ?? false;
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    leading: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primaryGreen.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle_rounded : Icons.pending_rounded,
                        color: isCompleted ? AppColors.primaryGreen : Colors.orange,
                        size: 22.w,
                      ),
                    ),
                    title: Text(
                      s['dhikirText'],
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${s['currentCount']}/${s['targetCount']} beads  •  ⭐ ${s['pointsEarned']} pts',
                      style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  ERROR SCREEN
  // ─────────────────────────────────────────────────────────────
  Widget _buildErrorScreen(String message, String userId) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64.w, color: Colors.redAccent),
              SizedBox(height: 16.h),
              Text('Something went wrong',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.red[700])),
              SizedBox(height: 8.h),
              Text(message,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center),
              SizedBox(height: 28.h),
              ElevatedButton.icon(
                onPressed: () => context.read<DhikirCubit>().loadCurrentSession(userId),
                icon: const Icon(Icons.refresh),
                label: Text('Retry', style: TextStyle(fontSize: 15.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────
  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, size: 16.w, color: const Color(0xFF2E6B9E)),
      ),
    );
  }
}