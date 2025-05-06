import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart'; // Needed for Isar.open
import 'package:flutter/foundation.dart'; // For kDebugMode and debugPrint
import '../../domain/entities/note.dart';
import '../../domain/entities/note_sort_option.dart'; // Import sort option
import 'local_note_datasource.dart';
import 'package:injectable/injectable.dart'; // Import injectable

@Singleton(as: LocalNoteDatasource) // Register as Singleton implementing LocalNoteDatasource
class IsarNoteDatasource implements LocalNoteDatasource {
  Isar? _isar;

  // Private method to get DB instance, handles initialization
  Future<Isar> _getDb() async {
    if (_isar == null || !_isar!.isOpen) {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [NoteSchema],
        directory: dir.path,
        name: 'notesDb', // Optional: name the instance
      );
    }
    return _isar!;
  }

  // This method needs to be called before the instance is used.
  // @preResolve tells injectable to await this future before returning the instance.
  @preResolve
  @override
  Future<IsarNoteDatasource> init() async {
    await _getDb(); // Ensure the database is initialized
    if (kDebugMode) {
      print('Isar database initialized.'); // Optional: confirmation log
    }
    return this; // Return the instance itself
  }

  @override
  @override
  Future<List<Note>> getAllNotes() async {
    final isar = await _getDb();
    // Fetch all notes and sort by createdAt descending
    // Exceptions will now propagate up.
    return await isar.notes.where().sortByCreatedAtDesc().findAll();
  }

@override
  Future<Note?> getNoteById(int id) async {
    try {
      final isar = await _getDb();
      // Use Isar's get method to retrieve by ID
      return await isar.notes.get(id);
    } catch (e) {
      debugPrint('Error getting note by id ($id): $e');
      rethrow; // Rethrow to allow higher layers to handle
    }
  }
  @override
  Future<void> saveNote(Note note) async {
    try {
      final isar = await _getDb();
      await isar.writeTxn(() async {
        await isar.notes.put(note); // put handles both create and update
      });
    } catch (e) {
      debugPrint('Error saving note (id: ${note.id}): $e');
      // Rethrow or handle error appropriately
      rethrow; // Rethrowing allows higher layers to handle it
    }
  }

  @override
  Future<void> deleteNote(int id) async {
    try {
      final isar = await _getDb();
      await isar.writeTxn(() async {
        final success = await isar.notes.delete(id);
        if (!success && kDebugMode) {
          // Note with id $id not found for deletion. (Removed print)
        }
      });
    } catch (e) {
      debugPrint('Error deleting note (id: $id): $e');
      rethrow;
    }
  }
@override
  Stream<List<Note>> watchAllNotes({
    NoteSortOption sortOption = NoteSortOption.dateModifiedDescending,
    String searchQuery = '',
  }) async* {
    final isar = await _getDb();

    // Use a function to build the query to handle type complexity
    QueryBuilder<Note, Note, QAfterSortBy> buildSortedQuery() {
      QueryBuilder<Note, Note, QWhere> baseQuery = isar.notes.where();

      // Apply filter first if needed
      if (searchQuery.isNotEmpty) {
        final lowerCaseQuery = searchQuery.toLowerCase();
        // Apply filter and then sort
        final filteredQuery = baseQuery.filter().group((q) => q
            .titleContains(lowerCaseQuery, caseSensitive: false)
            .or()
            .textContains(lowerCaseQuery, caseSensitive: false));

        switch (sortOption) {
          case NoteSortOption.dateCreatedAscending:
            return filteredQuery.sortByCreatedAt();
          case NoteSortOption.dateCreatedDescending:
            return filteredQuery.sortByCreatedAtDesc();
          case NoteSortOption.dateModifiedAscending:
            return filteredQuery.sortByUpdatedAt();
          case NoteSortOption.dateModifiedDescending:
            return filteredQuery.sortByUpdatedAtDesc();
          case NoteSortOption.titleAscending:
            return filteredQuery.sortByTitle();
          case NoteSortOption.titleDescending:
            return filteredQuery.sortByTitleDesc();
        }
      } else {
        // No filter, apply sort directly to baseQuery
        switch (sortOption) {
          case NoteSortOption.dateCreatedAscending:
            return baseQuery.sortByCreatedAt();
          case NoteSortOption.dateCreatedDescending:
            return baseQuery.sortByCreatedAtDesc();
          case NoteSortOption.dateModifiedAscending:
            return baseQuery.sortByUpdatedAt();
          case NoteSortOption.dateModifiedDescending:
            return baseQuery.sortByUpdatedAtDesc();
          case NoteSortOption.titleAscending:
            return baseQuery.sortByTitle();
          case NoteSortOption.titleDescending:
            return baseQuery.sortByTitleDesc();
        }
      }
    }

    // Build the query and watch it
    final finalQuery = buildSortedQuery();
    yield* finalQuery.watch(fireImmediately: true);
  }

@override
  Future<bool> noteTitleExists(String title, {int? excludeId}) async {
    final isar = await _getDb();
    var query = isar.notes
        .filter()
        .titleEqualTo(title, caseSensitive: false); // Case-insensitive check

    if (excludeId != null) {
      // If excludeId is provided, add a condition to exclude that specific note ID
      query = query.and().not().idEqualTo(excludeId);
    }

    final count = await query.count();
    return count > 0;
  }
  // Method to close the Isar instance, intended for use with DI disposal
  Future<void> close() async {
    if (_isar?.isOpen == true) {
      await _isar!.close();
      if (kDebugMode) {
        print('Isar database closed.');
      }
    }
  }
}