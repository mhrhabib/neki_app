part of 'theme_cubit.dart';

abstract class ThemeState {}

class ThemeInitial extends ThemeState {}

class ThemeLoaded extends ThemeState {
  final bool isDarkMode;

  ThemeLoaded({required this.isDarkMode});
}
