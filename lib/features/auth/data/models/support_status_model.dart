import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SupportStatus extends Equatable {
  final DateTime? lastDonationDate;
  final double lastDonationAmount;
  final double totalDonated;
  final int donationCount;
  final DateTime? lastPromptDate;
  final bool hasDeclinedRecently;
  final DateTime? lastDeclineDate;

  const SupportStatus({
    this.lastDonationDate,
    this.lastDonationAmount = 0,
    this.totalDonated = 0,
    this.donationCount = 0,
    this.lastPromptDate,
    this.hasDeclinedRecently = false,
    this.lastDeclineDate,
  });

  bool get isSupporter => totalDonated > 0;

  @override
  List<Object?> get props => [
        lastDonationDate,
        lastDonationAmount,
        totalDonated,
        donationCount,
        lastPromptDate,
        hasDeclinedRecently,
        lastDeclineDate,
      ];

  SupportStatus copyWith({
    DateTime? lastDonationDate,
    double? lastDonationAmount,
    double? totalDonated,
    int? donationCount,
    DateTime? lastPromptDate,
    bool? hasDeclinedRecently,
    DateTime? lastDeclineDate,
  }) {
    return SupportStatus(
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      lastDonationAmount: lastDonationAmount ?? this.lastDonationAmount,
      totalDonated: totalDonated ?? this.totalDonated,
      donationCount: donationCount ?? this.donationCount,
      lastPromptDate: lastPromptDate ?? this.lastPromptDate,
      hasDeclinedRecently: hasDeclinedRecently ?? this.hasDeclinedRecently,
      lastDeclineDate: lastDeclineDate ?? this.lastDeclineDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastDonationDate': lastDonationDate?.toIso8601String(),
      'lastDonationAmount': lastDonationAmount,
      'totalDonated': totalDonated,
      'donationCount': donationCount,
      'lastPromptDate': lastPromptDate?.toIso8601String(),
      'hasDeclinedRecently': hasDeclinedRecently,
      'lastDeclineDate': lastDeclineDate?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lastDonationDate': lastDonationDate != null
          ? Timestamp.fromDate(lastDonationDate!)
          : null,
      'lastDonationAmount': lastDonationAmount,
      'totalDonated': totalDonated,
      'donationCount': donationCount,
      'lastPromptDate': lastPromptDate != null
          ? Timestamp.fromDate(lastPromptDate!)
          : null,
      'hasDeclinedRecently': hasDeclinedRecently,
      'lastDeclineDate': lastDeclineDate != null
          ? Timestamp.fromDate(lastDeclineDate!)
          : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory SupportStatus.fromJson(Map<String, dynamic> json) {
    return SupportStatus(
      lastDonationDate: _parseDate(json['lastDonationDate']),
      lastDonationAmount: (json['lastDonationAmount'] ?? 0).toDouble(),
      totalDonated: (json['totalDonated'] ?? 0).toDouble(),
      donationCount: (json['donationCount'] ?? 0) as int,
      lastPromptDate: _parseDate(json['lastPromptDate']),
      hasDeclinedRecently: json['hasDeclinedRecently'] ?? false,
      lastDeclineDate: _parseDate(json['lastDeclineDate']),
    );
  }

  factory SupportStatus.fromFirestore(Map<String, dynamic> data) {
    return SupportStatus(
      lastDonationDate: _parseTimestamp(data['lastDonationDate']),
      lastDonationAmount: (data['lastDonationAmount'] ?? 0).toDouble(),
      totalDonated: (data['totalDonated'] ?? 0).toDouble(),
      donationCount: (data['donationCount'] ?? 0) as int,
      lastPromptDate: _parseTimestamp(data['lastPromptDate']),
      hasDeclinedRecently: data['hasDeclinedRecently'] ?? false,
      lastDeclineDate: _parseTimestamp(data['lastDeclineDate']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
