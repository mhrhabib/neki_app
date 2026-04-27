import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/roza_repository.dart';
import '../../../points/domain/repositories/points_repository.dart';

part 'roza_state.dart';

class RozaCubit extends Cubit<RozaState> {
  final RozaRepository rozaRepository;
  final PointsRepository pointsRepository;

  static const int _pointsPerFast = 100;

  RozaCubit({required this.rozaRepository, required this.pointsRepository}) : super(RozaInitial());

  Future<void> loadMonthlyRozaData(String userId, int year, int month) async {
    if (userId.isEmpty) return;
    try {
      emit(RozaLoading());

      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final rozaRecords = await rozaRepository.getRozaHistory(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      final selectedDates = rozaRecords
          .where((r) => r.isFasted)
          .map((r) => _dateOnly(r.date))
          .toList();

      final currentMonthFastCount = await rozaRepository.getCurrentMonthFastCount(userId);

      emit(
        RozaLoaded(
          selectedDates: selectedDates,
          brokenFastDates: _computeBrokenFastDates(selectedDates),
          currentMonthFastCount: currentMonthFastCount,
        ),
      );
    } catch (e) {
      emit(RozaError(message: e.toString()));
    }
  }

  Future<void> toggleDateSelection({
    required String userId,
    required DateTime date,
    required List<DateTime> currentlySelectedDates,
    String? notes,
  }) async {
    final current = state;
    if (current is! RozaLoaded) return;

    final target = _dateOnly(date);
    final isSelected = current.selectedDates.any((d) => _sameDay(d, target));

    // Optimistic update — keep the user's tap feeling instant.
    final updated = List<DateTime>.from(current.selectedDates);
    if (isSelected) {
      updated.removeWhere((d) => _sameDay(d, target));
    } else {
      updated.add(target);
    }
    emit(
      RozaLoaded(
        selectedDates: updated,
        brokenFastDates: _computeBrokenFastDates(updated),
        currentMonthFastCount: updated.where((d) => _isSameMonth(d, DateTime.now())).length,
      ),
    );

    try {
      if (isSelected) {
        await rozaRepository.unmarkFasted(userId: userId, date: target);
        await pointsRepository.addPoints(
          userId: userId,
          points: -_pointsPerFast,
          source: 'roza_unfasted',
        );
      } else {
        await rozaRepository.markFasted(userId: userId, date: target, notes: notes);
        await pointsRepository.addPoints(
          userId: userId,
          points: _pointsPerFast,
          source: 'roza_fasting',
        );
      }
    } catch (e) {
      debugPrint('❌ [RozaCubit] toggleDateSelection failed: $e');
      // Revert to the server state on failure.
      final now = DateTime.now();
      await loadMonthlyRozaData(userId, now.year, now.month);
    }
  }

  void clear() {
    emit(RozaInitial());
  }

  // Broken-fast days are derived client-side: any day in the gap between two
  // selected days within the same month. Persisting these to Firestore on
  // every tap was the source of the slowness.
  List<DateTime> _computeBrokenFastDates(List<DateTime> fasted) {
    if (fasted.length < 2) return const [];
    final sorted = fasted.map(_dateOnly).toList()..sort((a, b) => a.compareTo(b));
    final result = <DateTime>[];
    for (int i = 0; i < sorted.length - 1; i++) {
      final gap = sorted[i + 1].difference(sorted[i]).inDays;
      for (int j = 1; j < gap; j++) {
        result.add(sorted[i].add(Duration(days: j)));
      }
    }
    return result;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
