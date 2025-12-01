import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_repository.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final ThemeRepository themeRepository;

  ThemeCubit({required this.themeRepository}) : super(ThemeInitial());

  void loadTheme() {
    final isDark = themeRepository.getIsDarkMode();
    emit(ThemeLoaded(isDarkMode: isDark));
  }

  void toggleTheme() async {
    if (state is ThemeLoaded) {
      final current = (state as ThemeLoaded).isDarkMode;
      await themeRepository.setIsDarkMode(!current);
      emit(ThemeLoaded(isDarkMode: !current));
    }
  }
}
