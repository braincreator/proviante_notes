import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../domain/entities/note.dart';
import 'note_list_item.dart'; // Import NoteListItem

// Extracted Helper widget to display the responsive list/grid content
class NotesListContent extends StatelessWidget {
  final List<Note> notes;
  final void Function(Note note) onNoteTap;

  const NotesListContent({
    super.key, // Added key
    required this.notes,
    required this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a ValueKey based on the notes list to trigger animation on change
        final listKey = ValueKey(notes);

        if (constraints.maxWidth < 600) {
          // Use ListView for narrow screens
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              // NoteListItem already has its own key and entry animation
              return NoteListItem(note: note, onTap: onNoteTap);
            },
          ).animate(key: listKey).fadeIn(duration: 300.ms); // Fade in the whole list on change
        } else {
          // Use GridView for wider screens
          final crossAxisCount = (constraints.maxWidth / 300).floor().clamp(
            2,
            4, // Max 4 columns
          );
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 3 / 2, // Adjust aspect ratio as needed
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
               // NoteListItem already has its own key and entry animation
              return NoteListItem(note: note, onTap: onNoteTap);
            },
          ).animate(key: listKey).fadeIn(duration: 300.ms); // Fade in the whole grid on change
        }
      },
    );
  }
}