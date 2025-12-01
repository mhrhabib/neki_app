import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'theme_repository.dart';

part 'theme_state.dart';

/// Cubit for handling theme switching
class ThemeCubit extends Cubit<ThemeData> {
  final ThemeRepository themeRepository;

  ThemeCubit({required this.themeRepository}) : super(ThemeData.light());

  void loadTheme() async {
    await themeRepository.loadTheme();
    final isDark = themeRepository.getIsDarkMode();
    debugPrint('🎨 Loading Theme: isDark=$isDark');
    emit(isDark ? ThemeData.dark() : ThemeData.light());
  }

  Future<void> toggleTheme() async {
    final currentBrightness = state.brightness;
    final newIsDark = currentBrightness == Brightness.light;

    debugPrint('🎨 Theme Toggle: ${currentBrightness == Brightness.dark} -> $newIsDark');
    await themeRepository.setIsDarkMode(newIsDark);
    emit(newIsDark ? ThemeData.dark() : ThemeData.light());
    debugPrint('🎨 Theme State Emitted: brightness=${state.brightness}');
  }
}
