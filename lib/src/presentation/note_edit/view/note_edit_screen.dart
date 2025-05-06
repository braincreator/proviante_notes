import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/note.dart';
import '../../../injection.dart';
import '../bloc/note_edit_bloc.dart'; // Imports Event and State via part files
import '../../../core/utils/snackbar_utils.dart'; // Import global key
import '../../notes_list/bloc/notes_list_bloc.dart' as list_bloc; // Import NotesListBloc with prefix
// Hide DeleteNote from notes_list_bloc to avoid name collision

class NoteEditScreen extends StatefulWidget {
  // Used for navigation from list (narrow screen)
  final Note? note;
  // Used when displaying in detail pane (wide screen)
  final int? initialNoteId;
  // Callbacks removed

  const NoteEditScreen({
    super.key,
    this.note,
    this.initialNoteId,
    // Callbacks removed
  }) : assert(
         note == null || initialNoteId == null,
         'Cannot provide both note and initialNoteId',
       ); // Ensure only one is provided

  // Helper method for navigation (used on narrow screens)
  // Note: Callbacks are typically not passed via static route methods
  // as they often depend on the calling widget's context/state.
  // They are more relevant when NoteEditScreen is used directly in a layout.
  static Route<void> route({Note? note}) {
    return MaterialPageRoute<void>(
      // Pass note for narrow screen navigation
      builder: (_) => NoteEditScreen(note: note),
    );
  }

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final NoteEditBloc _noteEditBloc = getIt<NoteEditBloc>();

  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _textFocusNode = FocusNode();

  // Updated getter for checking if it's a new note
  bool get _isNewNote => widget.note == null && widget.initialNoteId == null;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    // Load note based on provided parameter
    if (widget.initialNoteId != null) {
      // Load by ID if provided (for detail pane)
      _noteEditBloc.add(LoadNoteById(widget.initialNoteId!));
    } else {
      // Load from Note object or null (for navigation or new note)
      _noteEditBloc.add(LoadNoteToEdit(widget.note));
    }

