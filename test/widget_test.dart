import 'package:easy_localization/easy_localization.dart'; // Import localization
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proviante_notes/main.dart';
import 'package:proviante_notes/src/domain/entities/note.dart'; // Import Note for when() setup if needed later
import 'package:proviante_notes/src/domain/repositories/note_repository.dart';
import 'package:proviante_notes/src/injection.dart'; // Import getIt instance
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:golden_toolkit/golden_toolkit.dart'; // Import golden_toolkit

// Import the generated mocks file
import 'widget_test.mocks.dart';
import 'dart:async'; // For StreamController
import 'package:proviante_notes/src/domain/entities/note_sort_option.dart'; // Import sort option

// Annotate to generate mock for NoteRepository
@GenerateMocks([NoteRepository])
void main() {
  // Ensure localization is initialized for tests
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Minimal setup for EasyLocalization for testing
    EasyLocalization.logger.enableBuildModes = []; // Disable logs
    await EasyLocalization.ensureInitialized();

    // It's often good practice to reset GetIt in setUpAll as well,
    // especially if tests might run in parallel or affect global state.
    getIt.reset();
  });

  // Reset GetIt before each test to ensure isolation
  setUp(() {
    getIt.reset();
  });

  // Use testGoldens for golden tests
  testGoldens('NotesListScreen initial empty state matches golden file', (WidgetTester tester) async {
    // --- Arrange ---
    final mockRepository = MockNoteRepository();
    final notesStreamController = StreamController<List<Note>>.broadcast();

    // Ensure GetIt is reset and mock is registered (redundant if setUp does it, but safe)
    // await getIt.reset(); // Assuming setUp handles this
    getIt.registerSingleton<NoteRepository>(mockRepository);

    // Mock watchAllNotes to return the stream
    when(mockRepository.watchAllNotes(
      sortOption: anyNamed('sortOption'),
      searchQuery: anyNamed('searchQuery'),
    )).thenAnswer((_) => notesStreamController.stream);

    // --- Act ---
    // Build the app
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const MyApp(),
      ),
    );

    // Add initial empty list to the stream *after* the widget is built
    notesStreamController.add([]);
    // Wait for the stream emission and UI update
    await tester.pumpAndSettle();

    // --- Assert ---
    // Verify that the AppBar title is 'Notes'.
    // Note: The title comes from translation 'notesList.title'
    expect(find.text('notesList.title'.tr()), findsOneWidget);

    // Verify the FloatingActionButton is present (only on narrow screens)
    // This test runs with default screen size, likely narrow.
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget); // Updated icon

    // Verify that the initial state (empty list) shows the localized text
    // Use the key from en.json and .tr()
    // Note: The key is nested 'notesList.empty.title'
    expect(find.text('notesList.empty.title'.tr()), findsOneWidget);
    expect(find.text('notesList.empty.message'.tr()), findsOneWidget);

    // --- Golden Test Assertion ---
    // Ensure fonts are loaded for golden tests
    await loadAppFonts();
    // Compare the screen with the golden file
    await screenMatchesGolden(tester, 'notes_list_screen_empty');

    // Clean up stream controller
    await notesStreamController.close();

    // --- Assert ---
    // Verify that the AppBar title is 'Notes'.
    // Using the actual text for now, could use localization key if title is localized.
    expect(find.text('Notes'), findsOneWidget);

    // Verify the FloatingActionButton is present
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Verify that the initial state (empty list) shows the localized text
    // Use the key from en.json and .tr()
    expect(find.text('notes_list_empty'.tr()), findsOneWidget);

    // --- Golden Test Assertion ---
    // Ensure fonts are loaded for golden tests
    await loadAppFonts();
    // Compare the screen with the golden file
    await screenMatchesGolden(tester, 'notes_list_screen_empty');
  });

  testGoldens('NotesListScreen loaded state matches golden file', (WidgetTester tester) async {
    // --- Arrange ---
    final mockRepository = MockNoteRepository();
    final notesStreamController = StreamController<List<Note>>.broadcast();
    // await getIt.reset(); // Assuming setUp handles this
    getIt.registerSingleton<NoteRepository>(mockRepository);

    // Mock watchAllNotes
    when(mockRepository.watchAllNotes(
      sortOption: anyNamed('sortOption'),
      searchQuery: anyNamed('searchQuery'),
    )).thenAnswer((_) => notesStreamController.stream);

    // Define test notes
    final testNotes = [
      Note.create(title: 'Test Note 1', text: 'This is the first test note.', createdAt: DateTime(2023, 10, 26, 10, 0), updatedAt: DateTime(2023, 10, 26, 10, 0)),
      Note.create(title: 'Test Note 2', text: 'This is a second note with longer text.', createdAt: DateTime(2023, 10, 25, 15, 30), updatedAt: DateTime(2023, 10, 25, 15, 30)),
    ];
    testNotes[0].id = 1;
    testNotes[1].id = 2;

    // --- Act ---
    // Build the app
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const MyApp(),
      ),
    );

    // Add notes to the stream
    notesStreamController.add(testNotes);
    await tester.pumpAndSettle(); // Wait for notes to load

    // --- Assert ---
    expect(find.text('Test Note 1'), findsOneWidget);
    expect(find.text('Test Note 2'), findsOneWidget);
    expect(find.textContaining('This is the first test note.'), findsOneWidget); // Check snippet/subtitle

    // --- Golden Test Assertion ---
    await loadAppFonts();
    await screenMatchesGolden(tester, 'notes_list_screen_loaded');

    // Clean up stream controller
    await notesStreamController.close();

    // --- Assert ---
    expect(find.text('Test Note 1'), findsOneWidget);
    expect(find.text('Test Note 2'), findsOneWidget);
    expect(find.textContaining('This is the first test note.'), findsOneWidget); // Check snippet/subtitle

    // --- Golden Test Assertion ---
    await loadAppFonts();
    await screenMatchesGolden(tester, 'notes_list_screen_loaded');
  });

  testWidgets('NotesListScreen allows deleting and undoing deletion', (WidgetTester tester) async {
    // --- Arrange ---
    final mockRepository = MockNoteRepository();
    final notesStreamController = StreamController<List<Note>>.broadcast();
    // await getIt.reset(); // Assuming setUp handles this
    getIt.registerSingleton<NoteRepository>(mockRepository);

    // Mock watchAllNotes
    when(mockRepository.watchAllNotes(
      sortOption: anyNamed('sortOption'),
      searchQuery: anyNamed('searchQuery'),
    )).thenAnswer((_) => notesStreamController.stream);

    // Mock deletion and addition for undo
    when(mockRepository.deleteNote(any)).thenAnswer((_) async {});
    when(mockRepository.addNote(any)).thenAnswer((_) async {});

    // Define the note to be deleted
    final testNote = Note.create(title: 'Note to Delete', text: 'Some text', createdAt: DateTime.now(), updatedAt: DateTime.now());
    testNote.id = 1; // Assign ID

    // --- Act ---
    // Build the app
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const MyApp(),
      ),
    );

    // Add the initial note to the stream
    notesStreamController.add([testNote]);
    await tester.pumpAndSettle();

    // Verify note is present initially
    expect(find.text('Note to Delete'), findsOneWidget);

    // Simulate swipe to delete
    await tester.drag(find.byType(Dismissible), const Offset(-500.0, 0.0));
    // IMPORTANT: After dragging, the Bloc optimistically removes the note.
    // The stream *might* update later, but we test the immediate state first.
    await tester.pump(); // Pump once for optimistic removal

    // --- Assert Deletion ---
    // Verify note is gone from list (optimistic update)
    expect(find.text('Note to Delete'), findsNothing);
    // Verify SnackBar is shown
    // Use the correct translation key and argument structure
    expect(find.widgetWithText(SnackBar, 'notes_list_deleted'.tr(namedArgs: {'title': 'Note to Delete'})), findsOneWidget);
    // Verify UNDO button is shown
    expect(find.widgetWithText(SnackBarAction, 'undo'.tr()), findsOneWidget);

    // Simulate the database update (stream emits empty list after deletion)
    notesStreamController.add([]);
    await tester.pumpAndSettle(); // Wait for stream update

    // --- Act Undo ---
    // Tap UNDO button
    await tester.tap(find.widgetWithText(SnackBarAction, 'undo'.tr()));
    // The Bloc should call addNote. We simulate the stream update after addNote.
    notesStreamController.add([testNote]); // Simulate note reappearing in stream
    await tester.pumpAndSettle(); // Wait for undo action and stream reload

    // --- Assert Undo ---
    // Verify note is back
    expect(find.text('Note to Delete'), findsOneWidget);

    // Verify repository methods were called
    verify(mockRepository.deleteNote(testNote.id)).called(1);
    // Verify addNote was called once (for undo) - Use captureAny to check the argument if needed
    verify(mockRepository.addNote(any)).called(1);
    // Verify watchAllNotes was called (at least initially)
    verify(mockRepository.watchAllNotes(sortOption: anyNamed('sortOption'), searchQuery: anyNamed('searchQuery'))).called(greaterThanOrEqualTo(1));

    // Clean up stream controller
    await notesStreamController.close();

    // Verify note is present
    expect(find.text('Note to Delete'), findsOneWidget);

    // Simulate swipe to delete
    await tester.drag(find.byType(Dismissible), const Offset(-500.0, 0.0));
    await tester.pumpAndSettle(); // Wait for dismiss animation and SnackBar

    // --- Assert Deletion ---
    // Verify note is gone from list (optimistic update)
    expect(find.text('Note to Delete'), findsNothing);
    // Verify SnackBar is shown
    expect(find.widgetWithText(SnackBar, 'notes_list_deleted'.tr(args: ['Note to Delete'])), findsOneWidget);
    // Verify UNDO button is shown
    expect(find.widgetWithText(SnackBarAction, 'undo'.tr()), findsOneWidget);

    // --- Act Undo ---
    // Tap UNDO button
    await tester.tap(find.widgetWithText(SnackBarAction, 'undo'.tr()));
    // Mock the reload after undo
    when(mockRepository.getNotes()).thenAnswer((_) async => [testNote]); // Assume it's restored
    await tester.pumpAndSettle(); // Wait for undo action and potential reload

    // --- Assert Undo ---
    // Verify note is back
    expect(find.text('Note to Delete'), findsOneWidget);

    // Verify delete was called once
    verify(mockRepository.deleteNote(testNote.id)).called(1);
    // Verify addNote was called once (for undo)
    verify(mockRepository.addNote(any)).called(1);
    // Verify getNotes was called multiple times (initial load, after undo)
    verify(mockRepository.getNotes()).called(greaterThan(1));

  });
