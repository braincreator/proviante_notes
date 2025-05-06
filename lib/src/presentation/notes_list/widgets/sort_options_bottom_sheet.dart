import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/note_sort_option.dart';
import '../bloc/notes_list_bloc.dart';

// Extracted Widget for the Sort Options Modal Bottom Sheet
class SortOptionsBottomSheet extends StatelessWidget {
  const SortOptionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the bloc state to get the current sort option
    final currentState = context.watch<NotesListBloc>().state;
    final currentSortOption = (currentState is NotesListLoaded)
        ? currentState.sortOption
        : NoteSortOption.dateModifiedDescending; // Default fallback

    // Add some vertical padding and ensure safe area for notches/gestures
    return Padding(
      padding: EdgeInsets.only(
        top: 8.0, // Space for drag handle
        left: 16.0,
        right: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0, // Adjust for keyboard + padding
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withAlpha((255*0.4).round()),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16), // Space after handle
          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0), // Padding below title
            child: Text(
              'notesList.sort.tooltip'.tr(), // Use tooltip as title
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          // Options List
          ListView(
            shrinkWrap: true,
            children: NoteSortOption.values.map((option) {
              return RadioListTile<NoteSortOption>(
                title: Text(option.displayName),
                value: option,
                groupValue: currentSortOption,
                activeColor: Theme.of(context).colorScheme.primary, // Use primary color
                shape: RoundedRectangleBorder( // Add rounded corners
                  borderRadius: BorderRadius.circular(8.0),
                ),
                visualDensity: VisualDensity.compact, // Make tiles denser
                onChanged: (NoteSortOption? value) {
                  if (value != null && value != currentSortOption) {
                    context.read<NotesListBloc>().add(SortOptionChanged(value));
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
          // No extra SizedBox needed at the bottom due to main padding
        ],
      ),
    );
  }
}