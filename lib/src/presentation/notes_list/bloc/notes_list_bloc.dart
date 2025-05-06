import 'dart:async'; // Added for StreamSubscription

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart'; // Added for Isar.autoIncrement
import '../../../domain/entities/note.dart';
import '../../../domain/repositories/note_repository.dart';
import '../../../domain/entities/note_sort_option.dart'; // Import the sort option
import 'package:injectable/injectable.dart'; // Import injectable

part 'notes_list_event.dart';
part 'notes_list_state.dart';

// Define internal events for stream updates
abstract class _NotesListInternalEvent extends NotesListEvent {
  const _NotesListInternalEvent();
}

class _NotesUpdated extends _NotesListInternalEvent {
  final List<Note> notes;
  const _NotesUpdated(this.notes);

  @override
  List<Object> get props => [notes];
}

class _NotesUpdateFailed extends _NotesListInternalEvent {
  final String error;
  const _NotesUpdateFailed(this.error);

  @override
  List<Object> get props => [error];
}

@LazySingleton() // Register as LazySingleton to preserve state (Added parentheses)
class NotesListBloc extends Bloc<NotesListEvent, NotesListState> {
  final NoteRepository _noteRepository;
  StreamSubscription<List<Note>>?
  _notesSubscription; // Added subscription field

  // Inject the repository via constructor
  NotesListBloc({required NoteRepository noteRepository})
      : _noteRepository = noteRepository,
        super(NotesListLoading()) {
    // Start with Loading state
    // Initial subscription with default sort/search
    _subscribeToNotes(
      sortOption: NoteSortOption.dateModifiedDescending,
      searchQuery: '',
    );

    // Register event handlers
    on<_NotesUpdated>(_onNotesUpdated);
    on<_NotesUpdateFailed>(_onNotesUpdateFailed);
    on<DeleteNote>(_onDeleteNote);
    on<UndoDeleteNote>(_onUndoDeleteNote);
    on<SearchQueryChanged>(_onSearchQueryChanged); // Add handler
    on<SortOptionChanged>(_onSortOptionChanged); // Add handler
  }

  // Handler for successful stream updates (notes are already filtered/sorted by repo)
  void _onNotesUpdated(_NotesUpdated event, Emitter<NotesListState> emit) {
    final currentState = state;
    NoteSortOption currentSortOption = NoteSortOption.dateModifiedDescending;
    String currentSearchQuery = '';
    Note? existingLastDeletedNote;
    String? existingErrorMessage;

    // Get current sort/search options and other state fields
    if (currentState is NotesListLoaded) {
      currentSortOption = currentState.sortOption;
      currentSearchQuery = currentState.searchQuery;
      existingLastDeletedNote = currentState.lastDeletedNote;
      existingErrorMessage = currentState.errorMessage;
    } else if (currentState is NotesListLoading) {
      // If loading, use defaults (this might happen on initial load)
      // The sort/search options used for the subscription are the source of truth
      // but we need them for the state object.
      // TODO: Revisit if this logic needs refinement for initial load edge cases.
    }

    // Emit the loaded state with the notes received from the stream
    emit(
      NotesListLoaded(
        event.notes, // Use notes directly from the event
        sortOption: currentSortOption,
        searchQuery: currentSearchQuery,
        lastDeletedNote: existingLastDeletedNote,
        errorMessage: existingErrorMessage,
      ),
    );
  }

  // Handler for stream update errors
  void _onNotesUpdateFailed(
    _NotesUpdateFailed event,
    Emitter<NotesListState> emit,
  ) {
    emit(NotesListError(event.error));
  }

