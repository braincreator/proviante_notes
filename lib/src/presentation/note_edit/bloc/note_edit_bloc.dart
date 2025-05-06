import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/repositories/note_repository.dart';
import 'package:easy_localization/easy_localization.dart'; // Import easy_localization

part 'note_edit_event.dart';
part 'note_edit_state.dart';

@injectable // Register as factory (new instance per request)
class NoteEditBloc extends Bloc<NoteEditEvent, NoteEditState> {
  final NoteRepository _noteRepository;

  NoteEditBloc({required NoteRepository noteRepository})
      : _noteRepository = noteRepository,
        super(const NoteEditState()) {
    on<LoadNoteToEdit>(_onLoadNoteToEdit);
    on<LoadNoteById>(_onLoadNoteById); // Register the new event handler
    on<TitleChanged>(_onTitleChanged);
    on<TextChanged>(_onTextChanged);
    on<SaveNote>(_onSaveNote);
    on<DeleteNote>(_onDeleteNote); // Register DeleteNote handler
  }

  void _onLoadNoteToEdit(LoadNoteToEdit event, Emitter<NoteEditState> emit) {
    emit(state.copyWith(
      status: NoteEditStatus.loaded,
      initialNote: event.note, // Keep track of the original note
      title: event.note?.title ?? '',
      text: event.note?.text ?? '',
    ));
  }

  void _onTitleChanged(TitleChanged event, Emitter<NoteEditState> emit) {
    emit(state.copyWith(title: event.title));
  }

  void _onTextChanged(TextChanged event, Emitter<NoteEditState> emit) {
    emit(state.copyWith(text: event.text));
  }

  Future<void> _onSaveNote(SaveNote event, Emitter<NoteEditState> emit) async {
    // --- Validation Start ---
    final trimmedTitle = state.title.trim(); // Get and trim title

    // Check for empty title
    if (trimmedTitle.isEmpty) {
      emit(state.copyWith(
        status: NoteEditStatus.failure,
        errorMessage: 'noteEdit.error.emptyTitle'.tr(), // Use localization key
      ));
      return; // Stop processing
    }

    // Check for duplicate title
    final idToExclude = state.isNewNote ? null : state.initialNote!.id;
    final bool titleExists = await _noteRepository.noteTitleExists(
      trimmedTitle,
      excludeId: idToExclude,
    );

    if (titleExists) {
      emit(state.copyWith(
        status: NoteEditStatus.failure,
        errorMessage: 'noteEdit.error.duplicateTitle'.tr(), // Use localization key
      ));
      return; // Stop processing
    }
    // --- Validation End ---

    // If validation passes, proceed with existing save logic...
    emit(state.copyWith(status: NoteEditStatus.saving, clearErrorMessage: true)); // Changed from loading to saving as per original code
    try {
      final now = DateTime.now();
      // Use the validated trimmedTitle here
      final noteToSave = state.isNewNote
          ? Note.create( // Use the named constructor
              title: trimmedTitle, // Use validated trimmed title
              text: state.text.trim(), // Trim whitespace
              createdAt: now,
              updatedAt: now,
            )
          : state.initialNote!.copyWith( // Use copyWith on existing note
              title: trimmedTitle, // Use validated trimmed title
              text: state.text.trim(), // Trim whitespace consistently
              updatedAt: DateTime.now(),
            );

      if (state.isNewNote) {
        await _noteRepository.addNote(noteToSave);
      } else {
        await _noteRepository.updateNote(noteToSave);
      }
      emit(state.copyWith(status: NoteEditStatus.success));
    } catch (e, stackTrace) { // Also capture stackTrace for better debugging
      print('Error saving note: $e\n$stackTrace'); // Add print statement
      emit(state.copyWith(
        status: NoteEditStatus.failure,
        errorMessage: e.toString(), // Keep updating state
      ));
    }
  }

  // Handler for LoadNoteById event
  Future<void> _onLoadNoteById(LoadNoteById event, Emitter<NoteEditState> emit) async {
    emit(state.copyWith(status: NoteEditStatus.loading, clearErrorMessage: true));
    try {
      final note = await _noteRepository.getNoteById(event.noteId);
      if (note != null) {
        emit(state.copyWith(
          status: NoteEditStatus.loaded,
          initialNote: note, // Keep track of the original note
          title: note.title,
          text: note.text,
        ));
      } else {
        // Handle case where note with the given ID is not found
        emit(state.copyWith(
          status: NoteEditStatus.failure,
          errorMessage: 'noteEdit.error.notFound'.tr(), // Use localization key
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: NoteEditStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  // Handler for DeleteNote event
  Future<void> _onDeleteNote(DeleteNote event, Emitter<NoteEditState> emit) async {
    final noteToDelete = state.initialNote; // Store the note before deleting

    // Ensure we have a note ID to delete and it matches the current note
    if (noteToDelete?.id != event.noteId || event.noteId == null) {
      emit(state.copyWith(
        status: NoteEditStatus.failure,
        errorMessage: 'Cannot delete note: ID mismatch or note not loaded.',
      ));
      return;
    }

    emit(state.copyWith(status: NoteEditStatus.saving, clearErrorMessage: true)); // Use saving status for delete too
    try {
      await _noteRepository.deleteNote(event.noteId!);
      // Emit success, no need to store deleted note here
      emit(state.copyWith(
        status: NoteEditStatus.success,
        lastEvent: event, // Track the event for listener
      ));
    } catch (e, stackTrace) {
      print('Error deleting note: $e\n$stackTrace');
      emit(state.copyWith(
        status: NoteEditStatus.failure,
        errorMessage: 'Failed to delete note: ${e.toString()}',
      ));
    }
  }
}