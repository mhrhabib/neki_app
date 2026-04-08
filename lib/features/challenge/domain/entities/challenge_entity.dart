enum ChallengeStatus { notStarted, active, completed, failed }

class ChallengeEntity {
  final int durationDays;
  final int rewardPoints;
  final DateTime startDate;
  final int completedDays;
  final ChallengeStatus status;
  final String? challengeType; // e.g., 'beat_satan', 'daily_prayers'
  final String? userId;

  ChallengeEntity({
    required this.durationDays,
    required this.rewardPoints,
    required this.startDate,
    required this.completedDays,
    required this.status,
    this.challengeType,
    this.userId,
  });

  DateTime get endDate => startDate.add(Duration(days: durationDays));

  bool get isCompleted => completedDays >= durationDays;

  bool get isActive => status == ChallengeStatus.active;

  int get remainingDays => durationDays - completedDays;

  double get progress => completedDays / durationDays;

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
  bool hasExpired() {
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
}