  // Event handler for deleting a note
  Future<void> _onDeleteNote(
    DeleteNote event,
    Emitter<NotesListState> emit,
  ) async {
    // Ensure current state is loaded to get the note to delete
    final currentState = state;
    if (currentState is! NotesListLoaded) {
      // If the state is not loaded, we cannot delete. Maybe emit an error?
      // For now, just return.
      return;
    }

    final noteToDelete = currentState.notes.firstWhere(
      (note) => note.id == event.noteId,
      orElse: () => Note(), // Return default Note if not found
    );

    // Check if the note was actually found (ID will be autoIncrement if orElse was triggered)
    if (noteToDelete.id == Isar.autoIncrement) {
      emit(
        currentState.copyWith(
          errorMessage: 'Note with ID ${event.noteId} not found for deletion.',
        ),
      );
      return;
    }

    // Proceed with deletion
    try {
      // Optimistically remove the note from the UI and store for potential undo
      final updatedNotes = List<Note>.from(currentState.notes)
        ..removeWhere((note) => note.id == event.noteId);
      emit(
        currentState.copyWith(
          notes: updatedNotes,
          lastDeletedNote: noteToDelete,
          clearErrorMessage: true,
        ),
      );

      // Perform the actual deletion
      await _noteRepository.deleteNote(event.noteId);
      // No manual emit needed, stream watcher will update the list
    } catch (e) {
      // If deletion fails, revert UI and emit error state
      // Revert UI by emitting previous state (before optimistic update) with error message
      emit(
        currentState.copyWith(
          errorMessage: 'Failed to delete note: ${e.toString()}',
          // Ensure lastDeletedNote is cleared as deletion failed
          lastDeletedNote: null,
        ),
      );
    }
  }

  Future<void> _onUndoDeleteNote(
    UndoDeleteNote event,
    Emitter<NotesListState> emit,
  ) async {
    final currentState = state;
    if (currentState is NotesListLoaded &&
        currentState.lastDeletedNote != null) {
      final noteToRestore = currentState.lastDeletedNote!;
      final stateBeforeUndo = currentState.copyWith(
        clearLastDeleted: true,
      ); // State after clearing undo flag

      try {
        // Perform the actual repository action to restore the note
        await _noteRepository.addNote(noteToRestore);
        // Explicitly clear lastDeletedNote after successful restoration
        // Use the current state (which includes the optimistically added note)
        // and clear the lastDeletedNote flag.
        final stateAfterOptimisticAdd = state;
        if (stateAfterOptimisticAdd is NotesListLoaded) {
          emit(stateAfterOptimisticAdd.copyWith(clearLastDeleted: true));
        }
        // Stream watcher will eventually update with the definitive list from DB
      } catch (e) {
        // If adding fails, revert UI to the state *before* optimistic update and show error
        emit(
          stateBeforeUndo.copyWith(
            // Revert notes list to the one before optimistic update
            notes: stateBeforeUndo.notes,
            errorMessage: 'Failed to undo delete: ${e.toString()}',
          ),
        );
      }
    }
  }

  // Handler for search query changes
  void _onSearchQueryChanged(
      SearchQueryChanged event, Emitter<NotesListState> emit) {
    final currentState = state;
    if (currentState is NotesListLoaded) {
      // Emit new state with updated query, keep existing notes temporarily
      emit(currentState.copyWith(
        searchQuery: event.query,
        clearErrorMessage: true,
        clearLastDeleted: true,
      ));
      // Resubscribe with the new query
      _subscribeToNotes(
        sortOption: currentState.sortOption,
        searchQuery: event.query,
      );
    }
    // If not loaded, the initial subscription will handle it eventually.
  }

  // Handler for sort option changes
  void _onSortOptionChanged(
      SortOptionChanged event, Emitter<NotesListState> emit) {
    final currentState = state;
    if (currentState is NotesListLoaded) {
      // Emit new state with updated sort option, keep existing notes temporarily
      emit(currentState.copyWith(
        sortOption: event.sortOption,
        clearErrorMessage: true,
        clearLastDeleted: true,
      ));
      // Resubscribe with the new sort option
      _subscribeToNotes(
        sortOption: event.sortOption,
        searchQuery: currentState.searchQuery,
      );
    }
    // If not loaded, the initial subscription will handle it eventually.
  }

  // Helper to manage the notes stream subscription
  void _subscribeToNotes({
    required NoteSortOption sortOption,
    required String searchQuery,
  }) {
    // Cancel previous subscription if it exists
    _notesSubscription?.cancel();

    // Create new subscription with current parameters
    _notesSubscription = _noteRepository
        .watchAllNotes(
      sortOption: sortOption,
      searchQuery: searchQuery,
    )
        .listen(
      (notes) => add(_NotesUpdated(notes)),
      onError: (error) => add(_NotesUpdateFailed(error.toString())),
    );
  }

  @override
  Future<void> close() {
    _notesSubscription?.cancel(); // Cancel subscription on close
    return super.close();
  }
}
