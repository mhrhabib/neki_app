/// Reward thresholds modeled after I Am Sober / Nomo / QuitNow.
/// Each entry is the calendar-day mark at which the user earns that
/// many Neki points. The list MUST stay sorted ascending by [days].
class AddictionMilestone {
  final int days;
  final int points;
  final String title;
  const AddictionMilestone(this.days, this.points, this.title);
}

const List<AddictionMilestone> kAddictionMilestones = [
  AddictionMilestone(1, 50, 'First Day'),
  AddictionMilestone(3, 100, '3 Days Strong'),
  AddictionMilestone(7, 250, '1 Week Clean'),
  AddictionMilestone(14, 500, '2 Weeks'),
  AddictionMilestone(30, 1000, '1 Month'),
  AddictionMilestone(60, 2000, '2 Months'),
  AddictionMilestone(90, 3500, '3 Months'),
  AddictionMilestone(180, 7000, '6 Months'),
  AddictionMilestone(365, 15000, '1 Year'),
];

/// The next unreached milestone for a given streak length, or null if the
/// user has cleared the entire ladder.
AddictionMilestone? nextMilestoneFor(int daysClean) {
  for (final m in kAddictionMilestones) {
    if (m.days > daysClean) return m;
  }
  return null;
}

/// The milestone the user is currently working toward — same as
/// [nextMilestoneFor] but **inclusive** of milestones whose threshold equals
/// today's [daysClean]. Used by the home progress card so a user who just
/// hit Day 7 sees "Day 7 of 7 (100%)" before the target rolls forward to 14.
AddictionMilestone? currentMilestoneFor(int daysClean) {
  for (final m in kAddictionMilestones) {
    if (m.days >= daysClean) return m;
  }
  return null;
}

/// All milestones the user has reached but not yet been rewarded for, given
/// their current [daysClean] and the highest day already awarded.
Iterable<AddictionMilestone> unawardedMilestones(
  int daysClean,
  int lastAwardedDays,
) {
  return kAddictionMilestones.where(
    (m) => m.days <= daysClean && m.days > lastAwardedDays,
  );
}
