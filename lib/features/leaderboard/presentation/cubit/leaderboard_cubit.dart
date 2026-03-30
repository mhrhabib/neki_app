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

  Future<void> load() async {
    emit(LeaderboardLoading());
    try {
      final currentUser = await _authRepository.getCurrentUser();
      final currentUserId = currentUser?.id ?? '';

      final results = await Future.wait([
        _leaderboardRepository.getGlobalLeaderboard(limit: 50),
        if (currentUserId.isNotEmpty)
          _leaderboardRepository.getUserRank(currentUserId)
        else
          Future.value(null),
      ]);

      final globalEntries = results[0] as List<LeaderboardEntryEntity>;
      final userRank = results.length > 1 ? results[1] as LeaderboardEntryEntity? : null;

      emit(LeaderboardLoaded(
        globalEntries: globalEntries,
        currentUserId: currentUserId,
        currentUserRank: userRank,
      ));
    } catch (e) {
      emit(LeaderboardError('Failed to load leaderboard. Please try again.'));
    }
  }
}
