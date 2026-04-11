import '../entities/dhikir_entity.dart';

abstract class DhikirRepository {
  Future<DhikirEntity> startDhikirSession({
    required String userId,
    required String dhikirText,
    required int targetCount,
  });

  Future<DhikirEntity> incrementDhikirCount(String sessionId);
  Future<DhikirEntity> getCurrentSession(String userId);
  Future<List<DhikirEntity>> getDhikirHistory(String userId, {DateTime? date});
  Future<void> completeDhikirSession(String sessionId);
  Future<void> deleteDhikirSession(String sessionId);

  // Predefined Dhikir suggestions
  List<String> getDhikirSuggestions();
}