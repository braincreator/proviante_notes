part of 'note_edit_bloc.dart';

enum NoteEditStatus { initial, loading, loaded, saving, success, failure }

class NoteEditState extends Equatable {
  final NoteEditStatus status;
  final Note? initialNote; // The note being edited, null if new
  final String title;
  final String text;
  final String? errorMessage;
  final NoteEditEvent? lastEvent; // Added to track the last event for messages
  // final Note? recentlyDeletedNote; // Removed redundant field

  const NoteEditState({
    this.status = NoteEditStatus.initial,
    this.initialNote,
    this.title = '',
    this.text = '',
    this.errorMessage,
    this.lastEvent, // Added
    // this.recentlyDeletedNote, // Removed from constructor
  });

  // Helper to check if it's a new note
  bool get isNewNote => initialNote == null;

  NoteEditState copyWith({
    NoteEditStatus? status,
    Note? initialNote, // Use ValueGetter to allow explicit null
    String? title,
    String? text,
    String? errorMessage,
    NoteEditEvent? lastEvent, // Added
    // Note? recentlyDeletedNote, // Removed from copyWith parameters
    // Helper to explicitly set errorMessage to null
    bool clearErrorMessage = false,
    // bool clearRecentlyDeleted = false, // Removed flag
  }) {
    return NoteEditState(
      status: status ?? this.status,
      initialNote: initialNote ?? this.initialNote,
      title: title ?? this.title,
      text: text ?? this.text,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      lastEvent: lastEvent ?? this.lastEvent, // Added
      // recentlyDeletedNote: clearRecentlyDeleted ? null : recentlyDeletedNote ?? this.recentlyDeletedNote, // Removed assignment
    );
  }

  @override
  List<Object?> get props => [status, initialNote, title, text, errorMessage, lastEvent]; // Removed recentlyDeletedNote
}