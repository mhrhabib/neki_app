import '../../../addiction/domain/addiction_milestones.dart';

enum ChallengeStatus { notStarted, active, completed, failed }

class ChallengeEntity {
  final int durationDays;
  final int rewardPoints;
  final DateTime startDate;
  final int completedDays;
  final ChallengeStatus status;
  final String? challengeType; // e.g., 'beat_satan', 'daily_prayers'
  final String? userId;
  /// Timestamp when the final day was checked in. `null` until the challenge
  /// is fully completed. Used to gate the 24h celebration window on home.
  final DateTime? completedAt;

  ChallengeEntity({
    required this.durationDays,
    required this.rewardPoints,
    required this.startDate,
    required this.completedDays,
    required this.status,
    this.challengeType,
    this.userId,
    this.completedAt,
  });

  DateTime get endDate => startDate.add(Duration(days: durationDays));

  /// Addiction tracking is open-ended (`durationDays == 0`) and never
  /// "completes" globally — top recovery apps (I Am Sober, Nomo) treat
  /// sobriety as continuous. Instead of completing once, the home card
  /// climbs a ladder of milestones (7 → 14 → 21 → 30 → …). Legacy
  /// addiction docs created with a fixed duration (e.g.
  /// `addiction_gambling_7`) keep their hard finish line.
  bool get isAddictionType =>
      challengeType?.startsWith('addiction') ?? false;

  /// The milestone the unbounded-addiction user is currently aiming for —
  /// e.g. "1 Week Clean" at 7 days. Null for non-addictions, fixed-duration
  /// challenges, or once the user has cleared the entire ladder.
  AddictionMilestone? get currentMilestone {
    if (!isAddictionType || durationDays > 0) return null;
    return currentMilestoneFor(daysClean);
  }

  /// Day-count goal driving the home progress bar. For fixed-duration
  /// challenges this is just [durationDays]. For unbounded addictions it is
  /// the current milestone's day mark — so the bar always has a concrete,
  /// reachable end. Returns 0 once an addiction user has cleared every
  /// milestone (>365 days), in which case the UI falls back to the lifetime
  /// "Days Clean" counter.
  int get effectiveDuration {
    if (durationDays > 0) return durationDays;
    return currentMilestone?.days ?? 0;
  }

  /// Days that count toward [effectiveDuration]. Addiction streaks advance
  /// with the calendar (skipping a check-in doesn't break sobriety), normal
  /// challenges (Beat Satan etc.) advance only with explicit check-ins.
  /// Clamped so display values never exceed the current goal.
  int get progressDays {
    final basis = isAddictionType ? daysClean : completedDays;
    final cap = effectiveDuration;
    if (cap <= 0) return basis;
    return basis.clamp(0, cap);
  }

  /// Used by the cubit's archive flow — only fixed-duration challenges
  /// (Beat Satan, legacy `addiction_*_7`) ever truly "complete". Unbounded
  /// addictions stay live forever and roll through milestones in place.
  bool get isCompleted {
    if (durationDays <= 0) return false;
    return progressDays >= durationDays;
  }

  /// True when an unbounded addiction has just hit (or passed) its current
  /// milestone day. Drives the green "Completed" badge on the home card
  /// without triggering the archive-and-remove flow.
  bool get isAtMilestone {
    if (durationDays > 0) return false; // fixed challenges use isCompleted
    final m = currentMilestone;
    if (m == null) return false;
    return daysClean >= m.days;
  }

  bool get isActive => status == ChallengeStatus.active;

  /// Effective completion timestamp. For docs written after the
  /// `completedAt` field was added this is the real check-in time. For
  /// legacy docs (`completedAt == null`) we fall back to the natural
  /// finish line `startDate + durationDays` so the 24h window still
  /// closes — otherwise old trophies stay pinned to home forever.
  DateTime? get _effectiveCompletedAt {
    if (!isCompleted) return null;
    return completedAt ?? startDate.add(Duration(days: durationDays));
  }

  /// While true, the home screen shows the full "Completed" celebration card.
  /// After 24 hours we archive the challenge and surface it as a profile badge
  /// instead, so the home screen doesn't keep stale trophies pinned forever.
  bool get isInCelebrationWindow {
    final ts = _effectiveCompletedAt;
    if (ts == null) return false;
    return DateTime.now().difference(ts).inHours < 24;
  }

  /// Completed challenge whose 24h celebration has elapsed — caller should
  /// archive it to the user's badge collection and remove it from home.
  bool get celebrationExpired {
    final ts = _effectiveCompletedAt;
    if (ts == null) return false;
    return DateTime.now().difference(ts).inHours >= 24;
  }

  int get remainingDays {
    final cap = effectiveDuration;
    return cap <= 0 ? 0 : cap - progressDays;
  }

  /// Progress toward the current goal — `durationDays` for fixed challenges,
  /// the active milestone's day mark for unbounded addictions. Returns 0
  /// when there is no active goal (addiction user past every milestone).
  double get progress {
    final cap = effectiveDuration;
    if (cap <= 0) return 0.0;
    return (progressDays / cap).clamp(0.0, 1.0);
  }

  /// Check if user can complete today's challenge
  bool canCompleteToday() {
    if (status != ChallengeStatus.active) return false;
    if (hasExpired()) return false;

    final today = DateTime.now();

    // If no days have been completed yet, the user should be able to complete today's task
    if (completedDays == 0) {
      // Allow completion only on or after the start date
      return !today.isBefore(startDate);
    }

    // For completedDays > 0, the last completion was on startDate + (completedDays - 1)
    final lastCompletionDate = startDate.add(Duration(days: completedDays - 1));

    // Return true when today is a different day than the last completion date
    return today.day != lastCompletionDate.day ||
        today.month != lastCompletionDate.month ||
        today.year != lastCompletionDate.year;
  }

  /// Check if challenge has expired (missed too many days).
  /// Uses calendar days and gives a 1-day grace period so users
  /// don't lose progress due to timezone/time-of-day edge cases.
  ///
  /// Addiction tracking NEVER expires — only an explicit "I relapsed"
  /// resets the streak. Skipping the daily pledge does not break sobriety.
  bool hasExpired() {
    if (isAddictionType) return false;
    if (status != ChallengeStatus.active) return false;
    if (isCompleted) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final daysSinceStart = today.difference(startDay).inDays;

    // User gets a 1-day grace period: if they're more than 1 full
    // calendar day behind on completions, the challenge is expired.
    return daysSinceStart > completedDays + 1;
  }

  /// Calendar days clean since [startDate]. This is the user-visible
  /// streak number — independent of how many times they've checked in.
  int get daysClean {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return today.difference(start).inDays;
  }

  // ── Addiction tracker helpers ──────────────────────────────────────────────

  /// The last day the user checked in (0-indexed calendar day from startDate).
  DateTime? get _lastCheckInDate {
    if (completedDays == 0) return null;
    final d = startDate.add(Duration(days: completedDays - 1));
    return DateTime(d.year, d.month, d.day);
  }

  /// True if the user skipped checking in on the previous calendar day.
  /// Shown as a "missed day" warning on the next app open.
  bool get missedYesterday {
    if (!isActive || completedDays == 0) return false;
    final last = _lastCheckInDate!;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final y = DateTime(yesterday.year, yesterday.month, yesterday.day);
    return last.isBefore(y);
  }

  /// True after 20:00 (8 PM) local time — the check-in window is open.
  bool get isCheckInWindowOpen => DateTime.now().hour >= 20;

  /// True if the user already tapped "Mark Clean" today.
  bool get checkedInToday {
    final last = _lastCheckInDate;
    if (last == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return last == today;
  }
}
