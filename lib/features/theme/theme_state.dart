part of 'theme_cubit.dart';

abstract class ThemeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ThemeInitial extends ThemeState {}

class ThemeLoaded extends ThemeState {
  final bool isDarkMode;

  ThemeLoaded({required this.isDarkMode});

  @override
  List<Object?> get props => [isDarkMode];
}
