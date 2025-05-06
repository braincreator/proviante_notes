import '../entities/note.dart';
import '../entities/note_sort_option.dart'; // Import sort option

abstract class NoteRepository {
  Future<List<Note>> getNotes(); // Consider adding search/sort here too? Maybe later.
  Future<Note?> getNoteById(int id);
  Future<void> addNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(int id);
  Stream<List<Note>> watchAllNotes({
    NoteSortOption sortOption = NoteSortOption.dateModifiedDescending,
    String searchQuery = '',
  });
  Future<bool> noteTitleExists(String title, {int? excludeId});
}
