import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

/// Returns a formatted time string (HH:mm) from a nullable [DateTime].
String formatTimeOnly(DateTime? time) {
  if (time == null) return '--:--';
  return DateFormat('HH:mm').format(time);
}

/// Returns the display name for a given [Prayer].
String getPrayerName(Prayer prayer) {
  switch (prayer) {
    case Prayer.fajr:
      return 'Fazr';
    case Prayer.sunrise:
      return 'Sunrise';
    case Prayer.dhuhr:
      return 'Johuur';
    case Prayer.asr:
      return 'Asr';
    case Prayer.maghrib:
      return 'Maghrib';
    case Prayer.isha:
      return 'Isha';
    case Prayer.none:
      return 'Isha';
  }
}

/// Returns the display label (with descriptive subtitle) for the next [Prayer].
String getNextPrayerLabel(Prayer prayer) {
  switch (prayer) {
    case Prayer.fajr:
      return 'Fazr (dawn prayer)';
    case Prayer.sunrise:
      return 'Sunrise';
    case Prayer.dhuhr:
      return 'Johuur (noon prayer)';
    case Prayer.asr:
      return 'Asr (afternoon prayer)';
    case Prayer.maghrib:
      return 'Maghrib (sunset prayer)';
    case Prayer.isha:
      return 'Isha (night prayer)';
    default:
      return 'Isha (night prayer)';
  }
}
