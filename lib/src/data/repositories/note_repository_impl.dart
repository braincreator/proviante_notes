import '../../domain/entities/note.dart';
import '../../domain/entities/note_sort_option.dart'; // Import sort option
import '../../domain/repositories/note_repository.dart';
import '../datasources/local_note_datasource.dart';
import 'package:injectable/injectable.dart'; // Import injectable

@LazySingleton(as: NoteRepository) // Register as LazySingleton implementing NoteRepository
class NoteRepositoryImpl implements NoteRepository {
  final LocalNoteDatasource datasource;

  NoteRepositoryImpl({required this.datasource});

  @override
  Future<List<Note>> getNotes() async {
    // Directly call the datasource method
    // TODO: Consider adding search/sort here too?
    return await datasource.getAllNotes();
  }

@override
  Future<Note?> getNoteById(int id) async {
    // Call the datasource method
    return await datasource.getNoteById(id);
  }
  @override
  Future<void> addNote(Note note) async {
    // Use the saveNote method which handles creation
    await datasource.saveNote(note);
  }

  @override
  Future<void> updateNote(Note note) async {
    // Use the saveNote method which handles updates
    await datasource.saveNote(note);
  }

  @override
  Future<void> deleteNote(int id) async {
    // Call the deleteNote method
    await datasource.deleteNote(id);
  }
@override
  Stream<List<Note>> watchAllNotes({
    NoteSortOption sortOption = NoteSortOption.dateModifiedDescending,
    String searchQuery = '',
  }) {
    // Call the datasource method, passing parameters
    return datasource.watchAllNotes(
      sortOption: sortOption,
      searchQuery: searchQuery,
    );
  }
@override
  Future<bool> noteTitleExists(String title, {int? excludeId}) {
    // Delegate to the datasource
    return datasource.noteTitleExists(title, excludeId: excludeId);
  }
}