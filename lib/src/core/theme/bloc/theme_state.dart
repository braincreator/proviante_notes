part of 'theme_bloc.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;

  const ThemeState(this.themeMode);

  factory ThemeState.initial() => const ThemeState(ThemeMode.system); // Default to system theme

  @override
  List<Object> get props => [themeMode];
}