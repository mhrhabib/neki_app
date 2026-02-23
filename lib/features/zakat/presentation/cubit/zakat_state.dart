import 'package:equatable/equatable.dart';

abstract class ZakatState extends Equatable {
  const ZakatState();

  @override
  List<Object?> get props => [];
}

class ZakatInitial extends ZakatState {}

class ZakatCalculating extends ZakatState {
  final double goldValue;
  final double silverValue;
  final double cashValue;
  final double investmentValue;
  final double otherAssetsValue;
  final double debtsValue;
  final double zakatAmount;
  final double totalAssets;
  final double netAssets;
  final double nisabThreshold;
  final bool isEligible;

  const ZakatCalculating({
    required this.goldValue,
    required this.silverValue,
    required this.cashValue,
    required this.investmentValue,
    required this.otherAssetsValue,
    required this.debtsValue,
    required this.zakatAmount,
    required this.totalAssets,
    required this.netAssets,
    required this.nisabThreshold,
    required this.isEligible,
  });

  @override
  List<Object?> get props => [
    goldValue,
    silverValue,
    cashValue,
    investmentValue,
    otherAssetsValue,
    debtsValue,
    zakatAmount,
    totalAssets,
    netAssets,
    nisabThreshold,
    isEligible,
  ];

  ZakatCalculating copyWith({
    double? goldValue,
    double? silverValue,
    double? cashValue,
    double? investmentValue,
    double? otherAssetsValue,
    double? debtsValue,
    double? zakatAmount,
    double? totalAssets,
    double? netAssets,
    double? nisabThreshold,
    bool? isEligible,
  }) {
    return ZakatCalculating(
      goldValue: goldValue ?? this.goldValue,
      silverValue: silverValue ?? this.silverValue,
      cashValue: cashValue ?? this.cashValue,
      investmentValue: investmentValue ?? this.investmentValue,
      otherAssetsValue: otherAssetsValue ?? this.otherAssetsValue,
      debtsValue: debtsValue ?? this.debtsValue,
      zakatAmount: zakatAmount ?? this.zakatAmount,
      totalAssets: totalAssets ?? this.totalAssets,
      netAssets: netAssets ?? this.netAssets,
      nisabThreshold: nisabThreshold ?? this.nisabThreshold,
      isEligible: isEligible ?? this.isEligible,
    );
  }
}

class ZakatSuccess extends ZakatState {
  final String message;
  const ZakatSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ZakatError extends ZakatState {
  final String message;
  const ZakatError(this.message);

  @override
  List<Object?> get props => [message];
}
