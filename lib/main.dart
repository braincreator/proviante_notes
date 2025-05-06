import 'package:easy_localization/easy_localization.dart'; // Import easy_localization
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import flutter_bloc
import 'package:proviante_notes/src/core/theme/bloc/theme_bloc.dart'; // Import ThemeBloc
import 'package:proviante_notes/src/injection.dart'; // Import DI configuration
import 'package:proviante_notes/src/presentation/notes_list/view/notes_list_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:proviante_notes/src/core/utils/snackbar_utils.dart'; // Import global key

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Localization
  await EasyLocalization.ensureInitialized();
  // Initialize Dependency Injection
  await configureDependencies(); // Await the DI setup

  runApp(
    // Wrap with BlocProvider for ThemeBloc
    BlocProvider<ThemeBloc>(
      create: (_) => getIt<ThemeBloc>()..add(LoadTheme()), // Get ThemeBloc from GetIt and load initial theme
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ru')], // Added 'ru'
        path: 'assets/translations', // Path to translation files
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('ru'), // Set Russian as default
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define ColorSchemes
    // Define Vibrant ColorSchemes
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple, // Vibrant seed color for light theme
      brightness: Brightness.light,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.teal, // Vibrant seed color for dark theme
      brightness: Brightness.dark,
    );

    // Wrap MaterialApp with BlocBuilder to listen for theme changes
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          // Localization delegates
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          scaffoldMessengerKey: scaffoldMessengerKey, // Assign the global key

          title: 'Notes App', // This could also be localized later
          theme: ThemeData(
            colorScheme: lightColorScheme,
            useMaterial3: true,
            scaffoldBackgroundColor: lightColorScheme.background, // Match scaffold background
            appBarTheme: AppBarTheme( // Style AppBar
              backgroundColor: lightColorScheme.primary,
              foregroundColor: lightColorScheme.onPrimary,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData(brightness: Brightness.light).textTheme)
                .apply(
                  bodyColor: lightColorScheme.onSurface,
                  displayColor: lightColorScheme.onSurface,
                ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
            scaffoldBackgroundColor: darkColorScheme.background, // Match scaffold background
            appBarTheme: AppBarTheme( // Style AppBar
              backgroundColor: darkColorScheme.primary,
              foregroundColor: darkColorScheme.onPrimary,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData(brightness: Brightness.dark).textTheme)
                .apply(
                  bodyColor: darkColorScheme.onSurface,
                  displayColor: darkColorScheme.onSurface,
                ),
          ),
          themeMode: state.themeMode, // Use themeMode from ThemeBloc state
          home: const NotesListScreen(), // Keep NotesListScreen as home
        );
      },
    );
  }
}
