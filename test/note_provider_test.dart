import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_counter_provider/providers/note_provider.dart';
import 'package:flutter_counter_provider/utils/date_format.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NoteProvider', () {
    test('add menambahkan catatan baru di urutan teratas dan memanggil listener',
        () async {
      final provider = NoteProvider();
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.add('Catatan Pertama', 'Isi pertama');
      await provider.add('Catatan Kedua', 'Isi kedua');

      expect(provider.totalCount, 2);
      expect(provider.notes.length, 2);
      expect(provider.notes.first.title, 'Catatan Kedua');
      expect(provider.notes.last.title, 'Catatan Pertama');
      expect(notifyCount, 2);
    });

    test('update mengubah judul dan isi catatan yang sesuai', () async {
      final provider = NoteProvider();
      await provider.add('Judul Awal', 'Konten awal');
      final id = provider.notes.first.id;

      await provider.update(id, 'Judul Baru', 'Konten baru');

      expect(provider.notes.first.title, 'Judul Baru');
      expect(provider.notes.first.content, 'Konten baru');
      expect(provider.totalCount, 1);
    });

    test('remove menghapus catatan dan restore mengembalikannya', () async {
      final provider = NoteProvider();
      await provider.add('Belanja', 'Beli kopi dan gula');
      final removedNote = provider.notes.first;

      await provider.remove(removedNote.id);
      expect(provider.totalCount, 0);
      expect(provider.notes, isEmpty);

      await provider.restore(removedNote);
      expect(provider.totalCount, 1);
      expect(provider.notes.first.id, removedNote.id);
      expect(provider.notes.first.title, 'Belanja');
    });

    test('setQuery memfilter judul dan isi secara tidak case-sensitive',
        () async {
      final provider = NoteProvider();
      await provider.add('Belajar Flutter', 'State management Provider');
      await provider.add('Resep Masakan', 'Nasi goreng spesial');

      provider.setQuery('FLUTTER');
      expect(provider.query, 'FLUTTER');
      expect(provider.notes.length, 1);
      expect(provider.notes.first.title, 'Belajar Flutter');

      provider.setQuery('provider');
      expect(provider.notes.length, 1);
      expect(provider.notes.first.title, 'Belajar Flutter');

      provider.setQuery('nasi');
      expect(provider.notes.length, 1);
      expect(provider.notes.first.title, 'Resep Masakan');

      provider.setQuery('tidak ada');
      expect(provider.notes, isEmpty);
      expect(provider.totalCount, 2);

      provider.setQuery('');
      expect(provider.notes.length, 2);
    });

    test('persistensi: add lalu NoteProvider baru memanggil load()', () async {
      final provider1 = NoteProvider();
      await provider1.add('Persistensi', 'Data tersimpan di SharedPreferences');

      final provider2 = NoteProvider();
      await provider2.load();

      expect(provider2.totalCount, 1);
      expect(provider2.notes.first.title, 'Persistensi');
      expect(
        provider2.notes.first.content,
        'Data tersimpan di SharedPreferences',
      );
    });
  });

  group('formatTanggal', () {
    test('memformat tanggal ke bahasa Indonesia', () {
      expect(formatTanggal(DateTime(2026, 11, 26)), '26 November 2026');
      expect(formatTanggal(DateTime(2026, 1, 5)), '5 Januari 2026');
    });
  });
}

