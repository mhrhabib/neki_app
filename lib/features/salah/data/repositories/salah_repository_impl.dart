import '../../domain/entities/salah_entity.dart';
import '../../domain/repositories/salah_repository.dart';
import '../models/salah_model.dart';

class SalahRepositoryImpl implements SalahRepository {
  final List<SalahEntity> _salahs = [];

  @override
  Future<List<SalahEntity>> getTodaysSalahs(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Return today's salahs or create default ones
    final todaysSalahs = _salahs.where((s) {
      final salahDate = DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day);
      return s.userId == userId && salahDate.isAtSameMomentAs(today);
    }).toList();

    if (todaysSalahs.isEmpty) {
      return _createDefaultSalahs(userId);
    }

    return todaysSalahs;
  }

  @override
  Future<SalahEntity> markSalahComplete({required String userId, required String salahName}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final salah = SalahModel(
      id: 'salah_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      salahName: salahName,
      timestamp: DateTime.now(),
      isCompleted: true,
      pointsEarned: 10,
    );

    _salahs.add(salah);
    return salah;
  }

  @override
  Future<List<SalahEntity>> getSalahHistory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return _salahs
        .where((s) => s.userId == userId && s.timestamp.isAfter(startDate) && s.timestamp.isBefore(endDate))
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
