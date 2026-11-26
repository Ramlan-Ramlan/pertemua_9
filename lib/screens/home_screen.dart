import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/note_provider.dart';
import '../utils/date_format.dart';
import 'note_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openNoteForm(BuildContext context, [Note? note]) async {
    final deletedNote = await Navigator.of(context).push<Note?>(
      MaterialPageRoute<Note?>(
        builder: (_) => NoteFormScreen(note: note),
      ),
    );
    if (deletedNote != null && context.mounted) {
      _showDeletedSnackBar(context, deletedNote);
    }
  }

  void _deleteNote(BuildContext context, Note note) {
    context.read<NoteProvider>().remove(note.id);
    _showDeletedSnackBar(context, note);
  }

  void _showDeletedSnackBar(BuildContext context, Note note) {
    final noteProvider = context.read<NoteProvider>();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Catatan dihapus'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () {
              noteProvider.restore(note);
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Harian'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (value) =>
                  context.read<NoteProvider>().setQuery(value),
              decoration: const InputDecoration(
                hintText: 'Cari catatan...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: Consumer<NoteProvider>(
              builder: (context, provider, child) {
                if (provider.totalCount == 0) {
                  return const Center(
                    child: Text('Belum ada catatan...'),
                  );
                }

                final notes = provider.notes;
                if (notes.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada catatan yang cocok.'),
                  );
                }

                return ListView.separated(
                  itemCount: notes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Dismissible(
                      key: ValueKey(note.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                      onDismissed: (_) => _deleteNote(context, note),
                      child: ListTile(
                        title: Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatTanggal(note.date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _openNoteForm(context, note),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Hapus',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _deleteNote(context, note),
                            ),
                          ],
                        ),
                        onTap: () => _openNoteForm(context, note),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteForm(context),
        icon: const Icon(Icons.edit),
        label: const Text('Tulis catatan'),
      ),
    );
  }
}
