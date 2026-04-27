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
  Future<void> unmarkFasted({required String userId, required DateTime date}) async {
    final docId = '${userId}_${date.toIso8601String().split('T')[0]}';
    debugPrint('🍽️ [Roza] Unmarking date: $docId');
    final ok = await _firestoreService.deleteDocument(
      collectionPath: _collectionPath,
      documentId: docId,
    );
    if (!ok) throw Exception('Failed to unmark Roza date');
  }

  @override
  Future<List<RozaEntity>> getRozaHistory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      debugPrint('🍽️ [Roza] Getting Roza history from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // Alternative approach: Get all user's Roza records and filter client-side
      // This avoids the composite index requirement
      final querySnapshot = await _firestoreService.getCollection(
        collectionPath: _collectionPath,
        queryBuilder: (query) => query.where('userId', isEqualTo: userId),
      );

      final allUserRecords = querySnapshot.docs
          .map((doc) => RozaModel.fromJson(doc.data()))
          .toList();

      // Filter by date range client-side
      final filteredRecords = allUserRecords.where((record) {
        final recordDate = record.date;
        return recordDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               recordDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      // Sort by date
      filteredRecords.sort((a, b) => a.date.compareTo(b.date));

      debugPrint('✅ [Roza] Retrieved ${filteredRecords.length} Roza records (client-side filtering)');
      return filteredRecords;
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

}
