import 'package:flutter_bloc/flutter_bloc.dart';
import 'zakat_state.dart';
import '../../../points/domain/repositories/points_repository.dart';

class ZakatCubit extends Cubit<ZakatState> {
  final PointsRepository _pointsRepository;

  ZakatCubit(this._pointsRepository) : super(ZakatInitial());

  void initCalculator() {
    emit(
      const ZakatCalculating(
        goldValue: 0,
        silverValue: 0,
        cashValue: 0,
        investmentValue: 0,
        otherAssetsValue: 0,
        debtsValue: 0,
        zakatAmount: 0,
        totalAssets: 0,
        netAssets: 0,
        nisabThreshold: 1500, // Default Silver Nisab (~612g silver)
        isEligible: false,
      ),
    );
  }

  void updateGold(double value) => _calculate(goldValue: value);
  void updateSilver(double value) => _calculate(silverValue: value);
  void updateCash(double value) => _calculate(cashValue: value);
  void updateInvestment(double value) => _calculate(investmentValue: value);
  void updateOtherAssets(double value) => _calculate(otherAssetsValue: value);
  void updateDebts(double value) => _calculate(debtsValue: value);
  void updateNisab(double value) => _calculate(nisabThreshold: value);

  void _calculate({
    double? goldValue,
    double? silverValue,
    double? cashValue,
    double? investmentValue,
    double? otherAssetsValue,
    double? debtsValue,
    double? nisabThreshold,
  }) {
    if (state is! ZakatCalculating) return;

    final s = state as ZakatCalculating;

    final currentGold = goldValue ?? s.goldValue;
    final currentSilver = silverValue ?? s.silverValue;
    final currentCash = cashValue ?? s.cashValue;
    final currentInvestment = investmentValue ?? s.investmentValue;
    final currentOther = otherAssetsValue ?? s.otherAssetsValue;
    final currentDebts = debtsValue ?? s.debtsValue;
    final currentNisab = nisabThreshold ?? s.nisabThreshold;

    final totalAssets =
        currentGold +
        currentSilver +
        currentCash +
        currentInvestment +
        currentOther;
    final netAssets = totalAssets - currentDebts;

    final isEligible = netAssets >= currentNisab;
    // Zakat is 2.5% of net assets if eligible
    final zakatAmount = isEligible ? netAssets * 0.025 : 0.0;

    emit(
      s.copyWith(
        goldValue: currentGold,
        silverValue: currentSilver,
        cashValue: currentCash,
        investmentValue: currentInvestment,
        otherAssetsValue: currentOther,
        debtsValue: currentDebts,
        totalAssets: totalAssets,
        netAssets: netAssets,
        zakatAmount: zakatAmount,
        nisabThreshold: currentNisab,
        isEligible: isEligible,
      ),
    );
  }

  Future<void> submitZakat(String userId, double amount) async {
    try {
      if (amount <= 0) return;

      // Reward user with Neki points for paying Zakat (e.g., 100 points)
      await _pointsRepository.addPoints(
        userId: userId,
        points: 100,
        source: 'Paid Zakat',
      );

      emit(
        const ZakatSuccess(
          "Alhamdulillah! You've earned 100 Neki points for your Zakat.",
        ),
      );
      // Reset after success
      Future.delayed(const Duration(seconds: 2), () => initCalculator());
    } catch (e) {
      emit(ZakatError(e.toString()));
    }
  }
}
