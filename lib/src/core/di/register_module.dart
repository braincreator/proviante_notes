import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@module
abstract class RegisterModule {
  @preResolve // Ensures SharedPreferences.getInstance() completes before dependent classes are initialized
  @singleton // Provides a single instance throughout the app
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();
}