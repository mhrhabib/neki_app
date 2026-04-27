import '../entities/roza_entity.dart';

abstract class RozaRepository {
  Future<RozaEntity> markFasted({required String userId, required DateTime date, String? notes});
  Future<void> unmarkFasted({required String userId, required DateTime date});
  Future<List<RozaEntity>> getRozaHistory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<int> getCurrentMonthFastCount(String userId);
}
