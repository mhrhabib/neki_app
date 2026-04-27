import 'package:flutter/foundation.dart';
import '../../data/models/support_status_model.dart';

class SupportTriggerService {
  static const int declineCooldownDays = 30;
  static const int smallDonationCooldownDays = 30;
  static const int mediumDonationCooldownDays = 90;
  static const int bigDonationCooldownDays = 180;
  static const int dailyRateLimitHours = 24;

  static const double mediumThreshold = 5;
  static const double bigThreshold = 10;

  static const List<int> addictionMilestones = [3, 7, 14, 30, 60, 90, 180, 365];
  static const int salahMilestoneInterval = 15;

  /// Decide whether a donation prompt may be shown for the given [status].
  ///
  /// Rules (aligned with plan):
  ///   - Declined "unable to donate" → 30-day cooldown.
  ///   - Small donation ($1–$4) → 30-day cooldown.
  ///   - Medium donation ($5–$9) → 90-day cooldown.
  ///   - Big donation ($10+) → 180-day cooldown.
  ///   - Hard cap: no more than one prompt per 24 hours.
  bool shouldAllowPrompt(SupportStatus status) {
    final now = DateTime.now();

    if (status.lastDeclineDate != null) {
      final diff = now.difference(status.lastDeclineDate!).inDays;
      if (diff < declineCooldownDays) {
        debugPrint(
          '🚫 [SupportTrigger] Silent: Decline cooldown ($diff/$declineCooldownDays days)',
        );
        return false;
      }
    }

    if (status.lastDonationDate != null) {
      final daysSince = now.difference(status.lastDonationDate!).inDays;
      final cooldown = _cooldownForAmount(status.lastDonationAmount);
      if (daysSince < cooldown) {
        debugPrint(
          '🚫 [SupportTrigger] Silent: Donation cooldown ($daysSince/$cooldown days)',
        );
        return false;
      }
    }

    if (status.lastPromptDate != null) {
      final hoursSince = now.difference(status.lastPromptDate!).inHours;
      if (hoursSince < dailyRateLimitHours) {
        debugPrint(
          '🚫 [SupportTrigger] Silent: Daily rate limit ($hoursSince/$dailyRateLimitHours h)',
        );
        return false;
      }
    }

    return true;
  }

  int _cooldownForAmount(double amount) {
    if (amount >= bigThreshold) return bigDonationCooldownDays;
    if (amount >= mediumThreshold) return mediumDonationCooldownDays;
    if (amount > 0) return smallDonationCooldownDays;
    return 0;
  }

  bool isAddictionMilestone(int daysClean) =>
      addictionMilestones.contains(daysClean);

  bool isSalahMilestone(int totalSalah) =>
      totalSalah > 0 && totalSalah % salahMilestoneInterval == 0;
}
