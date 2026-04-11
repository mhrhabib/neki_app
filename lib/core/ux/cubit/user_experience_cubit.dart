import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserExperienceState {
  final bool hasCelebratedFirstWin;
  final bool isFirstWinTriggered; // Transient flag for the UI to catch

  UserExperienceState({
    this.hasCelebratedFirstWin = false,
    this.isFirstWinTriggered = false,
  });

  UserExperienceState copyWith({
    bool? hasCelebratedFirstWin,
    bool? isFirstWinTriggered,
  }) {
    return UserExperienceState(
      hasCelebratedFirstWin: hasCelebratedFirstWin ?? this.hasCelebratedFirstWin,
      isFirstWinTriggered: isFirstWinTriggered ?? this.isFirstWinTriggered,
    );
  }
}

class UserExperienceCubit extends Cubit<UserExperienceState> {
  final SharedPreferences _prefs;
  static const String _kFirstWinKey = 'has_celebrated_first_win';

  UserExperienceCubit(this._prefs) : super(UserExperienceState()) {
    _loadInitial();
  }

  void _loadInitial() {
    final hasCelebrated = _prefs.getBool(_kFirstWinKey) ?? false;
    emit(state.copyWith(hasCelebratedFirstWin: hasCelebrated));
  }

  void triggerFirstWinCelebration() {
    if (state.hasCelebratedFirstWin) return;
    
    emit(state.copyWith(isFirstWinTriggered: true));
    // Reset the transient trigger immediately after emit so it's not re-fired
    Future.delayed(const Duration(milliseconds: 100), () {
      emit(state.copyWith(isFirstWinTriggered: false));
    });
  }

  Future<void> markFirstWinCelebrated() async {
    await _prefs.setBool(_kFirstWinKey, true);
    emit(state.copyWith(hasCelebratedFirstWin: true, isFirstWinTriggered: false));
  }
}
