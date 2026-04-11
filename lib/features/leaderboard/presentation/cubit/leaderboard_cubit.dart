import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/leaderboard_entry_entity.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

part 'leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final LeaderboardRepository _leaderboardRepository;
  final AuthRepository _authRepository;

  LeaderboardCubit({
    required LeaderboardRepository leaderboardRepository,
    required AuthRepository authRepository,
  })  : _leaderboardRepository = leaderboardRepository,
        _authRepository = authRepository,
        super(LeaderboardInitial());

  /// Returns 2-letter ISO country code from device locale, e.g. 'BD', 'US'.
  String _deviceCountryCode() {
    try {
      final code = PlatformDispatcher.instance.locale.countryCode;
      if (code != null && code.length == 2) return code.toUpperCase();
    } catch (_) {}
    try {
      final locale = Platform.localeName.split('.').first;
      final parts = locale.split(RegExp(r'[_\-]'));
      if (parts.length >= 2) {
        final candidate = parts.last.toUpperCase();
        if (candidate.length == 2) return candidate;
      }
    } catch (_) {}
    return '';
  }

  Future<void> load() async {
    emit(LeaderboardLoading());
    try {
      final currentUser = await _authRepository.getCurrentUser();
      final currentUserId = currentUser?.id ?? '';

      // Get user's rank first to determine their country
      LeaderboardEntryEntity? userRank;
      if (currentUserId.isNotEmpty) {
        userRank = await _leaderboardRepository.getUserRank(currentUserId);
      }

      // Use Firestore country if available, otherwise fall back to device locale
      final userCountry = (userRank?.country?.isNotEmpty == true)
          ? userRank!.country!
          : _deviceCountryCode();

      // Load global + country leaderboards in parallel
      final results = await Future.wait<List<LeaderboardEntryEntity>>([
        _leaderboardRepository.getGlobalLeaderboard(limit: 50),
        userCountry.isNotEmpty
            ? _leaderboardRepository.getCountryLeaderboard(
                country: userCountry,
                limit: 50,
              )
            : Future.value(<LeaderboardEntryEntity>[]),
      ]);

      emit(LeaderboardLoaded(
        globalEntries: results[0],
        countryEntries: results[1],
        currentUserId: currentUserId,
        currentUserRank: userRank,
        userCountry: userCountry.isNotEmpty ? userCountry : null,
      ));
    } catch (e, stackTrace) {
      debugPrint('❌ [LeaderboardCubit] $e\n$stackTrace');
      emit(LeaderboardError('Failed to load leaderboard. Please try again.'));
    }
  }

  void clear() {
    emit(LeaderboardInitial());
  }
}
