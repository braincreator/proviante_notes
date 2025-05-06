part of 'notes_list_bloc.dart';

abstract class NotesListState extends Equatable {
  const NotesListState();

  @override
  List<Object?> get props => []; // Change to List<Object?>
}

class NotesListInitial extends NotesListState {}

class NotesListLoading extends NotesListState {}

class NotesListLoaded extends NotesListState {
  final List<Note> notes;
  final NoteSortOption sortOption;
  final String searchQuery;
  final Note? lastDeletedNote; // To hold the note for potential undo
  final String? errorMessage; // To display non-fatal errors (e.g., delete failed)

  const NotesListLoaded(
    this.notes, {
    this.sortOption = NoteSortOption.dateModifiedDescending, // Default sort
    this.searchQuery = '', // Default empty search
    this.lastDeletedNote,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        notes,
        sortOption,
        searchQuery,
        lastDeletedNote,
        errorMessage,
      ]; // Add new fields to props

  // copyWith for easier state updates
  NotesListLoaded copyWith({
    List<Note>? notes,
    NoteSortOption? sortOption,
    String? searchQuery,
    Note? lastDeletedNote,
    String? errorMessage,
    bool clearLastDeleted = false, // Helper to explicitly clear lastDeletedNote
    bool clearErrorMessage = false, // Helper to explicitly clear errorMessage
  }) {
    return NotesListLoaded(
      notes ?? this.notes,
      sortOption: sortOption ?? this.sortOption,
      searchQuery: searchQuery ?? this.searchQuery,
      lastDeletedNote:
          clearLastDeleted ? null : lastDeletedNote ?? this.lastDeletedNote,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class NotesListError extends NotesListState {
  final String message;

  const NotesListError(this.message);

  @override
  List<Object> get props => [message];
}