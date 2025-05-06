part of 'note_edit_bloc.dart';

abstract class NoteEditEvent extends Equatable {
  const NoteEditEvent();

  @override
  List<Object?> get props => [];
}

// Event to load an existing note for editing, or null for a new note
class LoadNoteToEdit extends NoteEditEvent {
  final Note? note;

  const LoadNoteToEdit(this.note);

  @override
  List<Object?> get props => [note];
}

// Event to load an existing note by its ID
class LoadNoteById extends NoteEditEvent {
  final int noteId;

  const LoadNoteById(this.noteId);

  @override
  List<Object> get props => [noteId];
}
// Event when the title input changes
class TitleChanged extends NoteEditEvent {
  final String title;

  const TitleChanged(this.title);

  @override
  List<Object> get props => [title];
}

// Event when the text input changes
class TextChanged extends NoteEditEvent {
  final String text;

  const TextChanged(this.text);

  @override
  List<Object> get props => [text];
}

// Event to trigger saving the note (add or update)
class SaveNote extends NoteEditEvent {}

// Event to trigger deleting the note
class DeleteNote extends NoteEditEvent {
  final int noteId; // ID of the note to delete

  const DeleteNote(this.noteId);

  @override
  List<Object> get props => [noteId];
}