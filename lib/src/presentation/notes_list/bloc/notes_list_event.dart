part of 'notes_list_bloc.dart';

abstract class NotesListEvent extends Equatable {
  const NotesListEvent();

  @override
  List<Object> get props => [];
}

class DeleteNote extends NotesListEvent {
  final int noteId;

  const DeleteNote(this.noteId);

  @override
  List<Object> get props => [noteId];
}

// Event to undo the last deletion
class UndoDeleteNote extends NotesListEvent {}
// Event for updating the search query
class SearchQueryChanged extends NotesListEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}

// Event for changing the sort option
class SortOptionChanged extends NotesListEvent {
  final NoteSortOption sortOption;

  const SortOptionChanged(this.sortOption);

  @override
  List<Object> get props => [sortOption];
}