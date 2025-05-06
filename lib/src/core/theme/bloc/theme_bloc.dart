import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_event.dart';
part 'theme_state.dart';

const String _themePreferenceKey = 'app_theme_mode';

@singleton // Add this annotation
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SharedPreferences _prefs;

  ThemeBloc(this._prefs) // Update constructor to directly assign _prefs
      : super(ThemeState.initial()) {
    on<LoadTheme>(_onLoadTheme);
    on<ToggleTheme>(_onToggleTheme);
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    final themeString = _prefs.getString(_themePreferenceKey);
    final themeMode = _stringToThemeMode(themeString);
    emit(ThemeState(themeMode));
  }

  Future<void> _onToggleTheme(ToggleTheme event, Emitter<ThemeState> emit) async {
    final currentMode = state.themeMode;
    final nextMode = currentMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _prefs.setString(_themePreferenceKey, _themeModeToString(nextMode));
    emit(ThemeState(nextMode));
  }

  // Helper to convert ThemeMode enum to String for storage
  // Helper to convert ThemeMode enum to String for storage
  String _themeModeToString(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  // Helper to convert stored String back to ThemeMode enum
  ThemeMode _stringToThemeMode(String? modeString) => switch (modeString) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.system, // Default if null, not found, or invalid
      };
}