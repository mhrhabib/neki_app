import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/set_up_di.dart';

import '../../../../components/app_background_widget.dart';
import '../../../../core/widgets/custom_back_button.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../challenge/domain/entities/challenge_entity.dart';
import '../../../challenge/data/models/challenge_model.dart';
import '../../../challenge/presentation/cubit/challenge_cubit.dart';
import '../../../points/domain/repositories/points_repository.dart';
import '../widgets/addiction_counter_widget.dart';
import '../widgets/addiction_calendar_widget.dart';
import '../../../challenge/presentation/widgets/challenge_progress_widget.dart';
import '../../domain/addiction_milestones.dart';

class AddictionTrackerScreen extends StatefulWidget {
  /// The specific addiction type to render — e.g. 'addiction_porn'.
  /// If null, falls back to the first active addiction in the user's
  /// challenge map (legacy behaviour for users who only quit one thing).
  final String? typeKey;

  const AddictionTrackerScreen({super.key, this.typeKey});

  @override
  State<AddictionTrackerScreen> createState() => _AddictionTrackerScreenState();
}

class _AddictionTrackerScreenState extends State<AddictionTrackerScreen> {
  /// Cached past attempts for the currently displayed addiction. Loaded
  /// once per screen open; reloaded after a relapse/restart.
  List<ChallengeEntity>? _pastAttempts;
  String? _pastAttemptsForKey;

