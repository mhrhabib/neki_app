import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/leaderboard_entry_entity.dart';
import '../../domain/repositories/leaderboard_repository.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final FirestoreService _firestore;

  LeaderboardRepositoryImpl(this._firestore);

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

      // Fetch all user profiles in parallel
      final userFutures = snapshot.docs.map(
        (doc) => _firestore.getDocument(
          collectionPath: 'users',
          documentId: doc.id,
        ),
      );
      final userDocs = await Future.wait(userFutures);

      final entries = <LeaderboardEntryEntity>[];
      for (int i = 0; i < snapshot.docs.length; i++) {
        final pointsData = snapshot.docs[i].data();
        final userData = userDocs[i]?.data();

        final totalPoints = (pointsData['totalPoints'] as num?)?.toInt() ?? 0;
        if (totalPoints <= 0) continue;

        entries.add(LeaderboardEntryEntity(
          rank: entries.length + 1,
          userId: snapshot.docs[i].id,
          userName: userData?['name'] ?? 'Anonymous',
          photoUrl: userData?['photoUrl'],
          totalPoints: totalPoints,
          country: userData?['country'],
        ));
      }
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
    // Country field not yet stored in Firestore — return empty for now
    return [];
  }

  @override
  Future<LeaderboardEntryEntity?> getUserRank(String userId) async {
    try {
      final userPoints = await _firestore.getDocument(
        collectionPath: 'users_points',
        documentId: userId,
      );
      if (userPoints == null || !userPoints.exists) return null;

      final myPoints = (userPoints.data()?['totalPoints'] as num?)?.toInt() ?? 0;

      // Count users with more points to determine rank
      final above = await _firestore.getCollection(
        collectionPath: 'users_points',
        queryBuilder: (q) =>
            q.where('totalPoints', isGreaterThan: myPoints),
      );

      final rank = above.docs.length + 1;

      final userDoc = await _firestore.getDocument(
        collectionPath: 'users',
        documentId: userId,
      );

      return LeaderboardEntryEntity(
        rank: rank,
        userId: userId,
        userName: userDoc?.data()?['name'] ?? 'You',
        photoUrl: userDoc?.data()?['photoUrl'],
        totalPoints: myPoints,
        country: userDoc?.data()?['country'],
      );
    } catch (e) {
      return null;
    }
  }
}
