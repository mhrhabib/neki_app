import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/support_repository_impl.dart';
import '../../domain/services/support_trigger_service.dart';

abstract class SupportState {}

class SupportInitial extends SupportState {}

class SupportPromptReady extends SupportState {
  final String title;
  final String message;
  SupportPromptReady(this.title, this.message);
}

class SupportSuccess extends SupportState {
  final double amount;
  SupportSuccess(this.amount);
}

class SupportCubit extends Cubit<SupportState> {
  final SupportRepository _repository;
  final SupportTriggerService _triggerService;
  StreamSubscription? _statusSub;

  SupportCubit(this._repository, this._triggerService)
    : super(SupportInitial()) {
    _statusSub = _repository.supportStatusStream.listen((status) {
      if (status.lastDonationDate != null &&
          DateTime.now().difference(status.lastDonationDate!).inSeconds < 5) {
        emit(SupportSuccess(status.lastDonationAmount));
      }
    });
  }

  Future<void> checkAddictionMilestone(int daysClean) async {
    if (!_triggerService.isAddictionMilestone(daysClean)) return;

    final status = await _repository.getSupportStatus();
    if (_triggerService.shouldAllowPrompt(status)) {
      emit(
        SupportPromptReady(
          'Alhamdulillah! $daysClean Days Clean',
          'You\'ve reached a powerful milestone. If Neki is helping you stay strong, please consider supporting the project to keep it free for everyone.',
        ),
      );
    }
  }

  Future<void> checkSalahMilestone() async {
    await _repository.incrementSalahCount();
    final count = await _repository.getRecordedSalahCount();

    if (!_triggerService.isSalahMilestone(count)) return;

    final status = await _repository.getSupportStatus();
    if (_triggerService.shouldAllowPrompt(status)) {
      emit(
        SupportPromptReady(
          'Consistent in Prayer',
          'You\'ve recorded $count Salah! Your consistency is inspiring. Consider a small donation to help us maintain and grow this app for the community.',
        ),
      );
    }
  }

  Future<void> markDeclined() async {
    final status = await _repository.getSupportStatus();
    await _repository.updateSupportStatus(
      status.copyWith(
        lastDeclineDate: DateTime.now(),
        hasDeclinedRecently: true,
        lastPromptDate: DateTime.now(),
      ),
    );
    emit(SupportInitial());
  }

  Future<void> markMaybeLater() async {
    final status = await _repository.getSupportStatus();
    await _repository.updateSupportStatus(
      status.copyWith(lastPromptDate: DateTime.now()),
    );
    emit(SupportInitial());
  }

  /// Record that the prompt was shown without counting it as accept/decline.
  /// Used when the user proceeds to the IAP flow — we log the prompt so the
  /// rate limit ticks forward, and let the purchase stream handle the rest.
  Future<void> markPromptShown() async {
    final status = await _repository.getSupportStatus();
    await _repository.updateSupportStatus(
      status.copyWith(lastPromptDate: DateTime.now()),
    );
    emit(SupportInitial());
  }

  void reset() => emit(SupportInitial());

  @override
  Future<void> close() {
    _statusSub?.cancel();
    return super.close();
  }
}