  Future<void> _loadPastAttempts(ChallengeEntity addiction) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final key = ChallengeModel.typeKey(addiction.challengeType);
    if (_pastAttemptsForKey == key && _pastAttempts != null) return;
    final attempts = await context.read<ChallengeCubit>().getPastAttempts(
      authState.user.id,
      typeKey: key,
    );
    if (!mounted) return;
    setState(() {
      _pastAttempts = attempts;
      _pastAttemptsForKey = key;
    });
  }

  /// Resolves which addiction to display from the loaded challenge map.
  /// Honours the [widget.typeKey] route param when present, otherwise picks
  /// the first active addiction. Also accepts the legacy 'addiction' key
  /// for users whose docs predate per-type splitting.
  ChallengeEntity? _resolveAddiction(Map<String, ChallengeEntity> challenges) {
    final wanted = ChallengeModel.typeKey(widget.typeKey);
    if (challenges[wanted] != null) {
      return challenges[wanted];
    }
    // Prefer any addiction_* key that is active.
    for (final entry in challenges.entries) {
      if (entry.key.startsWith('addiction') && entry.value.isActive) {
        return entry.value;
      }
    }
    return challenges['addiction']; // legacy
  }

  @override
  void initState() {
    super.initState();
    // Load challenges from Firestore to ensure we have the latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        context.read<ChallengeCubit>().loadChallenge(authState.user.id);
      }
    });
    _checkInitialStatus();
  }

  void _checkInitialStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = context.read<ChallengeCubit>().state;
      if (state is ChallengeLoaded) {
        final addiction = _resolveAddiction(state.challenges);
        if (addiction != null) {
          // Note: missed-day dialog is intentionally NOT shown for addiction.
          // Addiction streaks are continuous — only an explicit "I relapsed"
          // resets the clock. Skipping a daily pledge is fine.
          await _awardPendingMilestones(addiction);
          await _loadPastAttempts(addiction);
        }
      }
    });
  }

  /// Walks the milestone ladder and credits Neki points for every threshold
  /// the user has crossed since the last time we ran. Idempotent via a
  /// per-streak SharedPreferences key (resets on relapse via
  /// [_clearMilestoneLedger]).
  Future<void> _awardPendingMilestones(ChallengeEntity addiction) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final userId = authState.user.id;

    final prefs = getIt<SharedPreferences>();
    // Key includes the streak start so a relapse + restart automatically
    // gives a fresh ledger without us having to remember to clear it.
    final ledgerKey = _milestoneLedgerKey(addiction);
    final lastAwarded = prefs.getInt(ledgerKey) ?? 0;

    final pending = unawardedMilestones(addiction.daysClean, lastAwarded);
    if (pending.isEmpty) return;

    final points = getIt<PointsRepository>();
    int? newHighWater;
    for (final m in pending) {
      try {
        await points.addPoints(
          userId: userId,
          points: m.points,
          source: 'addiction_milestone_${m.days}d',
        );
        newHighWater = m.days;
      } catch (e) {
        debugPrint('⚠️ [Addiction] milestone ${m.days}d award failed: $e');
        break; // stop so we retry from this point next session
      }
    }

    if (newHighWater != null) {
      await prefs.setInt(ledgerKey, newHighWater);
      if (mounted) {
        final last = pending.last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryGreen,
            content: Text(
              '🎉 ${last.title} — +${last.points} Neki points',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
      }
    }
  }

  String _milestoneLedgerKey(ChallengeEntity a) =>
      'addiction_milestones_${a.challengeType}_${a.startDate.millisecondsSinceEpoch}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          appBackgroundWidget(),
          BlocListener<ChallengeCubit, ChallengeState>(
            listener: (context, state) {
              if (state is ChallengeError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              } else if (state is ChallengeDayCompleted) {
                _showSuccessDialog(state.challenge, state.pointsEarned);
              } else if (state is ChallengeFullyCompleted) {
                _showSuccessDialog(
                  state.challenge,
                  state.totalPointsEarned,
                  isFinal: true,
                );
              }
            },
            child: BlocBuilder<ChallengeCubit, ChallengeState>(
              builder: (context, state) {
                if (state is ChallengeLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.goldAccent,
                    ),
                  );
                }

                // Extract the challenge map from whatever state we are in.
                // This ensures the screen doesn't go blank or stuck on a loader
                // when a day is completed.
                Map<String, ChallengeEntity>? challenges;
                if (state is ChallengeLoaded) {
                  challenges = state.challenges;
                } else if (state is ChallengeDayCompleted) {
                  challenges = state.allChallenges;
                } else if (state is ChallengeFullyCompleted) {
                  challenges = state.allChallenges;
                }

                if (challenges != null) {
                  final addiction = _resolveAddiction(challenges);
                  final beatSatan = challenges['beat_satan'];

                  if (addiction == null) {
                    return _buildNoActiveChallengeView();
                  }

                  // Trigger milestone awards + history load AFTER the cubit
                  // has loaded for THIS specific addiction. Doing this from
                  // initState alone misses the case where the user just
                  // created a brand-new streak (cubit was still Loading at
                  // initState time). The guards inside each method make
                  // these safe to call repeatedly.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _awardPendingMilestones(addiction);
                    _loadPastAttempts(addiction);
                  });

                  return SafeArea(
                    child: Column(
                      children: [
                        _buildAppBar(addiction),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 10.h,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AddictionCounterWidget(
                                  startDate: addiction.startDate,
                                ),
                                SizedBox(height: 24.h),
                                _buildMilestoneCard(addiction),
                                SizedBox(height: 24.h),
                                AddictionCalendarWidget(challenge: addiction),
                                SizedBox(height: 24.h),
                                _buildHistoryCard(addiction),
                                SizedBox(height: 24.h),
                                _buildMotivationCard(),
                                SizedBox(height: 24.h),
                                _buildActionButtons(addiction),

                                if (beatSatan != null &&
                                    beatSatan.isActive) ...[
                                  SizedBox(height: 40.h),
                                  _buildBeatSatanSection(beatSatan),
                                ],

                                SizedBox(height: 40.h),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ChallengeError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 48.sp,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Error Loading Challenge',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          state.message,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ChallengeEntity addiction) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        children: [
          const CustomBackButton(),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Text(
                    "Recovery Center",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _getAddictionLabel(addiction.challengeType),
                    style: TextStyle(
                      color: AppColors.goldAccent.withValues(alpha: 0.7),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 48.w), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(ChallengeEntity addiction) {
    final next = nextMilestoneFor(addiction.daysClean);
    if (next == null) {
      // User has cleared the entire ladder — celebrate and stop nagging.
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.goldAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.goldAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.emoji_events, color: AppColors.goldAccent, size: 28.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'You\'ve passed every milestone. Keep going — every day is its own victory.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final progress = (addiction.daysClean / next.days).clamp(0.0, 1.0);
    final daysLeft = next.days - addiction.daysClean;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                color: AppColors.goldAccent,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'NEXT MILESTONE',
                style: TextStyle(
                  color: AppColors.goldAccent.withValues(alpha: 0.8),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '+${next.points} pts',
                style: TextStyle(
                  color: AppColors.goldAccent,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            next.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            daysLeft == 1 ? '1 day to go' : '$daysLeft days to go',
            style: TextStyle(color: Colors.white54, fontSize: 12.sp),
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.h,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation(AppColors.goldAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ChallengeEntity addiction) {
    final attempts = _pastAttempts;
    if (attempts == null) {
      // First load — quietly render nothing instead of a flash of "no history".
      return const SizedBox.shrink();
    }

    // The user's longest-ever streak: max(current days clean, all archived).
    final pastBest = attempts.fold<int>(0, (m, a) {
      final d = a is ChallengeModel
          ? (a.toJson()['daysClean'] as int? ?? 0)
          : 0;
      return d > m ? d : m;
    });
    final currentClean = addiction.daysClean;
    final longest = currentClean > pastBest ? currentClean : pastBest;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: AppColors.goldAccent,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'YOUR JOURNEY',
                style: TextStyle(
                  color: AppColors.goldAccent.withValues(alpha: 0.8),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildStat(
                'Longest streak',
                '$longest day${longest == 1 ? '' : 's'}',
              ),
              SizedBox(width: 24.w),
              _buildStat('Past attempts', '${attempts.length}'),
            ],
          ),
          if (attempts.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
            SizedBox(height: 12.h),
            ...attempts.take(5).map(_buildAttemptRow),
            if (attempts.length > 5)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  '+ ${attempts.length - 5} earlier attempts',
                  style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white38, fontSize: 11.sp),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildAttemptRow(ChallengeEntity attempt) {
    final raw = attempt is ChallengeModel
        ? attempt.toJson()
        : <String, dynamic>{};
    final days = raw['daysClean'] as int? ?? 0;
    final start = attempt.startDate;
    final dateLabel =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6.sp, color: Colors.white24),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Started $dateLabel',
              style: TextStyle(color: Colors.white60, fontSize: 12.sp),
            ),
          ),
          Text(
            '$days day${days == 1 ? '' : 's'}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.goldAccent,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'NEKI MOTIVATION',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.sp,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            '"Indeed, Allah is with the patient." - Quran 2:153',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ChallengeEntity addiction) {
    final bool isWindowOpen = addiction.isCheckInWindowOpen;
    final bool isCheckedIn = addiction.checkedInToday;

    return Column(
      children: [
        // Mark Clean Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: isCheckedIn
                ? []
                : [
                    BoxShadow(
                      color:
                          (isWindowOpen ? AppColors.goldAccent : Colors.white10)
                              .withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: (isWindowOpen && !isCheckedIn)
                ? () => _markClean(addiction)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isCheckedIn
                  ? Colors.white10
                  : AppColors.goldAccent,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCheckedIn
                      ? Icons.check_circle
                      : Icons.verified_user_outlined,
                  size: 20.sp,
                  color: isCheckedIn ? AppColors.successGreen : Colors.black,
                ),
                SizedBox(width: 12.w),
                Text(
                  isCheckedIn
                      ? 'DONE FOR TODAY!'
                      : isWindowOpen
                      ? 'I STAYED CLEAN TODAY ✅'
                      : 'AVAILABLE AFTER 8 PM',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: isCheckedIn ? Colors.white38 : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Allow user to mark today complete at any time (with confirmation).
        if (!isCheckedIn && addiction.isCheckInWindowOpen)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                // Confirm to avoid accidental taps
                final confirm =
                    await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1C1C1E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        title: Text(
                          'Mark Today as Complete?',
                          style: TextStyle(color: AppColors.goldAccent),
                        ),
                        content: Text(
                          'Marking today as complete will record your sobriety for today. Are you sure?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Mark'),
                          ),
                        ],
                      ),
                    ) ??
                    false;

                if (confirm) _markClean(addiction);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white12),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'Mark Today as Complete',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),

        // Relapse Button
        TextButton(
          onPressed: () => _showRelapseDialog(addiction),
          style: TextButton.styleFrom(
            foregroundColor: Colors.redAccent.withValues(alpha: 0.7),
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.heart_broken_outlined, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'I RELAPSED 💔',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBeatSatanSection(ChallengeEntity beatSatan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Text(
            'ACTIVE CHALLENGES',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ChallengeProgressWidget(challenge: beatSatan),
      ],
    );
  }

  Widget _buildNoActiveChallengeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_moon_outlined, color: Colors.white24, size: 64.sp),
          SizedBox(height: 24.h),
          Text(
            'No Active Recovery Plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: () => context.go(RouteNames.addiction),
            child: const Text('Choose a plan'),
          ),
        ],
      ),
    );
  }

  String _getAddictionLabel(String? type) {
    if (type == null) return 'Recovery';
    final parts = type.split('_');
    if (parts.length >= 2) {
      switch (parts[1]) {
        case 'porn':
          return 'Porn Addiction';
        case 'smoking':
          return 'Smoking';
        case 'alcohol':
          return 'Alcohol';
        case 'gambling':
          return 'Gambling';
      }
    }
    return 'Recovery';
  }

  void _markClean(ChallengeEntity addiction) {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<ChallengeCubit>().completeTodayChallenge(
        userId: authState.user.id,
        typeKey: ChallengeModel.typeKey(addiction.challengeType),
      );
    }
  }

  void _showRelapseDialog(ChallengeEntity addiction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
        ),
        title: Text(
          'Pick yourself back up',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ',
              style: TextStyle(
                color: AppColors.goldAccent,
                fontSize: 20.sp,
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              '"Do not despair of the mercy of Allah"',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13.sp,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Text(
              'A relapse is a moment, not a failure of your journey. Restarting shows true strength of character.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'NOT YET',
              style: TextStyle(
                color: Colors.white24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _restartChallenge(addiction),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'RESTART NOW 🔄',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _restartChallenge(ChallengeEntity addiction) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final key = ChallengeModel.typeKey(addiction.challengeType);
    final cubit = context.read<ChallengeCubit>();
    final navigator = Navigator.of(context);

    // Close the dialog up-front so the user gets immediate feedback.
    navigator.pop();

    // Abandon archives the old streak and clears the active doc; the new
    // streak must wait for that delete to land or it will be wiped.
    await cubit.abandonChallenge(authState.user.id, typeKey: key);
    if (!mounted) return;
    await cubit.startChallenge(
      userId: authState.user.id,
      durationDays: addiction.durationDays,
      rewardPoints: addiction.rewardPoints,
      challengeType: addiction.challengeType,
    );
  }

  void _showSuccessDialog(
    ChallengeEntity challenge,
    int points, {
    bool isFinal = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
          side: BorderSide(color: AppColors.goldAccent.withValues(alpha: 0.2)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.h),
            Icon(
              isFinal ? Icons.emoji_events_rounded : Icons.check_circle_rounded,
              color: AppColors.goldAccent,
              size: 64.sp,
            ),
            SizedBox(height: 24.h),
            Text(
              isFinal ? 'CHALLENGE COMPLETE!' : 'ALHAMDULILLAH!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              isFinal
                  ? 'You have successfully completed your recovery goal. May Allah grant you steadfastness.'
                  : 'You stayed clean today! Every small victory builds your character.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars_rounded,
                    color: AppColors.goldAccent,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '+$points Neki Points',
                    style: TextStyle(
                      color: AppColors.goldAccent,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<ChallengeCubit>().resetToLoaded();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                child: Text(
                  'CONTINUE',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
