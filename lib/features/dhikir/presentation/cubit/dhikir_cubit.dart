import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/dhikir_repository.dart';
import '../../../points/domain/repositories/points_repository.dart';

part 'dhikir_state.dart';

class DhikirCubit extends Cubit<DhikirState> {
  final DhikirRepository dhikirRepository;
  final PointsRepository pointsRepository;

  /// Tracks how many optimistic increments haven't been confirmed by the server yet.
  int _pendingIncrements = 0;

  DhikirCubit({required this.dhikirRepository, required this.pointsRepository})
    : super(DhikirInitial());

  Future<void> startDhikirSession({
    required String userId,
    required String dhikirText,
    required int targetCount,
  }) async {
    try {
      emit(DhikirLoading());
      final session = await dhikirRepository.startDhikirSession(
        userId: userId,
        dhikirText: dhikirText,
        targetCount: targetCount,
      );

      emit(
        DhikirSessionActive(
          sessionId: session.id,
          dhikirText: session.dhikirText,
          targetCount: session.targetCount,
          currentCount: session.currentCount,
          pointsEarned: session.pointsEarned,
          isCompleted: session.isCompleted,
        ),
      );
    } catch (e) {
      emit(DhikirError(message: e.toString()));
    }
  }

  Future<void> incrementCount(String userId, String sessionId) async {
    try {
      // Optimistic update: immediately show the new count in the UI
      if (state is DhikirSessionActive) {
        final current = state as DhikirSessionActive;
        if (current.sessionId == sessionId) {
          final optimisticCount = current.currentCount + 1;
          final optimisticCompleted = optimisticCount >= current.targetCount;
          emit(
            DhikirSessionActive(
              sessionId: current.sessionId,
              dhikirText: current.dhikirText,
              targetCount: current.targetCount,
              currentCount: optimisticCount,
              pointsEarned: current.pointsEarned,
              isCompleted: optimisticCompleted,
            ),
          );
        }
      }

      // Track that this increment is in-flight
      _pendingIncrements++;

      // Persist increment to the backend
      final session = await dhikirRepository.incrementDhikirCount(sessionId);
      _pendingIncrements--;

      if (session.isCompleted && session.pointsEarned > 0) {
        // Award points when session is completed
        await pointsRepository.addPoints(
          userId: userId,
          points: session.pointsEarned,
          source:
              'dhikir_${session.dhikirText.replaceAll(' ', '_').toLowerCase()}',
        );

        emit(
          DhikirSessionCompleted(
            sessionId: session.id,
            dhikirText: session.dhikirText,
            targetCount: session.targetCount,
            currentCount: session.currentCount,
            pointsEarned: session.pointsEarned,
            isCompleted: session.isCompleted,
          ),
        );
      } else if (_pendingIncrements == 0) {
        // Only emit server state when no more taps are in-flight,
        // otherwise the server count would overwrite the optimistic count.
        emit(
          DhikirSessionActive(
            sessionId: session.id,
            dhikirText: session.dhikirText,
            targetCount: session.targetCount,
            currentCount: session.currentCount,
            pointsEarned: session.pointsEarned,
            isCompleted: session.isCompleted,
          ),
        );
      }
      // If _pendingIncrements > 0, skip emitting — the last in-flight call
      // will reconcile with the final server count.
    } catch (e) {
      _pendingIncrements = (_pendingIncrements - 1).clamp(0, 999);
      debugPrint('❌ [DhikirCubit] incrementCount failed: $e');
      emit(DhikirError(message: e.toString()));
    }
  }

  Future<void> loadCurrentSession(String userId) async {
    try {
      emit(DhikirLoading());
      final session = await dhikirRepository.getCurrentSession(userId);

      emit(
        DhikirSessionActive(
          sessionId: session.id,
          dhikirText: session.dhikirText,
          targetCount: session.targetCount,
          currentCount: session.currentCount,
          pointsEarned: session.pointsEarned,
          isCompleted: session.isCompleted,
        ),
      );
    } catch (e) {
      // No active session found, stay in initial state
      emit(DhikirInitial());
    }
  }

  Future<void> loadDhikirHistory(String userId, {DateTime? date}) async {
    try {
      emit(DhikirLoading());
      final sessions = await dhikirRepository.getDhikirHistory(
        userId,
        date: date,
      );

      final sessionMaps = sessions
          .map(
            (session) => {
              'id': session.id,
              'dhikirText': session.dhikirText,
              'targetCount': session.targetCount,
              'currentCount': session.currentCount,
              'pointsEarned': session.pointsEarned,
              'date': session.date,
              'isCompleted': session.isCompleted,
            },
          )
          .toList();

      emit(DhikirHistoryLoaded(sessions: sessionMaps));
    } catch (e) {
      emit(DhikirError(message: e.toString()));
    }
  }

  Future<void> completeSession(String sessionId) async {
    try {
      await dhikirRepository.completeDhikirSession(sessionId);
      emit(DhikirInitial()); // Reset to initial state
    } catch (e) {
      emit(DhikirError(message: e.toString()));
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await dhikirRepository.deleteDhikirSession(sessionId);
      emit(DhikirInitial()); // Reset to initial state
    } catch (e) {
      emit(DhikirError(message: e.toString()));
    }
  }

  List<String> getDhikirSuggestions() {
    return dhikirRepository.getDhikirSuggestions();
  }

  void clear() {
    emit(DhikirInitial());
  }
}
