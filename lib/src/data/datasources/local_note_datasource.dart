import '../../domain/entities/note.dart';
import '../../domain/entities/note_sort_option.dart'; // Import sort option

abstract class LocalNoteDatasource {
  Future<void> init();
  Future<List<Note>> getAllNotes(); // Consider adding search/sort here too? Maybe later.
  Future<Note?> getNoteById(int id);
  Future<void> saveNote(Note note);
  Future<void> deleteNote(int id);
  Stream<List<Note>> watchAllNotes({
    NoteSortOption sortOption = NoteSortOption.dateModifiedDescending,
    String searchQuery = '',
  });
  Future<bool> noteTitleExists(String title, {int? excludeId});
}
