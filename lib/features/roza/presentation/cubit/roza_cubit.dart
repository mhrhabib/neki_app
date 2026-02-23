import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/roza_repository.dart';
import '../../../points/domain/repositories/points_repository.dart';

part 'roza_state.dart';

class RozaCubit extends Cubit<RozaState> {
  final RozaRepository rozaRepository;
  final PointsRepository pointsRepository;

  RozaCubit({required this.rozaRepository, required this.pointsRepository}) : super(RozaInitial());

  Future<void> loadMonthlyRozaData(String userId, int year, int month) async {
    try {
      emit(RozaLoading());

      // Get Roza records for the month
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final rozaRecords = await rozaRepository.getRozaHistory(userId: userId, startDate: startDate, endDate: endDate);

      // Separate fasted and broken fast dates
      final selectedDates = rozaRecords.where((record) => record.isFasted).map((record) => record.date).toList();

      final brokenFastDates = rozaRecords.where((record) => !record.isFasted).map((record) => record.date).toList();

      final currentMonthFastCount = await rozaRepository.getCurrentMonthFastCount(userId);

      emit(
        RozaLoaded(
          selectedDates: selectedDates,
          brokenFastDates: brokenFastDates,
          currentMonthFastCount: currentMonthFastCount,
        ),
      );
    } catch (e) {
      emit(RozaError(message: e.toString()));
    }
  }

  Future<void> markDatesAsFasted({required String userId, required List<DateTime> dates, String? notes}) async {
    try {
      emit(RozaLoading());

      // Mark dates as fasted in repository
      await rozaRepository.markMultipleDatesFasted(userId: userId, dates: dates, notes: notes);

      // Add points for each fasted date (100 points per date)
      final totalPoints = dates.length * 100;
      await pointsRepository.addPoints(userId: userId, points: totalPoints, source: 'roza_fasting');

      // Reload the monthly data
      final now = DateTime.now();
      await loadMonthlyRozaData(userId, now.year, now.month);
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
    try {
      emit(RozaLoading());

      final updatedDates = List<DateTime>.from(currentlySelectedDates);

      // Check if date is already selected
      final isSelected = updatedDates.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);

      if (isSelected) {
        // Remove the date
        updatedDates.removeWhere((d) => d.year == date.year && d.month == date.month && d.day == date.day);
      } else {
        // Add the date
        updatedDates.add(date);
      }

      // If we have dates selected, mark them as fasted
      if (updatedDates.isNotEmpty) {
        await markDatesAsFasted(userId: userId, dates: updatedDates, notes: notes);
      } else {
        // If no dates selected, just reload current month data
        final now = DateTime.now();
        await loadMonthlyRozaData(userId, now.year, now.month);
      }
    } catch (e) {
      emit(RozaError(message: e.toString()));
    }
  }
}
