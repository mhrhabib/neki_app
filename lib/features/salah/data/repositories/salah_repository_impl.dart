import '../../../../core/services/firestore_service.dart';
import '../../domain/entities/salah_entity.dart';
import '../../domain/repositories/salah_repository.dart';
import '../models/salah_model.dart';

class SalahRepositoryImpl implements SalahRepository {
  final FirestoreService _firestoreService;
  static const String _collectionPath = 'users_salahs';

  SalahRepositoryImpl(this._firestoreService);

  @override
  Future<List<SalahEntity>> getTodaysSalahs(String userId) async {
    final now = DateTime.now();
    // Shift logical day by 4 hours backwards.
    // So 3:00 AM Tuesday is treated as Monday for Salah tracking purposes.
    final logicalNow = now.subtract(const Duration(hours: 4));
    final todayStr = DateTime(
      logicalNow.year,
      logicalNow.month,
      logicalNow.day,
    ).toIso8601String().split('T')[0];

    // Fetch all salahs for the user and filter in memory to avoid needing a composite index
    final snapshot = await _firestoreService.getCollection(
      collectionPath: _collectionPath,
      queryBuilder: (query) => query.where('userId', isEqualTo: userId),
    );

    final List<SalahEntity> allUserSalahs = snapshot.docs
        .map((doc) => SalahModel.fromJson(doc.data()))
        .toList();

    final todaysSalahs = allUserSalahs.where((salah) {
      final logicalSalahTime = salah.timestamp.subtract(
        const Duration(hours: 4),
      );
      final salahDateStr = logicalSalahTime.toIso8601String().split('T')[0];
      return salahDateStr == todayStr;
    }).toList();

    if (todaysSalahs.isEmpty) {
      return _createDefaultSalahs(userId);
    }

    return todaysSalahs;
  }

  @override
  Future<SalahEntity> markSalahComplete({
    required String userId,
    required String salahName,
  }) async {
    final now = DateTime.now();
    final logicalNow = now.subtract(const Duration(hours: 4));
    final dateKey =
        '${logicalNow.year}-${logicalNow.month.toString().padLeft(2, '0')}-${logicalNow.day.toString().padLeft(2, '0')}';

    final id = 'salah_${userId}_${salahName}_$dateKey';
    final salah = SalahModel(
      id: id,
      userId: userId,
      salahName: salahName,
      timestamp: DateTime.now(),
      isCompleted: true,
      pointsEarned: 100,
    );

    await _firestoreService.setDocument(
      collectionPath: _collectionPath,
      documentId: id,
      data: salah.toJson(),
    );

    return salah;
  }

  @override
  Future<List<SalahEntity>> getSalahHistory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _firestoreService.getCollection(
      collectionPath: _collectionPath,
      queryBuilder: (query) => query.where('userId', isEqualTo: userId),
    );

    return snapshot.docs
        .map((doc) => SalahModel.fromJson(doc.data()))
        .where(
          (salah) =>
              salah.timestamp.isAfter(startDate) &&
              salah.timestamp.isBefore(endDate),
        )
        .toList();
  }

  List<SalahEntity> _createDefaultSalahs(String userId) {
    final names = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    return names
        .map(
          (name) => SalahModel(
            id: 'salah_${name}_${DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            salahName: name,
            timestamp: DateTime.now(),
            isCompleted: false,
            pointsEarned: 0,
          ),
        )
        .toList();
  }
}
