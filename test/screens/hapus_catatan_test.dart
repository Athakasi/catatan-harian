// ============================================================
// FILE: test/screens/hapus_catatan_test.dart
// #Test #WidgetTest — Menguji fitur hapus catatan.
//
// Yang diuji:
//   - tombol hapus ada di setiap kartu
//   - menekan tombol hapus memunculkan dialog konfirmasi
//   - menekan Batal TIDAK menghapus apa pun
//   - menekan Hapus benar-benar menghapus dari storage
//   - setelah dihapus, empty state muncul lagi
//   - menghapus satu dari beberapa catatan tidak mengganggu yang lain
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:catatan_harian/models/note.dart';
import 'package:catatan_harian/screens/note_list_screen.dart';
import 'package:catatan_harian/services/note_storage.dart';
import 'package:catatan_harian/widgets/note_card.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  NoteStorage buatStorage() => NoteStorage(preferensi: SharedPreferencesAsync());

  // #Helper #SiapkanHalaman — Menyiapkan halaman daftar dengan data contoh.
  //
  // Mengembalikan storage agar test bisa memeriksa isinya setelah aksi.
  Future<NoteStorage> siapkan(
    WidgetTester tester, {
    List<String> judul = const ['Catatan A'],
  }) async {
    final storage = buatStorage();
    for (final j in judul) {
      await storage.tambah(Note.baru(judul: j, isi: 'isi $j'));
    }

    await tester.pumpWidget(
      MaterialApp(home: NoteListScreen(storage: storage)),
    );
    await tester.pumpAndSettle();

    return storage;
  }

  group('Fitur hapus catatan', () {
    // #Test #TombolAda — Setiap kartu punya tombol hapus.
    testWidgets('setiap kartu menampilkan tombol hapus', (tester) async {
      await siapkan(tester, judul: ['Catatan A', 'Catatan B']);

      // #Assert #JumlahKartu
      expect(find.byType(NoteCard), findsNWidgets(2));

      // #Assert #JumlahTombolHapus — Harus sama dengan jumlah kartu.
      expect(find.byTooltip('Hapus catatan'), findsNWidgets(2));
    });

    // #Test #DialogMuncul — Menekan tombol hapus memunculkan konfirmasi.
    testWidgets('menekan tombol hapus memunculkan dialog konfirmasi', (tester) async {
      await siapkan(tester);

      await tester.tap(find.byTooltip('Hapus catatan').first);
      await tester.pumpAndSettle();

      // #Assert #DialogTerlihat
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Hapus catatan?'), findsOneWidget);

      // #Assert #JudulDisebut — Dialog harus menyebut catatan mana
      // yang akan dihapus, agar pengguna tidak salah hapus.
      expect(find.textContaining('Catatan A'), findsWidgets);

      // #Assert #PeringatanPermanen — Pengguna harus tahu ini tidak bisa dibatalkan.
      expect(find.textContaining('tidak bisa dibatalkan'), findsOneWidget);
    });

    // #Test #BatalTidakMenghapus — Ini test paling penting.
    //
    // Tanpa test ini, mudah terjadi bug: dialog muncul, pengguna tekan
    // Batal, tapi data tetap terhapus.
    testWidgets('menekan Batal tidak menghapus catatan', (tester) async {
      final storage = await siapkan(tester);

      await tester.tap(find.byTooltip('Hapus catatan').first);
      await tester.pumpAndSettle();

      // #Langkah #TekanBatal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // #Assert #DialogTertutup
      expect(find.byType(AlertDialog), findsNothing);

      // #Assert #MasihTampil — Kartu masih ada di layar.
      expect(find.text('Catatan A'), findsOneWidget);

      // #Assert #MasihTersimpan — Dan masih ada di storage.
      final isi = await storage.muatSemua();
      expect(isi.length, 1);
    });

    // #Test #HapusBerhasil — Menekan Hapus benar-benar menghapus.
    testWidgets('menekan Hapus menghapus catatan dari storage', (tester) async {
      final storage = await siapkan(tester);

      await tester.tap(find.byTooltip('Hapus catatan').first);
      await tester.pumpAndSettle();

      // #Langkah #TekanHapus — Tombol di dalam dialog.
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();

      // #Assert #HilangDariStorage
      final isi = await storage.muatSemua();
      expect(isi, isEmpty);

      // #Assert #HilangDariLayar
      expect(find.text('Catatan A'), findsNothing);

      // #Assert #EmptyStateMuncul — Karena sudah tidak ada catatan.
      expect(find.text('Belum ada catatan'), findsOneWidget);
    });

    // #Test #SnackBar — Setelah menghapus, pengguna diberi tahu.
    testWidgets('menampilkan SnackBar setelah berhasil menghapus', (tester) async {
      await siapkan(tester);

      await tester.tap(find.byTooltip('Hapus catatan').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));

      // #Langkah #Pump — Jangan pumpAndSettle langsung, karena SnackBar
      // punya durasi tampil dan kita ingin menangkapnya.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('dihapus'), findsOneWidget);
    });

    // #Test #HanyaSatu — Menghapus satu catatan tidak boleh mengganggu
    // catatan lain. Ini menguji bahwa kita mencari berdasarkan id,
    // bukan berdasarkan posisi.
    testWidgets('menghapus satu catatan tidak menghapus yang lain', (tester) async {
      final storage = await siapkan(tester, judul: ['Pertama', 'Kedua', 'Ketiga']);

      // #Langkah #HapusKedua — Cari kartu berjudul "Kedua", lalu tekan
      // tombol hapus DI DALAM kartu itu.
      //
      // `find.descendant` mencari widget di dalam widget lain.
      // Ini cara tepat: kita tidak mau sembarang tombol hapus,
      // tapi tombol hapus milik kartu "Kedua".
      final kartuKedua = find.ancestor(
        of: find.text('Kedua'),
        matching: find.byType(NoteCard),
      );
      final tombolHapus = find.descendant(
        of: kartuKedua,
        matching: find.byTooltip('Hapus catatan'),
      );

      await tester.tap(tombolHapus);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();

      // #Assert #SisaDua
      final isi = await storage.muatSemua();
      expect(isi.length, 2);

      // #Assert #YangBenarTerhapus — "Kedua" hilang, lainnya tetap.
      final judulSisa = isi.map((n) => n.judul).toSet();
      expect(judulSisa, contains('Pertama'));
      expect(judulSisa, contains('Ketiga'));
      expect(judulSisa, isNot(contains('Kedua')));

      // #Assert #TampilanBenar
      expect(find.text('Pertama'), findsOneWidget);
      expect(find.text('Kedua'), findsNothing);
      expect(find.text('Ketiga'), findsOneWidget);
    });

    // #Test #TidakBisaDismiss — Dialog sengaja tidak bisa ditutup dengan
    // menyentuh area luar, agar pengguna tidak bingung.
    //
    // Kita verifikasi lewat perilaku: menekan area luar tidak menutup dialog.
    testWidgets('dialog tidak tertutup saat area luar disentuh', (tester) async {
      await siapkan(tester);

      await tester.tap(find.byTooltip('Hapus catatan').first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // #Langkah #SentuhLuar — Tekan pojok kiri atas, jauh dari dialog.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      // #Assert #DialogMasihAda — barrierDismissible: false bekerja.
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
