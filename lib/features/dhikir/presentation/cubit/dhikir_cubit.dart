import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/dhikir_repository.dart';
import '../../../points/domain/repositories/points_repository.dart';

part 'dhikir_state.dart';

class DhikirCubit extends Cubit<DhikirState> {
  final DhikirRepository dhikirRepository;
  final PointsRepository pointsRepository;

  DhikirCubit({
    required this.dhikirRepository,
    required this.pointsRepository,
  }) : super(DhikirInitial());

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

      emit(DhikirSessionActive(
        sessionId: session.id,
        dhikirText: session.dhikirText,
        targetCount: session.targetCount,
        currentCount: session.currentCount,
        pointsEarned: session.pointsEarned,
        isCompleted: session.isCompleted,
      ));
    } catch (e) {
      emit(DhikirError(message: e.toString()));
    }
  }

  Future<void> incrementCount(String userId, String sessionId) async {
    try {
      // Optimistic update: if we have an active session in state, update it immediately
      if (state is DhikirSessionActive) {
        final current = state as DhikirSessionActive;
        if (current.sessionId == sessionId) {
          final optimisticCount = current.currentCount + 1;
          final optimisticCompleted = optimisticCount >= current.targetCount;
          // Keep pointsEarned unchanged until confirmed by backend
          emit(DhikirSessionActive(
            sessionId: current.sessionId,
            dhikirText: current.dhikirText,
            targetCount: current.targetCount,
            currentCount: optimisticCount,
            pointsEarned: current.pointsEarned,
            isCompleted: optimisticCompleted,
          ));
        }
      }

      // Persist increment (may be network-backed); update state from response
      final session = await dhikirRepository.incrementDhikirCount(sessionId);

      if (session.isCompleted && session.pointsEarned > 0) {
        // Award points when session is completed
        await pointsRepository.addPoints(
          userId: userId,
          points: session.pointsEarned,
          source: 'dhikir_${session.dhikirText.replaceAll(' ', '_').toLowerCase()}',
        );

        emit(DhikirSessionCompleted(
          sessionId: session.id,
          dhikirText: session.dhikirText,
          targetCount: session.targetCount,
          currentCount: session.currentCount,
          pointsEarned: session.pointsEarned,
          isCompleted: session.isCompleted,
        ));
      } else {
        emit(DhikirSessionActive(
          sessionId: session.id,
          dhikirText: session.dhikirText,
          targetCount: session.targetCount,
          currentCount: session.currentCount,
          pointsEarned: session.pointsEarned,
          isCompleted: session.isCompleted,
        ));
      }
    } catch (e) {
      // On failure, try to surface an error and (optionally) refresh session
      debugPrint('❌ [DhikirCubit] incrementCount failed: $e');
      emit(DhikirError(message: e.toString()));
    }
  }

  Future<void> loadCurrentSession(String userId) async {
    try {
      emit(DhikirLoading());
      final session = await dhikirRepository.getCurrentSession(userId);

      emit(DhikirSessionActive(
        sessionId: session.id,
        dhikirText: session.dhikirText,
        targetCount: session.targetCount,
        currentCount: session.currentCount,
        pointsEarned: session.pointsEarned,
        isCompleted: session.isCompleted,
      ));
    } catch (e) {
      // No active session found, stay in initial state
      emit(DhikirInitial());
    }
  }

  Future<void> loadDhikirHistory(String userId, {DateTime? date}) async {
    try {
      emit(DhikirLoading());
      final sessions = await dhikirRepository.getDhikirHistory(userId, date: date);

      final sessionMaps = sessions.map((session) => {
        'id': session.id,
        'dhikirText': session.dhikirText,
        'targetCount': session.targetCount,
        'currentCount': session.currentCount,
        'pointsEarned': session.pointsEarned,
        'date': session.date,
        'isCompleted': session.isCompleted,
      }).toList();

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
}