testWidgets('NotesListScreen allows searching notes', (WidgetTester tester) async {
    // --- Arrange ---
    final mockRepository = MockNoteRepository();
    final notesStreamController = StreamController<List<Note>>.broadcast();
    getIt.registerSingleton<NoteRepository>(mockRepository);

    // Define initial notes
    final initialTestNotes = [
      Note.create(title: 'Apple Note', text: 'About red apples.', createdAt: DateTime(2023, 10, 26), updatedAt: DateTime(2023, 10, 26))..id = 1,
      Note.create(title: 'Banana Note', text: 'About yellow bananas.', createdAt: DateTime(2023, 10, 25), updatedAt: DateTime(2023, 10, 25))..id = 2,
      Note.create(title: 'Another Apple', text: 'Green apples are tasty.', createdAt: DateTime(2023, 10, 24), updatedAt: DateTime(2023, 10, 24))..id = 3,
    ];

    // Mock watchAllNotes
    when(mockRepository.watchAllNotes(
      sortOption: anyNamed('sortOption'),
      searchQuery: anyNamed('searchQuery'),
    )).thenAnswer((invocation) {
      // Simulate filtering based on the captured query
      final query = invocation.namedArguments[#searchQuery] as String;
      final filteredNotes = initialTestNotes
          .where((note) =>
              note.title.toLowerCase().contains(query.toLowerCase()) ||
              note.text.toLowerCase().contains(query.toLowerCase()))
          .toList();
      if (!notesStreamController.isClosed) {
        notesStreamController.add(filteredNotes);
      }
      return notesStreamController.stream;
    });


    // --- Act ---
    // Build the app
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const MyApp(),
      ),
    );

    // Add initial notes to the stream
    // Use addPostFrameCallback to ensure listeners are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (!notesStreamController.isClosed) {
         notesStreamController.add(initialTestNotes);
       }
    });
    await tester.pumpAndSettle();

    // Verify initial state
    expect(find.text('Apple Note'), findsOneWidget);
    expect(find.text('Banana Note'), findsOneWidget);
    expect(find.text('Another Apple'), findsOneWidget);

    // Find the search field and enter text
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'Apple');

    // Wait for debounce timer (500ms in NotesListScreen) + a little extra
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle(); // Wait for stream update and UI rebuild

    // --- Assert Search ---
    // Verify watchAllNotes was called with the query
    verify(mockRepository.watchAllNotes(
      sortOption: anyNamed('sortOption'),
      searchQuery: 'Apple',
    )).called(greaterThanOrEqualTo(1)); // Called at least once after initial

    // Verify only matching notes are shown
    expect(find.text('Apple Note'), findsOneWidget);
    expect(find.text('Banana Note'), findsNothing);
    expect(find.text('Another Apple'), findsOneWidget);

    // --- Act Clear Search ---
    final clearButton = find.widgetWithIcon(IconButton, Icons.clear);
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pumpAndSettle(); // Wait for clear and stream update

    // --- Assert Clear Search ---
     // Verify watchAllNotes was called with empty query
    verify(mockRepository.watchAllNotes(
      sortOption: anyNamed('sortOption'),
      searchQuery: '',
    )).called(greaterThanOrEqualTo(1));

    // Verify all notes are shown again
    expect(find.text('Apple Note'), findsOneWidget);
    expect(find.text('Banana Note'), findsOneWidget);
    expect(find.text('Another Apple'), findsOneWidget);

    // Clean up
    await notesStreamController.close();
  });

  testWidgets('NotesListScreen allows sorting notes', (WidgetTester tester) async {
    // --- Arrange ---
    final mockRepository = MockNoteRepository();
    final notesStreamController = StreamController<List<Note>>.broadcast();
    getIt.registerSingleton<NoteRepository>(mockRepository);

    // Define initial notes (unsorted for testing)
    final initialTestNotes = [
      Note.create(title: 'Note B', text: 'Modified second', createdAt: DateTime(2023, 10, 25), updatedAt: DateTime(2023, 10, 25))..id = 2,
      Note.create(title: 'Note A', text: 'Modified first', createdAt: DateTime(2023, 10, 26), updatedAt: DateTime(2023, 10, 26))..id = 1,
      Note.create(title: 'Note C', text: 'Modified third', createdAt: DateTime(2023, 10, 24), updatedAt: DateTime(2023, 10, 24))..id = 3,
    ];

    // Mock watchAllNotes
    when(mockRepository.watchAllNotes(
      sortOption: anyNamed('sortOption'),
      searchQuery: anyNamed('searchQuery'),
    )).thenAnswer((invocation) {
      // Simulate sorting - actual sorting happens in repo, here we just pass notes
      // For test verification, we rely on checking the `verify` call later.
      // We pass the *original* unsorted list to ensure the UI updates based on stream
      if (!notesStreamController.isClosed) {
         notesStreamController.add(initialTestNotes);
      }
      return notesStreamController.stream;
    });


    // --- Act ---
    // Build the app
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const MyApp(),
      ),
    );

    // Add initial notes
    // Use addPostFrameCallback to ensure listeners are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (!notesStreamController.isClosed) {
         notesStreamController.add(initialTestNotes);
       }
    });
    await tester.pumpAndSettle();

    // Verify initial state (default sort is dateModifiedDescending)
    expect(find.text('Note A'), findsOneWidget);
    expect(find.text('Note B'), findsOneWidget);
    expect(find.text('Note C'), findsOneWidget);

    // Find and tap the sort button
    final sortButton = find.widgetWithIcon(IconButton, Icons.sort);
    expect(sortButton, findsOneWidget);
    await tester.tap(sortButton);
    await tester.pumpAndSettle(); // Wait for bottom sheet animation

    // Find and tap the 'Title (A-Z)' sort option
    // Use the exact text from en.json
    final titleAscSortOption = find.text('notesList.sortOptions.titleAsc'.tr());
    expect(titleAscSortOption, findsOneWidget); // Ensure it's visible in the sheet
    await tester.tap(titleAscSortOption);
    await tester.pumpAndSettle(); // Wait for sheet dismissal and stream update

    // --- Assert Sort Change ---
    // Verify watchAllNotes was called with the new sort option
    verify(mockRepository.watchAllNotes(
      sortOption: NoteSortOption.titleAscending,
      searchQuery: anyNamed('searchQuery'),
    )).called(greaterThanOrEqualTo(1));

    // Optional: If mock actually sorted, verify UI order here.
    // Since our mock doesn't sort, we just verified the call above.

    // Clean up
    await notesStreamController.close();
  });
}

