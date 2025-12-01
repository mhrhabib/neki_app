import '../entities/good_deed_entity.dart';

abstract class GoodDeedsRepository {
  Future<GoodDeedEntity> logDeed({
    required String userId,
    required String title,
    required String description,
    String? category,
  });
  Future<List<GoodDeedEntity>> getDeedHistory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<List<GoodDeedEntity>> getRecentDeeds(String userId, {int limit = 10});
}
