// ============================================================
// FILE: test/screens/note_form_test.dart
// #Test #WidgetTest — Menguji halaman form tambah & edit.
//
// Yang diuji:
//   - form kosong menampilkan pesan validasi
//   - judul saja terisi masih ditolak (isi wajib diisi)
//   - isian lengkap tersimpan ke storage
//   - mode edit mengisi kolom dengan data lama
//   - mode edit menyimpan perubahan tanpa membuat catatan baru
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:catatan_harian/models/note.dart';
import 'package:catatan_harian/screens/note_form_screen.dart';
import 'package:catatan_harian/services/note_storage.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  NoteStorage buatStorage() => NoteStorage(preferensi: SharedPreferencesAsync());

  // #Helper #Bungkus — Membungkus halaman dalam MaterialApp.
  // ScaffoldMessenger dan Navigator butuh MaterialApp di atasnya.
  Widget bungkus(Widget child) => MaterialApp(home: child);

  // #Helper #CariKolom — Mencari kolom input berdasarkan label.
  //
  // `find.widgetWithText` mencari widget bertipe tertentu yang berisi
  // teks tertentu. Dipakai karena kita tidak punya key pada TextFormField.
  Finder kolom(String label) => find.widgetWithText(TextFormField, label);

  group('NoteFormScreen - mode tambah', () {
    // #Test #ValidasiKosong — Menekan Simpan tanpa mengisi apa pun
    // harus menampilkan pesan error, bukan menyimpan.
    testWidgets('menampilkan pesan validasi saat form kosong', (tester) async {
      final storage = buatStorage();

      await tester.pumpWidget(bungkus(NoteFormScreen(storage: storage)));
      await tester.pumpAndSettle();

      // #Langkah #TekanSimpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // #Assert #PesanError — Kedua kolom menampilkan pesan masing-masing.
      expect(find.text('Judul tidak boleh kosong'), findsOneWidget);
      expect(find.text('Isi catatan tidak boleh kosong'), findsOneWidget);

      // #Assert #TidakTersimpan — Storage harus tetap kosong.
      final isi = await storage.muatSemua();
      expect(isi, isEmpty);
    });

    // #Test #HanyaJudul — Mengisi judul saja belum cukup.
    testWidgets('menolak simpan jika hanya judul yang diisi', (tester) async {
      final storage = buatStorage();

      await tester.pumpWidget(bungkus(NoteFormScreen(storage: storage)));
      await tester.pumpAndSettle();

      await tester.enterText(kolom('Judul'), 'Hanya Judul');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Isi catatan tidak boleh kosong'), findsOneWidget);

      final isi = await storage.muatSemua();
      expect(isi, isEmpty);
    });

    // #Test #SimpanBerhasil — Isian lengkap harus tersimpan.
    testWidgets('menyimpan catatan saat form diisi lengkap', (tester) async {
      final storage = buatStorage();

      await tester.pumpWidget(bungkus(NoteFormScreen(storage: storage)));
      await tester.pumpAndSettle();

      // #Langkah #IsiForm
      await tester.enterText(kolom('Judul'), 'Belanja Bulanan');
      await tester.enterText(kolom('Isi catatan'), 'Beras, telur, minyak');

      // #Langkah #Simpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // #Assert #Tersimpan
      final isi = await storage.muatSemua();
      expect(isi.length, 1);
      expect(isi.first.judul, 'Belanja Bulanan');
      expect(isi.first.isi, 'Beras, telur, minyak');
    });

    // #Test #TrimSpasi — Spasi berlebih di awal/akhir harus dibuang.
    // Tanpa trim, "  Belanja  " akan tersimpan dengan spasi aneh.
    testWidgets('membuang spasi berlebih di awal dan akhir', (tester) async {
      final storage = buatStorage();

      await tester.pumpWidget(bungkus(NoteFormScreen(storage: storage)));
      await tester.pumpAndSettle();

      await tester.enterText(kolom('Judul'), '   Judul Dengan Spasi   ');
      await tester.enterText(kolom('Isi catatan'), '   isi   ');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      final isi = await storage.muatSemua();
      expect(isi.first.judul, 'Judul Dengan Spasi');
      expect(isi.first.isi, 'isi');
    });

    // #Test #JudulTerlaluPanjang — Batas 100 karakter ditegakkan.
    testWidgets('menolak judul lebih dari 100 karakter', (tester) async {
      final storage = buatStorage();

      await tester.pumpWidget(bungkus(NoteFormScreen(storage: storage)));
      await tester.pumpAndSettle();

      // #Langkah #BuatTeksPanjang — 'A' diulang 101 kali.
      await tester.enterText(kolom('Judul'), 'A' * 101);
      await tester.enterText(kolom('Isi catatan'), 'isi');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Judul maksimal 100 karakter'), findsOneWidget);
    });
  });

  group('NoteFormScreen - mode edit', () {
    // #Test #IsiAwal — Kolom harus terisi data lama, dan judul AppBar berubah.
    testWidgets('mengisi kolom dengan data catatan lama', (tester) async {
      final catatan = Note(
        id: 'abc',
        judul: 'Judul Lama',
        isi: 'Isi lama',
        dibuatPada: DateTime(2026, 1, 1),
        diubahPada: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        bungkus(NoteFormScreen(catatanAwal: catatan, storage: buatStorage())),
      );
      await tester.pumpAndSettle();

      // #Assert #JudulAppBar — Mode edit punya judul berbeda.
      expect(find.text('Edit Catatan'), findsOneWidget);

      // #Assert #IsiKolom — Teks lama muncul di dalam kolom.
      expect(find.text('Judul Lama'), findsOneWidget);
      expect(find.text('Isi lama'), findsOneWidget);
    });

    // #Test #SimpanPerubahan — Mengubah judul tidak boleh membuat
    // catatan baru; jumlah catatan harus tetap 1.
    testWidgets('menyimpan perubahan tanpa membuat catatan baru', (tester) async {
      final storage = buatStorage();

      // #Langkah #Siapkan — Simpan satu catatan dulu.
      final asli = Note.baru(judul: 'Judul Lama', isi: 'Isi lama');
      await storage.tambah(asli);

      await tester.pumpWidget(
        bungkus(NoteFormScreen(catatanAwal: asli, storage: storage)),
      );
      await tester.pumpAndSettle();

      // #Langkah #UbahJudul — Ganti isi kolom judul.
      await tester.enterText(kolom('Judul'), 'Judul Baru');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // #Assert #TetapSatu — Tidak ada duplikat.
      final isi = await storage.muatSemua();
      expect(isi.length, 1);

      // #Assert #JudulBerubah #IdTetap
      expect(isi.first.judul, 'Judul Baru');
      expect(isi.first.isi, 'Isi lama'); // tidak diubah
      expect(isi.first.id, asli.id);     // id tidak berubah
    });

    // #Test #TanggalDiubah — Setelah disunting, tanggal "diubah" harus lebih baru
    // daripada tanggal "dibuat".
    testWidgets('memperbarui tanggal diubah setelah menyunting', (tester) async {
      final storage = buatStorage();

      final asli = Note(
        id: 'abc',
        judul: 'Judul',
        isi: 'Isi',
        dibuatPada: DateTime(2020, 1, 1),
        diubahPada: DateTime(2020, 1, 1),
      );
      await storage.simpanSemua([asli]);

      await tester.pumpWidget(
        bungkus(NoteFormScreen(catatanAwal: asli, storage: storage)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(kolom('Isi catatan'), 'Isi yang sudah diubah');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      final isi = await storage.muatSemua();
      expect(isi.first.isi, 'Isi yang sudah diubah');
      expect(isi.first.dibuatPada, DateTime(2020, 1, 1)); // tetap
      expect(isi.first.diubahPada.isAfter(DateTime(2020, 1, 1)), isTrue);
    });
  });
}
