import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'note.dart';

/// In-memory note state that mirrors itself into local storage.
///
/// The UI calls [onTextChanged] on every keystroke; writes to disk are
/// debounced so saving never blocks typing.
class NotesStore extends ChangeNotifier {
  NotesStore({Duration saveDelay = const Duration(milliseconds: 500)})
      : _saveDelay = saveDelay;

  static const String _storageKey = 'quick_notes.v1';

  final Duration _saveDelay;
  final List<Note> _notes = <Note>[];
  Timer? _saveTimer;
  int _idCounter = 0;
  bool _loaded = false;
  String? _editingId;

  /// All notes, newest first.
  List<Note> get notes => List.unmodifiable(_notes);

  /// True once local storage has been read.
  bool get isLoaded => _loaded;

  /// The note currently loaded in the editor, if any.
  Note? get editingNote {
    final String? id = _editingId;
    if (id == null) return null;
    for (final Note note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  /// Text the editor should display right now.
  String get activeText => editingNote?.text ?? '';

  /// Reads saved notes from local storage. Safe to call multiple times.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        _notes
          ..clear()
          ..addAll(Note.decodeList(raw));
        _sortNotes();
      }
    } catch (_) {
      // Unreadable data: start fresh instead of crashing.
      _notes.clear();
    }
    notifyListeners();
  }

  /// Called on every keystroke. Creates or updates the active note and
  /// schedules a debounced save. Clearing the text removes the active note.
  void onTextChanged(String text) {
    var changed = false;
    if (text.trim().isEmpty) {
      final Note? note = editingNote;
      if (note != null) {
        _notes.remove(note);
        _editingId = null;
        changed = true;
      }
    } else {
      final Note? note = editingNote;
      if (note == null) {
        final Note created = _createNote(text);
        _editingId = created.id;
        changed = true;
      } else if (text != note.text) {
        note
          ..text = text
          ..updatedAt = DateTime.now();
        _sortNotes();
        changed = true;
      }
    }
    if (changed) {
      _scheduleSave();
      notifyListeners();
    }
  }

  /// Loads [id] into the editor for editing.
  void editNote(String id) {
    if (_editingId == id) return;
    _editingId = id;
    notifyListeners();
  }

  /// Clears the editor so the next keystroke starts a new note.
  void startNewNote() {
    _editingId = null;
    notifyListeners();
  }

  /// Removes a note permanently.
  void deleteNote(String id) {
    final int before = _notes.length;
    _notes.removeWhere((Note note) => note.id == id);
    if (_notes.length == before) return;
    if (_editingId == id) _editingId = null;
    _scheduleSave(immediate: true);
    notifyListeners();
  }

  Note _createNote(String text) {
    final DateTime now = DateTime.now();
    final Note note = Note(
      id: 'note-${now.microsecondsSinceEpoch}-${_idCounter++}',
      text: text,
      updatedAt: now,
    );
    _notes.insert(0, note);
    return note;
  }

  void _sortNotes() {
    _notes.sort((Note a, Note b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void _scheduleSave({bool immediate = false}) {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (immediate) {
      unawaited(_persist());
    } else {
      _saveTimer = Timer(_saveDelay, _persist);
    }
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (_notes.isEmpty) {
        await prefs.remove(_storageKey);
      } else {
        await prefs.setString(_storageKey, Note.encodeList(_notes));
      }
    } catch (_) {
      // Persistence is best-effort; the app keeps working in memory.
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    unawaited(_persist());
    super.dispose();
  }
}
