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

  /// Addiction tracking is open-ended and never "completes" — only the
  /// fixed-duration challenges (Beat Satan, daily-prayer streaks) have a
  /// finish line. Top recovery apps (I Am Sober, Nomo) treat sobriety as
  /// continuous: there is always another milestone ahead.
  bool get _isAddiction => challengeType?.startsWith('addiction') ?? false;

  bool get isCompleted =>
      _isAddiction ? false : completedDays >= durationDays;

  bool get isActive => status == ChallengeStatus.active;

  /// While true, the home screen shows the full "Completed" celebration card.
  /// After 24 hours we archive the challenge and surface it as a profile badge
  /// instead, so the home screen doesn't keep stale trophies pinned forever.
  bool get isInCelebrationWindow {
    if (!isCompleted || completedAt == null) return false;
    return DateTime.now().difference(completedAt!).inHours < 24;
  }

  /// Completed challenge whose 24h celebration has elapsed — caller should
  /// archive it to the user's badge collection and remove it from home.
  bool get celebrationExpired {
    if (!isCompleted || completedAt == null) return false;
    return DateTime.now().difference(completedAt!).inHours >= 24;
  }

  int get remainingDays => durationDays <= 0 ? 0 : durationDays - completedDays;

  /// For addiction (durationDays=0), progress is always 0.
  /// For normal challenges, it's completedDays / durationDays clamped to [0, 1].
  double get progress {
    if (durationDays == 0) return 0.0; // Unbounded addiction streak
    return (completedDays / durationDays).clamp(0.0, 1.0);
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
    if (_isAddiction) return false;
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
