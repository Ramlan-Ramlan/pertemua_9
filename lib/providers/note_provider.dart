import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

class NoteProvider extends ChangeNotifier {
  static const String _storageKey = 'notes_v1';

  List<Note> _notes = [];
  String _query = '';
  int _nextIdSuffix = 0;

  List<Note> get notes {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return List.unmodifiable(_notes);
    }
    return List.unmodifiable(
      _notes.where(
        (note) =>
            note.title.toLowerCase().contains(normalizedQuery) ||
            note.content.toLowerCase().contains(normalizedQuery),
      ),
    );
  }

  int get totalCount => _notes.length;

  String get query => _query;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _notes = [];
    } else {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _notes = decoded
          .map((item) => Note.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_notes.map((note) => note.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> add(String title, String content) async {
    final now = DateTime.now();
    var id = now.microsecondsSinceEpoch.toString();
    while (_notes.any((note) => note.id == id)) {
      id = '${now.microsecondsSinceEpoch}_${_nextIdSuffix++}';
    }
    final note = Note(
      id: id,
      title: title,
      content: content,
      date: now,
    );
    _notes.insert(0, note);
    notifyListeners();
    await _save();
  }

  Future<void> update(String id, String title, String content) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) return;
    _notes[index] = _notes[index].copyWith(title: title, content: content);
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    final previousLength = _notes.length;
    _notes.removeWhere((note) => note.id == id);
    if (_notes.length == previousLength) return;
    notifyListeners();
    await _save();
  }

  Future<void> restore(Note note) async {
    if (_notes.any((existing) => existing.id == note.id)) return;
    final insertIndex =
        _notes.indexWhere((existing) => !existing.date.isAfter(note.date));
    if (insertIndex == -1) {
      _notes.add(note);
    } else {
      _notes.insert(insertIndex, note);
    }
    notifyListeners();
    await _save();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }
}

