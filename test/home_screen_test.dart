import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_counter_provider/main.dart';
import 'package:flutter_counter_provider/providers/note_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Alur tambah, edit, cari, hapus, dan urungkan catatan',
      (WidgetTester tester) async {
    final provider = NoteProvider();
    await provider.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MyApp(),
      ),
    );

    // Kondisi awal kosong
    expect(find.text('Catatan Harian'), findsOneWidget);
    expect(find.text('Belum ada catatan...'), findsOneWidget);

    // Tambah catatan baru
    await tester.tap(find.text('Tulis catatan'));
    await tester.pumpAndSettle();

    // Validasi form kosong
    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();
    expect(find.text('Judul tidak boleh kosong'), findsOneWidget);
    expect(find.text('Isi catatan tidak boleh kosong'), findsOneWidget);

    // Isi judul & konten lalu simpan
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Judul'),
      'Rapat Pagi',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Isi catatan'),
      'Bahas progres sprint 1',
    );
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.text('Rapat Pagi'), findsOneWidget);
    expect(find.text('Bahas progres sprint 1'), findsOneWidget);

    // Edit catatan melalui tombol Edit
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Judul'),
      'Rapat Pagi Diubah',
    );
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();
    expect(find.text('Rapat Pagi Diubah'), findsOneWidget);

    // Cari catatan tidak ditemukan lalu ditemukan
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();
    expect(find.text('Tidak ada catatan yang cocok.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'diubah');
    await tester.pump();
    expect(find.text('Rapat Pagi Diubah'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    // Hapus melalui tombol Hapus di daftar, lalu tekan Urungkan
    await tester.tap(find.byTooltip('Hapus'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan dihapus'), findsOneWidget);
    expect(find.text('Belum ada catatan...'), findsOneWidget);

    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();
    expect(find.text('Rapat Pagi Diubah'), findsOneWidget);

    // Hapus dari halaman Edit (dengan dialog konfirmasi) lalu Urungkan
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus Catatan?'), findsOneWidget);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan dihapus'), findsOneWidget);
    expect(find.text('Belum ada catatan...'), findsOneWidget);

    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();
    expect(find.text('Rapat Pagi Diubah'), findsOneWidget);

    // Geser ke kiri untuk hapus juga tetap berfungsi
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Catatan dihapus'), findsOneWidget);
    expect(find.text('Belum ada catatan...'), findsOneWidget);
  });
}
