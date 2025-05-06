import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import '../../../domain/entities/note.dart';
import '../bloc/notes_list_bloc.dart'; // For events

// Renamed from _NoteListItem and made public
class NoteListItem extends StatelessWidget {
  final Note note;
  final void Function(Note note)? onTap; // Add onTap callback

  const NoteListItem({
    super.key,
    required this.note,
    this.onTap, // Add to constructor
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMd(context.locale.toString())
        .add_jm()
        .format(note.createdAt);

    // Removed manual text snippet logic

    return Dismissible(
      key: Key('note_${note.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        // Only dispatch the event, Snackbar is handled in NotesListScreen now
        context.read<NotesListBloc>().add(DeleteNote(note.id));
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0), // Match Card margin
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8.0), // Match Card shape
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0), // Keep existing padding for icon
        child: const Icon(Icons.delete_sweep_outlined, color: Colors.white), // Updated dismiss icon
      ),
      child: Card( // Wrap ListTile with Card
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell( // Use InkWell for tap effect within Card
          onTap: () => onTap?.call(note), // Keep onTap functionality
          borderRadius: BorderRadius.circular(8), // Match Card shape
          child: Padding( // Add internal padding
            padding: const EdgeInsets.all(16.0), // Increased internal padding
            child: Column( // Use Column for better control over layout
              crossAxisAlignment: CrossAxisAlignment.stretch, // Make column children fill width
              children: [
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith( // Changed from titleMedium to titleLarge
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8), // Spacing
                Text(
                  note.text, // Use full text, let Text widget handle overflow
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withAlpha((255 * 0.7).round()),
                      ),
                  maxLines: 5, // Limit lines for preview
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8), // Spacing
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withAlpha((255 * 0.6).round()),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
     .rotate(begin: -0.02, duration: 400.ms, curve: Curves.easeOut) // Subtle rotation
     .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut) // Slide from bottom slightly
     .fadeIn(duration: 400.ms, delay: 100.ms); // Fade in slightly delayed
  }
}