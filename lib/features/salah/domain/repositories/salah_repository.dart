import '../entities/salah_entity.dart';

abstract class SalahRepository {
  Future<List<SalahEntity>> getTodaysSalahs(String userId);
  Future<SalahEntity> markSalahComplete({required String userId, required String salahName});
  Future<List<SalahEntity>> getSalahHistory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
