import '../entities/zakat_entity.dart';

abstract class ZakatRepository {
  Future<ZakatEntity> donateZakat({
    required String userId,
    required double amount,
    required String recipient,
    String? notes,
  });
  Future<List<ZakatEntity>> getZakatHistory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<double> getTotalZakatDonated(String userId);
}
