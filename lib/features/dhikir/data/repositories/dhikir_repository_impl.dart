import 'package:flutter/foundation.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/dhikir_entity.dart';
import '../../domain/repositories/dhikir_repository.dart';
import '../models/dhikir_model.dart';

class DhikirRepositoryImpl implements DhikirRepository {
  final FirestoreService _firestoreService;
  static const String _collectionPath = 'dhikir_sessions';

  DhikirRepositoryImpl(this._firestoreService);

  @override
  Future<DhikirEntity> startDhikirSession({
    required String userId,
    required String dhikirText,
    required int targetCount,
  }) async {
    try {
      debugPrint('📿 [Dhikir] Starting session: $dhikirText, target: $targetCount');

      final sessionId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
      final session = DhikirModel(
        id: sessionId,
        userId: userId,
        dhikirText: dhikirText,
        targetCount: targetCount,
        currentCount: 0,
        pointsEarned: 0,
        date: DateTime.now(),
        isCompleted: false,
      );

      final success = await _firestoreService.setDocument(
        collectionPath: _collectionPath,
        documentId: sessionId,
        data: session.toJson(),
      );

      if (!success) {
        throw Exception('Failed to create Dhikir session');
      }

      debugPrint('✅ [Dhikir] Session started successfully');
      return session;
    } catch (e) {
      debugPrint('❌ [Dhikir] Error starting session: $e');
      rethrow;
    }
  }

  @override
  Future<DhikirEntity> incrementDhikirCount(String sessionId) async {
    try {
      debugPrint('📿 [Dhikir] Incrementing count for session: $sessionId');

      // Get current session
      final doc = await _firestoreService.getDocument(
        collectionPath: _collectionPath,
        documentId: sessionId,
      );

      if (doc == null || !doc.exists) {
        throw Exception('Dhikir session not found');
      }

      final session = DhikirModel.fromJson(doc.data()!);
      final newCount = session.currentCount + 1;
      final isCompleted = newCount >= session.targetCount;
      final pointsEarned = isCompleted ? session.totalPossiblePoints : 0;

      final updatedSession = session.copyWith(
        currentCount: newCount,
        isCompleted: isCompleted,
        pointsEarned: pointsEarned,
      );

      final success = await _firestoreService.setDocument(
        collectionPath: _collectionPath,
        documentId: sessionId,
        data: updatedSession.toJson(),
      );

      if (!success) {
        throw Exception('Failed to update Dhikir session');
      }

      debugPrint('✅ [Dhikir] Count incremented: $newCount/${session.targetCount}');
      return updatedSession;
    } catch (e) {
      debugPrint('❌ [Dhikir] Error incrementing count: $e');
      rethrow;
    }
  }

  @override
  Future<DhikirEntity> getCurrentSession(String userId) async {
    try {
      debugPrint('📿 [Dhikir] Getting current session for user: $userId');

      final querySnapshot = await _firestoreService.getCollection(
        collectionPath: _collectionPath,
        queryBuilder: (query) => query
            .where('userId', isEqualTo: userId)
            .where('isCompleted', isEqualTo: false)
            .orderBy('date', descending: true)
            .limit(1),
      );

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No active Dhikir session found');
      }

      final session = DhikirModel.fromJson(querySnapshot.docs.first.data());
      debugPrint('✅ [Dhikir] Current session found: ${session.dhikirText}');
      return session;
    } catch (e) {
      debugPrint('❌ [Dhikir] Error getting current session: $e');
      rethrow;
    }
  }

  @override
  Future<List<DhikirEntity>> getDhikirHistory(String userId, {DateTime? date}) async {
    try {
      debugPrint('📿 [Dhikir] Getting history for user: $userId');

      final querySnapshot = await _firestoreService.getCollection(
        collectionPath: _collectionPath,
        queryBuilder: (query) {
          var q = query.where('userId', isEqualTo: userId);
          if (date != null) {
            final startOfDay = DateTime(date.year, date.month, date.day);
            final endOfDay = startOfDay.add(const Duration(days: 1));
            q = q
                .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
                .where('date', isLessThan: endOfDay.toIso8601String());
          }
          return q.orderBy('date', descending: true);
        },
      );

      final sessions = querySnapshot.docs
          .map((doc) => DhikirModel.fromJson(doc.data()))
          .toList();

      debugPrint('✅ [Dhikir] Retrieved ${sessions.length} sessions');
      return sessions;
    } catch (e) {
      debugPrint('❌ [Dhikir] Error getting history: $e');
      rethrow;
    }
  }

  @override
  Future<void> completeDhikirSession(String sessionId) async {
    try {
      debugPrint('📿 [Dhikir] Completing session: $sessionId');

      final doc = await _firestoreService.getDocument(
        collectionPath: _collectionPath,
        documentId: sessionId,
      );

      if (doc == null || !doc.exists) {
        throw Exception('Dhikir session not found');
      }

      final session = DhikirModel.fromJson(doc.data()!);
      final updatedSession = session.copyWith(isCompleted: true);

      await _firestoreService.setDocument(
        collectionPath: _collectionPath,
        documentId: sessionId,
        data: updatedSession.toJson(),
      );

      debugPrint('✅ [Dhikir] Session completed');
    } catch (e) {
      debugPrint('❌ [Dhikir] Error completing session: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteDhikirSession(String sessionId) async {
    try {
      debugPrint('📿 [Dhikir] Deleting session: $sessionId');

      await _firestoreService.deleteDocument(
        collectionPath: _collectionPath,
        documentId: sessionId,
      );

      debugPrint('✅ [Dhikir] Session deleted');
    } catch (e) {
      debugPrint('❌ [Dhikir] Error deleting session: $e');
      rethrow;
    }
  }

  @override
  List<String> getDhikirSuggestions() {
    return [
      'Allahu Akbar (الله أكبر)',
      'Alhamdulillah (الحمد لله)',
      'Subhanallah (سبحان الله)',
      'La ilaha illallah (لا إله إلا الله)',
      'Astaghfirullah (أستغفر الله)',
      'Bismillah (بسم الله)',
      'Inshallah (إن شاء الله)',
      'Masha Allah (ما شاء الله)',
      'Jazakallah Khair (جزاك الله خيراً)',
      'Allahu Akbar wa lillahil hamd (الله أكبر ولله الحمد)',
      'Subhanallah wal hamdulillah wa la ilaha illallah wallahu akbar (سبحان الله والحمد لله ولا إله إلا الله والله أكبر)',
      'La hawla wa la quwwata illa billah (لا حول ولا قوة إلا بالله)',
      'Hasbiyallah wa ni\'mal wakeel (حسبي الله ونعم الوكيل)',
      'Ya Allah (يا الله)',
      'Rabbighfirli (رب اغفر لي)',
    ];
  }
}