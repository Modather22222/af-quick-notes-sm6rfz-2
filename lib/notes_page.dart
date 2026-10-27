import 'dart:async';

import 'package:flutter/material.dart';

import 'note.dart';
import 'notes_store.dart';

/// Single screen: an always-on-top editor that autosaves as you type, plus
/// the list of past notes.
class NotesPage extends StatefulWidget {
  const NotesPage({super.key, required this.store});

  final NotesStore store;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _editor = TextEditingController();

  /// Last text the editor sent to the store; lets us tell user typing apart
  /// from store-driven changes (e.g. loading another note to edit).
  String _lastSent = '';

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_syncEditor);
    unawaited(widget.store.load());
  }

  @override
  void dispose() {
    widget.store.removeListener(_syncEditor);
    _editor.dispose();
    super.dispose();
  }

  void _syncEditor() {
    final String text = widget.store.activeText;
    if (text != _editor.text && text != _lastSent) {
      _editor.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _onChanged(String value) {
    _lastSent = value;
    widget.store.onTextChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final NotesStore store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (BuildContext context, _) {
        final String? editingId = store.editingNote?.id;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Quick Notes'),
            actions: [
              IconButton(
                tooltip: 'Start a new note',
                icon: const Icon(Icons.post_add),
                onPressed: store.startNewNote,
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _editor,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: editingId == null
                        ? 'Start typing a new note…'
                        : 'Update note…',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.edit_note),
                  ),
                  onChanged: _onChanged,
                ),
              ),
              if (store.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Saved notes',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              Expanded(child: _buildNotesList(context, store, editingId)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotesList(
      BuildContext context, NotesStore store, String? editingId) {
    final List<Note> notes = store.notes;
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sticky_note_2_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No notes yet. Start typing above to create one.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 16),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Note note = notes[index];
        final bool isEditing = note.id == editingId;
        return ListTile(
          selected: isEditing,
          leading: Icon(
            isEditing ? Icons.edit : Icons.sticky_note_2_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            note.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text('Edited ${_formatDate(note.updatedAt)}'),
          onTap: () => store.editNote(note.id),
          trailing: IconButton(
            tooltip: 'Delete note',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => store.deleteNote(note.id),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime time) {
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${pad(time.month)}-${pad(time.day)} '
        '${pad(time.hour)}:${pad(time.minute)}';
  }
}