    // Add listeners to controllers to update Bloc state on change
    _titleController.addListener(() {
      _noteEditBloc.add(TitleChanged(_titleController.text));
    });
    _textController.addListener(() {
      _noteEditBloc.add(TextChanged(_textController.text));
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _titleFocusNode.dispose();
    _textFocusNode.dispose();
    // Bloc is managed by GetIt, no need to close here if factory-provided
    super.dispose();
  }

  // Method to show discard confirmation dialog
  Future<bool> _onWillPop() async {
    if (_canPop ||
        !_noteEditBloc.state.isDirty(
          _titleController.text,
          _textController.text,
        )) {
      return true; // Allow pop if no changes or already confirmed
    }
    final shouldPop = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('note_edit_back_confirm'.tr()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Don't pop
                child: Text('common.cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Pop
                child: Text('discard'.tr()), // Assuming 'discard' key exists
              ),
            ],
          ),
    );
    return shouldPop ?? false;
  }

  // Method to handle saving the note
  void _saveNote(BuildContext context) {
    // Basic validation: Ensure title is not empty
    if (_titleController.text.trim().isEmpty) {
      // Use global key, separate calls
      scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('title_cannot_be_empty'.tr())));
      _titleFocusNode.requestFocus();
      return;
    }
    _noteEditBloc.add(SaveNote());
  }

  // Method to show delete confirmation dialog
  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    // Get BLoC and current state *before* async gap (showDialog)
    final bloc = context.read<NoteEditBloc>();
    final currentNoteId = bloc.state.initialNote?.id;

    // Don't show delete dialog if it's a new note or ID is missing
    if (currentNoteId == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            // Use different context name
            title: Text('note_delete_confirm_title'.tr()),
            content: Text('note_delete_confirm_body'.tr()),
            actions: <Widget>[
              TextButton(
                onPressed:
                    () => Navigator.of(context).pop(false), // Don't delete
                child: Text('common.cancel'.tr()),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.of(context).pop(true), // Delete
                child: Text('common.delete'.tr()),
              ),
            ],
          ),
    );

    if (shouldDelete == true && context.mounted) {
      // Check context.mounted after await
      // Add the DeleteNote event from NoteEditBloc
      bloc.add(DeleteNote(currentNoteId)); // Pass the ID
      // Navigation and Snackbar are handled by the BlocListener based on state changes
    }
  }

  // iOS delete action sheet removed, consolidated into _showDeleteConfirmationDialog

  // Builds the main content (form fields) - Now consistently Material
  Widget _buildBody(
    BuildContext context,
    NoteEditState state,
    bool isLoading,
    // TargetPlatform platform, // No longer needed
  ) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge;
    final hintColor = Theme.of(context).hintColor; // Use hintColor for placeholder

    // Padding is handled by InputDecoration contentPadding now
    // const cupertinoTitlePadding = EdgeInsets.symmetric(vertical: 12.0, horizontal: 0);
    // const cupertinoBodyPadding = EdgeInsets.symmetric(vertical: 12.0, horizontal: 0);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800), // Keep constraint
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(
            24.0, // Increased padding around the fields
          ), // Ensure padding around the column
          child: Column(
            children: [
              // --- Consistent Material Title Field ---
              TextFormField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: InputDecoration(
                  hintText: 'noteEdit.placeholder.title'.tr(), // Use hintText with translation
                  border: InputBorder.none, // Remove border
                  hintStyle: titleStyle?.copyWith(color: hintColor), // Style hint
                  contentPadding: const EdgeInsets.symmetric(vertical: 12.0), // Adjust padding
                ),
                style: titleStyle,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _textFocusNode.requestFocus(),
                enabled: !isLoading,
                maxLines: 1, // Ensure single line for title
              ),
              const SizedBox(height: 16.0), // Keep spacing
              // --- Consistent Material Body Field ---
              Expanded(
                child: TextFormField(
                  controller: _textController,
                  focusNode: _textFocusNode,
                  decoration: InputDecoration(
                    hintText: 'noteEdit.placeholder.content'.tr(), // Use hintText with translation
                    border: InputBorder.none, // Remove border
                    hintStyle: bodyStyle?.copyWith(color: hintColor), // Style hint
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0), // Adjust padding
                  ),
                  style: bodyStyle, // Apply body style
                  maxLines: null, // Allows multiple lines
                  expands: true, // Takes available space
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline, // Ensure multiline keyboard
                  enabled: !isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final platform = Theme.of(context).platform; // No longer needed

    // Provide the Bloc instance to the subtree
    return BlocProvider.value(
      value: _noteEditBloc,
      // Use PopScope for back navigation confirmation - applies to the whole screen
      child: PopScope(
        canPop: _canPop,
        onPopInvokedWithResult: (didPop, _) async {
          // Changed to onPopInvokedWithResult and added unused result parameter
          if (didPop) return;
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            setState(() {
              _canPop = true;
            }); // Allow pop
            Navigator.of(context).pop();
          }
        },
        child: BlocBuilder<NoteEditBloc, NoteEditState>(
          builder: (context, state) {
            // Use 'saving' status for delete operation as well
            final isLoading =
                state.status == NoteEditStatus.saving ||
                state.status == NoteEditStatus.loading;

            // Define the main body content builder here
            Widget buildMainContent(BuildContext scaffoldContext) {
              return BlocListener<NoteEditBloc, NoteEditState>(
                // Add listenWhen to trigger on status changes or specific error conditions
                listenWhen: (previous, current) {
                  // Trigger on status changes (success/failure) OR if error message appears on failure
                  return previous.status != current.status ||
                      (current.status == NoteEditStatus.failure &&
                          current.errorMessage != null);
                },
                listener: (context, state) { // Note: context here is from BlocListener, use scaffoldContext for ScaffoldMessenger
                  // Update text controllers if state changes externally (e.g., on load)
                  if (state.status == NoteEditStatus.loaded ||
                      state.status == NoteEditStatus.initial) {
                    // Check if controllers need update to avoid cursor jumps
                    if (_titleController.text != state.title) {
                      // Use selective update to preserve cursor position if possible
                      final currentSelection = _titleController.selection;
                      _titleController.text = state.title;
                      if (currentSelection.start <= _titleController.text.length &&
                          currentSelection.end <= _titleController.text.length) {
                        _titleController.selection = currentSelection;
                      }
                    }
                    if (_textController.text != state.text) {
                      final currentSelection = _textController.selection;
                      _textController.text = state.text;
                      if (currentSelection.start <= _textController.text.length &&
                          currentSelection.end <= _textController.text.length) {
                        _textController.selection = currentSelection;
                      }
                    }
                  }

                  // Handle save/delete success: show message and invoke callbacks
                  if (state.status == NoteEditStatus.success) {
                    // Check if the last event was the DeleteNote from NoteEditBloc
                    final bool isDelete = state.lastEvent is DeleteNote;

                    // --- Handle Delete Success ---
                    // Use initialNote as it represents the note that was just deleted
                    if (isDelete && state.initialNote != null) {
                      // Dispatch DeleteNote (from NotesListBloc) to show Snackbar with Undo
                      final notesListBloc = getIt<list_bloc.NotesListBloc>(); // Use prefix for type
                      notesListBloc.add(list_bloc.DeleteNote(state.initialNote!.id)); // Use initialNote!.id

                      // Allow popping
                      setState(() {
                        _canPop = true;
                      });
                      // Pop the screen immediately after delete confirmation
                      Navigator.of(context).pop();

                    }
                    // --- Handle Save Success ---
                    else if (!isDelete) {
                      final message = 'note_saved_success'.tr();
                      // Show save success message
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (scaffoldMessengerKey.currentState != null) {
                          scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                          scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
                        }
                      });

                      // Allow popping after success
                      setState(() {
                        _canPop = true;
                      });

                      // Pop if not in detail view
                      if (widget.initialNoteId == null) {
                        Navigator.of(context).pop();
                      }
                    }
                  }

                  // Handle save/delete failure: show error message from state
                  if (state.status == NoteEditStatus.failure &&
                      state.errorMessage != null) {
                    // Use global key
                    // Use global key, wrap in addPostFrameCallback
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (scaffoldMessengerKey.currentState != null) {
                        scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                        scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(state.errorMessage!)));
                      }
                    });
                  }
                },
                // The actual UI content
                // Pass the original context, as scaffoldContext is no longer needed
                // Pass context, state, isLoading. Platform no longer needed.
                child: _buildBody(context, state, isLoading),
              );
            }

            // Consistent Material UI for all platforms
            return Scaffold(
              appBar: AppBar(
                // Use maybePop for leading back button to respect PopScope
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back), // Material back icon
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.maybePop(context),
                ),
                title: Text(
                  _isNewNote
                      ? 'noteEdit.title.new'.tr()
                      : 'noteEdit.title.edit'.tr(),
                ),
                actions: [
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Center(
                        // Use adaptive indicator in AppBar as well
                        child: SizedBox(
                          width: 24, // Constrain size
                          height: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 3, // Adjust stroke if needed
                            // Consider adding valueColor if theme contrast is poor
                            // valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // Save Button
                    IconButton(
                      tooltip: 'common.save'.tr(),
                      icon: const Icon(Icons.done_outline), // Changed save icon again
                      onPressed: () => _saveNote(context),
                    ),
                    // Delete Button (conditionally shown)
                    if (!_isNewNote)
                      IconButton(
                        tooltip: 'common.delete'.tr(),
                        icon: const Icon(Icons.delete_outline), // Updated delete icon
                        onPressed: () => _showDeleteConfirmationDialog(context),
                      ),
                  ],
                ],
              ),
              // Wrap body in SafeArea
              body: SafeArea(
                // Pass the original context to the main content builder
                child: buildMainContent(context),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Helper extension to check if the current state is dirty
extension NoteEditStateX on NoteEditState {
  bool isDirty(String currentTitle, String currentText) {
    // Handle initial state where initialNote might be null briefly
    if (status == NoteEditStatus.initial ||
        status == NoteEditStatus.loading ||
        initialNote == null) {
      // If it's a new note being created, any text means it's dirty
      if (initialNote == null &&
          (currentTitle.isNotEmpty || currentText.isNotEmpty)) {
        return true;
      }
      return false; // Not dirty if loading or truly initial state with no changes
    }
    // Compare against the initial note data loaded into the state
    return initialNote!.title != currentTitle ||
        initialNote!.text != currentText;
  }
}
