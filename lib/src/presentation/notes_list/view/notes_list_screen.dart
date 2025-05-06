import 'dart:async'; // Import for Timer (debounce)

import 'package:easy_localization/easy_localization.dart'; // Import localization
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Add flutter_animate import
import '../../../core/routing/transitions.dart'; // Import custom transitions
import '../../../core/theme/bloc/theme_bloc.dart';
import '../../../domain/entities/note.dart';
import '../../../injection.dart';
import '../../note_edit/view/note_edit_screen.dart';
import '../bloc/notes_list_bloc.dart';
import '../../../core/utils/snackbar_utils.dart'; // Import global key
// Removed NoteListItem import, now imported via notes_list_content.dart
import '../widgets/notes_list_content.dart'; // Import extracted widget
import '../widgets/sort_options_bottom_sheet.dart'; // Import extracted widget

// Define the breakpoint for the two-pane layout
const double tabletBreakpoint = 720;

// Convert to StatefulWidget
class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  // Add state for selected note ID
  int? _selectedNoteId;
  // Keep track of the Bloc instance
  late final NotesListBloc _notesListBloc;
  // Controller for search field
  final TextEditingController _searchController = TextEditingController();
  // Timer for search debounce
  Timer? _debounce;
  // State for clear button visibility
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    // Fetch the Bloc instance from GetIt
    _notesListBloc = getIt<NotesListBloc>();
    // Initialize search controller text and clear button visibility
    final initialState = _notesListBloc.state;
    String initialQuery = '';
    if (initialState is NotesListLoaded) {
      initialQuery = initialState.searchQuery;
    }
    _searchController.text = initialQuery;
    _showClearButton = initialQuery.isNotEmpty; // Set initial visibility

    // Add listener for search input changes
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Search handler with debounce and clear button visibility update
  void _onSearchChanged() {
    // Update clear button visibility immediately
    if (_showClearButton != _searchController.text.isNotEmpty) {
      setState(() {
        _showClearButton = _searchController.text.isNotEmpty;
      });
    }

    // Debounce the BLoC event dispatch
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final currentState = _notesListBloc.state;
      final currentQuery = (currentState is NotesListLoaded) ? currentState.searchQuery : '';
      if (currentQuery != _searchController.text) {
         _notesListBloc.add(SearchQueryChanged(_searchController.text));
      }
    });
  }


  // Handler for tapping a note item
  void _handleNoteTap(Note note) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= tabletBreakpoint) {
      // Wide screen: Update selected ID in state
      setState(() {
        _selectedNoteId = note.id;
      });
    } else {
      // Narrow screen: Navigate to full edit screen using custom transition
      Navigator.of(context).push(
        buildSharedAxisTransitionRoute(NoteEditScreen(initialNoteId: note.id)),
      );
    }
  }

  // Handler for pressing the add note button
  void _handleAddNote() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= tabletBreakpoint) {
      // Wide screen: Set selected ID to null to show new note editor
      setState(() {
        _selectedNoteId = null;
      });
    } else {
      // Narrow screen: Navigate to full edit screen for a new note using custom transition
      Navigator.of(
        context,
      ).push(buildSharedAxisTransitionRoute(const NoteEditScreen()));
    }
  }

  // Method to show the sort options bottom sheet
  void _showSortOptions(BuildContext context) {
     // Use the context passed to the builder which is under the BlocProvider.value
    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider.value( // Provide the bloc instance to the sheet
        value: _notesListBloc,
        // Use the extracted widget
        child: const SortOptionsBottomSheet(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Define the main content widget (list/grid or two-pane) using BlocBuilder
    final Widget mainContentWidget = BlocBuilder<NotesListBloc, NotesListState>(
      builder: (context, state) {
        if (state is NotesListLoading) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        } else if (state is NotesListLoaded) {
          if (state.notes.isEmpty) {
            // Show empty state only if search query is also empty
            if (state.searchQuery.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 60,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'notesList.empty.title'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'notesList.empty.message'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            } else {
              // Show "No results" if search is active but notes are empty
               return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off, // Icon indicating no search results
                      size: 60,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'notesList.search.noResults'.tr(), // Needs translation key
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
          }
          // Use LayoutBuilder to determine layout based on width
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= tabletBreakpoint) {
                // Wide screen: Two-pane layout (Master-Detail)
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      // Use the extracted widget
                      child: NotesListContent(
                        notes: state.notes,
                        onNoteTap: _handleNoteTap,
                      ),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(
                      flex: 3,
                      child: NoteEditScreen(
                        key: ValueKey(_selectedNoteId),
                        initialNoteId: _selectedNoteId,
                      ),
                    ),
                  ],
                );
              } else {
                // Narrow screen: Show only the list/grid
                // Use the extracted widget
                return NotesListContent(
                  notes: state.notes,
                  onNoteTap: _handleNoteTap,
                );
              }
            },
          );
        } else if (state is NotesListError) {
          // Error state widget
          return Center(
            child: Text(
              'notes_list_error'.tr(args: [state.message]),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        } else {
          // Fallback for unknown state
          return const Center(child: Text('Unknown state'));
        }
      },
    );

    // Provide the Bloc instance and build the Scaffold
    return BlocProvider.value(
      value: _notesListBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('notesList.title'.tr()),
          actions: [
            // Sort Button - Use Builder to get context below BlocProvider.value
            Builder(
              builder: (buttonContext) => IconButton(
                tooltip: 'notesList.sort.tooltip'.tr(),
                icon: const Icon(Icons.sort),
                onPressed: () => _showSortOptions(buttonContext), // Pass correct context
              ),
            ),
            // Theme Toggle Button
            BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) {
                return IconButton(
                  tooltip: 'Toggle Theme',
                  onPressed: () {
                    context.read<ThemeBloc>().add(ToggleTheme());
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: RotationTransition(
                          turns: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      key: ValueKey(state.themeMode),
                      state.themeMode == ThemeMode.light
                          ? Icons.nightlight_round
                          : Icons.wb_sunny_outlined,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column( // Main body column
            children: [
              // Search Field
              Padding(
                // Match horizontal padding of the list content (20.0)
                padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'notesList.search.hint'.tr(), // Needs translation
                    prefixIcon: const Icon(Icons.search),
                    // Conditionally show clear button based on _showClearButton state
                    suffixIcon: _showClearButton
                        ? IconButton(
                            tooltip: 'notesList.search.clearTooltip'.tr(),
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear(); // Clears the text field
                              // Manually update state for immediate UI feedback
                              setState(() {
                                _showClearButton = false;
                              });
                              // Dispatch event immediately using the bloc instance
                              _notesListBloc.add(const SearchQueryChanged(''));
                              // Cancel any pending debounce timer
                              _debounce?.cancel();
                            },
                          )
                        : null, // Show nothing if text is empty
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                ),
              ),
              // List/Content Area (Expanded)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0), // Adjusted padding
                  // Listeners for Snackbar messages (Error and Undo)
                  child: BlocListener<NotesListBloc, NotesListState>(
                    listenWhen: (previous, current) =>
                        current is NotesListLoaded && current.errorMessage != null,
                    listener: (context, state) {
                      if (state is NotesListLoaded && state.errorMessage != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (scaffoldMessengerKey.currentState != null) {
                            scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                            scaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(content: Text(state.errorMessage!)),
                            );
                          }
                        });
                      }
                    },
                    child: BlocListener<NotesListBloc, NotesListState>(
                      listenWhen: (previous, current) =>
                          previous is NotesListLoaded &&
                          current is NotesListLoaded &&
                          previous.lastDeletedNote != current.lastDeletedNote &&
                          current.lastDeletedNote != null,
                      listener: (context, state) {
                        if (state is NotesListLoaded && state.lastDeletedNote != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (scaffoldMessengerKey.currentState != null) {
                              scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                              scaffoldMessengerKey.currentState?.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'notes_list_deleted'.tr(namedArgs: {'title': state.lastDeletedNote!.title}),
                                  ),
                                  action: SnackBarAction(
                                    label: 'undo'.tr(),
                                    onPressed: () {
                                      // Use context from listener which is below BlocProvider.value
                                      context.read<NotesListBloc>().add(UndoDeleteNote());
                                    },
                                  ),
                                ),
                              );
                            }
                          });
                        }
                      },
                      // The actual list/grid/two-pane content
                      child: mainContentWidget,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // FAB is a direct parameter of Scaffold
        floatingActionButton: MediaQuery.of(context).size.width < tabletBreakpoint
            ? FloatingActionButton(
                tooltip: 'notes_list_add_tooltip'.tr(),
                onPressed: _handleAddNote,
                shape: const CircleBorder(),
                child: const Icon(Icons.add_circle_outline),
              )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scaleXY(
                  end: 1.1,
                  duration: 600.ms,
                  curve: Curves.easeInOut,
                )
            : null,
      ),
    );
  }
}

// _NotesListContent and _SortOptionsBottomSheet have been moved to separate files
// in the widgets directory.
