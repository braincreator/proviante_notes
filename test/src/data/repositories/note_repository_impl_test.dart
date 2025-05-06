import 'dart:async'; // Import for StreamController
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:proviante_notes/src/data/datasources/local_note_datasource.dart';
import 'package:proviante_notes/src/data/repositories/note_repository_impl.dart';
import 'package:proviante_notes/src/domain/entities/note.dart';
import 'package:proviante_notes/src/domain/entities/note_sort_option.dart';

// Generate mocks for LocalNoteDatasource
@GenerateMocks([LocalNoteDatasource])
import 'note_repository_impl_test.mocks.dart';

void main() {
  late MockLocalNoteDatasource mockLocalNoteDatasource;
  late NoteRepositoryImpl repository;

  setUp(() {
    mockLocalNoteDatasource = MockLocalNoteDatasource();
    repository = NoteRepositoryImpl(datasource: mockLocalNoteDatasource); // Fix: Use named parameter
  });

  // Fix: Use default constructor and property assignment, change content to text
  final tNote1 = Note()
    ..id = 1
    ..title = 'Test Note 1'
    ..text = 'Test Content 1' // Fix: Use 'text'
    ..createdAt = DateTime(2023, 1, 1)
    ..updatedAt = DateTime(2023, 1, 1);

  final tNote2 = Note()
    ..id = 2
    ..title = 'Test Note 2'
    ..text = 'Test Content 2' // Fix: Use 'text'
    ..createdAt = DateTime(2023, 1, 2)
    ..updatedAt = DateTime(2023, 1, 2);

  final tNotesList = [tNote1, tNote2];
  const tSortOption = NoteSortOption.titleAscending; // Fix: Use valid enum value
  const tSearchQuery = 'Test';
  const tNoteId = 1;

  // Fix: Test the actual getNotes method which calls getAllNotes
  group('getNotes', () {
    test('should return list of notes from the datasource', () async {
      // Arrange
      when(mockLocalNoteDatasource.getAllNotes()) // Fix: Mock getAllNotes
          .thenAnswer((_) async => tNotesList);

      // Act
      final result = await repository.getNotes(); // Fix: Call getNotes without params

      // Assert
      expect(result, equals(tNotesList));
      verify(mockLocalNoteDatasource.getAllNotes()); // Fix: Verify getAllNotes
      verifyNoMoreInteractions(mockLocalNoteDatasource);
    });
  });

  // Fix: Test addNote method
  group('addNote', () {
    test('should call saveNote on the datasource when adding', () async {
      // Arrange
      // saveNote is used for both add and update in datasource
      when(mockLocalNoteDatasource.saveNote(any)).thenAnswer((_) async => tNote1.id);

      // Act
      await repository.addNote(tNote1); // Fix: Call addNote

      // Assert
      verify(mockLocalNoteDatasource.saveNote(tNote1)); // Datasource uses saveNote
      verifyNoMoreInteractions(mockLocalNoteDatasource);
    });
  });

  // Fix: Test updateNote method
  group('updateNote', () {
    test('should call saveNote on the datasource when updating', () async {
      // Arrange
      when(mockLocalNoteDatasource.saveNote(any)).thenAnswer((_) async => tNote1.id);

      // Act
      await repository.updateNote(tNote1); // Fix: Call updateNote

      // Assert
      verify(mockLocalNoteDatasource.saveNote(tNote1)); // Datasource uses saveNote
      verifyNoMoreInteractions(mockLocalNoteDatasource);
    });
  });

  group('deleteNote', () {
    test('should call deleteNote on the datasource', () async {
      // Arrange
      when(mockLocalNoteDatasource.deleteNote(any)).thenAnswer((_) async => true); // Assuming delete returns success bool

      // Act
      await repository.deleteNote(tNoteId);

      // Assert
      verify(mockLocalNoteDatasource.deleteNote(tNoteId));
      verifyNoMoreInteractions(mockLocalNoteDatasource);
    });
  });

  group('deleteNote', () {
    test('should call deleteNote on the datasource', () async {
      // Arrange
      when(mockLocalNoteDatasource.deleteNote(any)).thenAnswer((_) async => true); // Assuming delete returns success bool

      // Act
      await repository.deleteNote(tNoteId);

      // Assert
      verify(mockLocalNoteDatasource.deleteNote(tNoteId));
      verifyNoMoreInteractions(mockLocalNoteDatasource);
    });
  });

   group('getNoteById', () {
    test('should return a note from the datasource when called with an id', () async {
      // Arrange
      when(mockLocalNoteDatasource.getNoteById(any)).thenAnswer((_) async => tNote1);

      // Act
      final result = await repository.getNoteById(tNoteId);

      // Assert
      expect(result, equals(tNote1));
      verify(mockLocalNoteDatasource.getNoteById(tNoteId));
      verifyNoMoreInteractions(mockLocalNoteDatasource);
    });

     test('should return null if datasource returns null', () async {
      // Arrange
      when(mockLocalNoteDatasource.getNoteById(any)).thenAnswer((_) async => null);

      // Act
      final result = await repository.getNoteById(tNoteId);

      // Assert
      expect(result, isNull);
      verify(mockLocalNoteDatasource.getNoteById(tNoteId));
      verifyNoMoreInteractions(mockLocalNoteDatasource);
    });
  });

  // Add test for watchAllNotes
  group('watchAllNotes', () {
    test('should call watchAllNotes on the datasource with correct parameters', () {
      // Arrange
      final streamController = StreamController<List<Note>>();
      when(mockLocalNoteDatasource.watchAllNotes(
        sortOption: anyNamed('sortOption'),
        searchQuery: anyNamed('searchQuery'),
      )).thenAnswer((_) => streamController.stream);

      // Act
      final result = repository.watchAllNotes(
        sortOption: tSortOption,
        searchQuery: tSearchQuery,
      );

      // Assert
      expect(result, isA<Stream<List<Note>>>());
      verify(mockLocalNoteDatasource.watchAllNotes(
        sortOption: tSortOption,
        searchQuery: tSearchQuery,
      ));
      verifyNoMoreInteractions(mockLocalNoteDatasource);

      streamController.close(); // Clean up stream controller
    });
  });

  // Add test for noteTitleExists
  group('noteTitleExists', () {
    test('should call noteTitleExists on the datasource', () async {
      // Arrange
      const title = 'Existing Title';
      const excludeId = 5;
      when(mockLocalNoteDatasource.noteTitleExists(any, excludeId: anyNamed('excludeId')))
          .thenAnswer((_) async => true);

      // Act
      final result = await repository.noteTitleExists(title, excludeId: excludeId);

      // Assert
      expect(result, isTrue);
      verify(mockLocalNoteDatasource.noteTitleExists(title, excludeId: excludeId));
      verifyNoMoreInteractions(mockLocalNoteDatasource);
    });
  });
}