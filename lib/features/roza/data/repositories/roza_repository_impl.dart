import 'package:flutter/foundation.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/roza_entity.dart';
import '../../domain/repositories/roza_repository.dart';
import '../models/roza_model.dart';

class RozaRepositoryImpl implements RozaRepository {
  final FirestoreService _firestoreService;
  static const String _collectionPath = 'roza_records';

  RozaRepositoryImpl(this._firestoreService);

  @override
  Future<RozaEntity> markFasted({required String userId, required DateTime date, String? notes}) async {
    try {
      debugPrint('🍽️ [Roza] Marking date as fasted: ${date.toIso8601String()}');

      // Create the fasted record
      final rozaRecord = RozaModel(
        id: '${userId}_${date.toIso8601String().split('T')[0]}', // Unique ID based on user and date
        userId: userId,
        date: date,
        isFasted: true,
        pointsEarned: 100,
        notes: notes,
      );

      // Save to Firestore
      final success = await _firestoreService.setDocument(
        collectionPath: _collectionPath,
        documentId: rozaRecord.id,
        data: rozaRecord.toJson(),
      );

      if (!success) {
        throw Exception('Failed to save Roza record');
      }

      debugPrint('✅ [Roza] Successfully marked date as fasted');
      return rozaRecord;
    } catch (e) {
      debugPrint('❌ [Roza] Error marking date as fasted: $e');
      rethrow;
    }
  }

  @override
  Future<List<RozaEntity>> getRozaHistory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      debugPrint('🍽️ [Roza] Getting Roza history from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      final querySnapshot = await _firestoreService.getCollection(
        collectionPath: _collectionPath,
        queryBuilder: (query) => query
            .where('userId', isEqualTo: userId)
            .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
            .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
            .orderBy('date'),
      );

      final rozaRecords = querySnapshot.docs.map((doc) => RozaModel.fromJson(doc.data())).toList();

      debugPrint('✅ [Roza] Retrieved ${rozaRecords.length} Roza records');
      return rozaRecords;
    } catch (e) {
      debugPrint('❌ [Roza] Error getting Roza history: $e');
      rethrow;
    }
  }

  @override
  Future<int> getCurrentMonthFastCount(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final rozaRecords = await getRozaHistory(userId: userId, startDate: startOfMonth, endDate: endOfMonth);

      final fastCount = rozaRecords.where((record) => record.isFasted).length;
      debugPrint('✅ [Roza] Current month fast count: $fastCount');
      return fastCount;
    } catch (e) {
      debugPrint('❌ [Roza] Error getting current month fast count: $e');
      rethrow;
    }
  }

  /// Get all Roza records for a specific month to determine calendar state
  Future<List<RozaEntity>> getMonthlyRozaRecords(String userId, int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return await getRozaHistory(userId: userId, startDate: startDate, endDate: endDate);
  }

  @override
  Future<void> markMultipleDatesFasted({required String userId, required List<DateTime> dates, String? notes}) async {
    try {
      debugPrint('🍽️ [Roza] Marking multiple dates as fasted: ${dates.length} dates');

      // First mark all selected dates as fasted
      for (final date in dates) {
        await markFasted(userId: userId, date: date, notes: notes);
      }

      // Then mark skipped dates as broken fasts
      await _markSkippedDatesAsBroken(userId: userId, selectedDates: dates);

      debugPrint('✅ [Roza] Successfully marked multiple dates as fasted');
    } catch (e) {
      debugPrint('❌ [Roza] Error marking multiple dates as fasted: $e');
      rethrow;
    }
  }

  /// Mark skipped dates as broken fasts when there are gaps in fasting
  Future<void> _markSkippedDatesAsBroken({required String userId, required List<DateTime> selectedDates}) async {
    if (selectedDates.length < 2) return;

    // Sort dates
    selectedDates.sort();

    for (int i = 0; i < selectedDates.length - 1; i++) {
      final currentDate = selectedDates[i];
      final nextDate = selectedDates[i + 1];

      // Check if there's a gap between dates
      final daysDifference = nextDate.difference(currentDate).inDays;

      if (daysDifference > 1) {
        // Mark all dates between current and next as broken fasts
        for (int j = 1; j < daysDifference; j++) {
          final skippedDate = currentDate.add(Duration(days: j));
          final skippedRecord = RozaModel(
            id: '${userId}_${skippedDate.toIso8601String().split('T')[0]}',
            userId: userId,
            date: skippedDate,
            isFasted: false, // Mark as broken fast
            pointsEarned: 0,
            notes: 'Skipped - Broken fast',
          );

          await _firestoreService.setDocument(
            collectionPath: _collectionPath,
            documentId: skippedRecord.id,
            data: skippedRecord.toJson(),
          );

          debugPrint('🍽️ [Roza] Marked skipped date as broken: ${skippedDate.toIso8601String()}');
        }
      }
    }
  }
}
