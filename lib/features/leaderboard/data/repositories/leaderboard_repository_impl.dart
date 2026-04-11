import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/leaderboard_entry_entity.dart';
import '../../domain/repositories/leaderboard_repository.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final FirestoreService _firestore;

  LeaderboardRepositoryImpl(this._firestore);

  LeaderboardEntryEntity _fromDoc(Map<String, dynamic> data, String docId, int rank) {
    final bool isVisible = data['showOnLeaderboard'] ?? true;
    
    return LeaderboardEntryEntity(
      rank: rank,
      userId: docId,
      userName: isVisible && (data['name'] as String?)?.isNotEmpty == true
          ? data['name'] as String
          : 'Anonymous',
      photoUrl: isVisible ? data['photoUrl'] as String? : null,
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
      country: data['country'] as String?,
    );
  }

  @override
  Future<List<LeaderboardEntryEntity>> getGlobalLeaderboard({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore.getCollection(
        collectionPath: 'users_points',
        queryBuilder: (q) =>
            q.orderBy('totalPoints', descending: true).limit(limit),
      );

      if (snapshot.docs.isEmpty) return [];

      final entries = <LeaderboardEntryEntity>[];
      for (final doc in snapshot.docs) {
        entries.add(_fromDoc(doc.data(), doc.id, entries.length + 1));
      }
      print('Fetched ${entries.length} global leaderboard entries');
      print('Leaderboard entries: ${entries.map((e) => e.userName).toList()}');
      return entries;
    } catch (e) {
      throw Exception('Failed to load leaderboard: $e');
    }
  }

  @override
  Future<List<LeaderboardEntryEntity>> getCountryLeaderboard({
    required String country,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore.getCollection(
        collectionPath: 'users_points',
        queryBuilder: (q) => q
            .where('country', isEqualTo: country)
            .orderBy('totalPoints', descending: true)
            .limit(limit),
      );

      if (snapshot.docs.isEmpty) return [];

      final entries = <LeaderboardEntryEntity>[];
      for (final doc in snapshot.docs) {
        entries.add(_fromDoc(doc.data(), doc.id, entries.length + 1));
      }
      return entries;
    } catch (e) {
      throw Exception('Failed to load country leaderboard: $e');
    }
  }

  @override
  Future<LeaderboardEntryEntity?> getUserRank(String userId) async {
    try {
      final userPoints = await _firestore.getDocument(
        collectionPath: 'users_points',
        documentId: userId,
      );
      if (userPoints == null || !userPoints.exists) return null;

      final data = userPoints.data()!;
      final myPoints = (data['totalPoints'] as num?)?.toInt() ?? 0;

      // Count users with more points to determine rank
      final above = await _firestore.getCollection(
        collectionPath: 'users_points',
        queryBuilder: (q) => q.where('totalPoints', isGreaterThan: myPoints),
      );

      return _fromDoc(data, userId, above.docs.length + 1);
    } catch (e) {
      return null;
    }
  }
}
