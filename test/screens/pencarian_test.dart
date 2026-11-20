// ============================================================
// FILE: test/screens/pencarian_test.dart
// #Test #WidgetTest — Menguji fitur pencarian catatan.
//
// Yang diuji:
//   - tombol cari muncul dan membuka mode pencarian
//   - mencari berdasarkan judul
//   - mencari berdasarkan isi (bukan hanya judul)
//   - pencarian tidak membedakan huruf besar/kecil
//   - hasil kosong menampilkan pesan khusus (bukan "Belum ada catatan")
//   - tombol bersihkan mengembalikan semua catatan
//   - tombol tutup keluar dari mode pencarian
//   - tombol cari nonaktif saat daftar kosong
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:catatan_harian/models/note.dart';
import 'package:catatan_harian/screens/note_list_screen.dart';
import 'package:catatan_harian/services/note_storage.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  NoteStorage buatStorage() => NoteStorage(preferensi: SharedPreferencesAsync());

  // #Helper #Siapkan — Menyiapkan halaman dengan data contoh.
  Future<NoteStorage> siapkan(
    WidgetTester tester, {
    List<List<String>> data = const [
      ['Belanja Bulanan', 'Beras 5kg, telur 1kg, minyak goreng'],
      ['Rencana Belajar', 'Selesaikan fitur pencarian di Flutter'],
      ['Ide Aplikasi', 'Aplikasi pencatat pengeluaran harian'],
    ],
  }) async {
    final storage = buatStorage();
    for (final d in data) {
      await storage.tambah(Note.baru(judul: d[0], isi: d[1]));
    }

    await tester.pumpWidget(
      MaterialApp(home: NoteListScreen(storage: storage)),
    );
    await tester.pumpAndSettle();

    return storage;
  }

  // #Helper #BukaPencarian — Menekan tombol cari di AppBar.
  Future<void> bukaPencarian(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Cari catatan'));
    await tester.pumpAndSettle();
  }

  // #Helper #KotakPencarian — Menemukan TextField di dalam AppBar.
  //
  // Dibuat sebagai FUNGSI (bukan variabel), karena `find.` harus
  // dijalankan ulang setiap kali dipanggil — pohon widget bisa berubah.
  Finder kotakPencarian() => find.descendant(
    of: find.byType(AppBar),
    matching: find.byType(TextField),
  );

  group('Fitur pencarian', () {
    // #Test #TombolAda — Tombol cari muncul saat daftar berisi data.
    testWidgets('tombol cari tersedia saat ada catatan', (tester) async {
      await siapkan(tester);

      expect(find.byTooltip('Cari catatan'), findsOneWidget);
    });

    // #Test #NonaktifSaatKosong — Tidak ada gunanya mencari di daftar kosong.
    testWidgets('tombol cari nonaktif saat belum ada catatan', (tester) async {
      await siapkan(tester, data: []);

      // #Assert #TombolAdaTapiMati — Tombolnya masih ada di pohon widget,
      // tapi onPressed-nya null sehingga tidak bisa ditekan.
      final tombol = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.search),
          matching: find.byType(IconButton),
        ),
      );

      expect(tombol.onPressed, isNull);
    });

    // #Test #BukaMode — Menekan tombol cari mengubah AppBar.
    testWidgets('menekan tombol cari membuka kotak pencarian', (tester) async {
      await siapkan(tester);

      // #Assert #Sebelum — Judul biasa tampil.
      expect(find.text('Catatan Harian'), findsOneWidget);
      expect(kotakPencarian(), findsNothing);

      await bukaPencarian(tester);

      // #Assert #Sesudah — Judul berganti kotak pencarian.
      expect(kotakPencarian(), findsOneWidget);
      expect(find.text('Catatan Harian'), findsNothing);

      // #Assert #HintTampil — Petunjuk penggunaan terlihat.
      expect(find.textContaining('Cari judul atau isi'), findsOneWidget);
    });

    // #Test #CariJudul — Mengetik kata kunci menyaring berdasarkan judul.
    testWidgets('mencari berdasarkan judul menyaring daftar', (tester) async {
      await siapkan(tester);
      await bukaPencarian(tester);

      await tester.enterText(kotakPencarian(), 'Belanja');
      await tester.pumpAndSettle();

      // #Assert #Cocok
      expect(find.text('Belanja Bulanan'), findsOneWidget);

      // #Assert #TidakCocok — Yang lain hilang dari layar.
      expect(find.text('Rencana Belajar'), findsNothing);
      expect(find.text('Ide Aplikasi'), findsNothing);
    });

    // #Test #CariIsi — Pencarian juga menelusuri ISI, bukan hanya judul.
    //
    // Ini penting: pengguna sering mengingat potongan kalimat,
    // bukan judulnya.
    testWidgets('mencari berdasarkan isi catatan', (tester) async {
      await siapkan(tester);
      await bukaPencarian(tester);

      // "beras" hanya ada di ISI catatan "Belanja Bulanan",
      // tidak ada di judul mana pun.
      await tester.enterText(kotakPencarian(), 'beras');
      await tester.pumpAndSettle();

      expect(find.text('Belanja Bulanan'), findsOneWidget);
      expect(find.text('Rencana Belajar'), findsNothing);
    });

    // #Test #TidakCaseSensitive — "BELANJA" harus menemukan "Belanja".
    testWidgets('pencarian tidak membedakan huruf besar dan kecil', (tester) async {
      await siapkan(tester);
      await bukaPencarian(tester);

      await tester.enterText(kotakPencarian(), 'BELANJA');
      await tester.pumpAndSettle();

      expect(find.text('Belanja Bulanan'), findsOneWidget);
    });

    // #Test #SebagianKata — Potongan kata juga harus cocok.
    testWidgets('mencari dengan potongan kata tetap menemukan hasil', (tester) async {
      await siapkan(tester);
      await bukaPencarian(tester);

      await tester.enterText(kotakPencarian(), 'apl');
      await tester.pumpAndSettle();

      // #Assert #DuaHasil — "Ide Aplikasi" (judul) dan
      // "Aplikasi pencatat..." (isi catatan Ide Aplikasi) cocok.
      expect(find.text('Ide Aplikasi'), findsOneWidget);
    });

    // #Test #TidakDitemukan — Pesan khusus, BUKAN "Belum ada catatan".
    //
    // Ini pembeda penting: pengguna harus tahu catatannya masih ada,
    // hanya tidak cocok dengan kata kunci.
    testWidgets('menampilkan pesan khusus saat tidak ada hasil', (tester) async {
      await siapkan(tester);
      await bukaPencarian(tester);

      await tester.enterText(kotakPencarian(), 'zzz tidak ada');
      await tester.pumpAndSettle();

      // #Assert #PesanKhusus
      expect(find.text('Tidak ada hasil'), findsOneWidget);

      // #Assert #KataKunciDisebut — Pesan harus menyebut kata kunci
      // yang dicari, supaya pengguna sadar mungkin ada salah ketik.
      //
      // CATATAN: `find.textContaining` di sini akan menemukan DUA widget —
      // teks pesan DAN isi kotak pencarian (karena kotak juga berisi
      // kata kunci yang sama). Karena itu kita cari teks pesan secara
      // utuh dengan `find.text`, bukan potongan.
      expect(
        find.text('Tidak ada catatan yang cocok dengan "zzz tidak ada".'),
        findsOneWidget,
      );

      // #Assert #BUKANEmptyState — Ini yang membedakan dari empty state biasa.
      expect(find.text('Belum ada catatan'), findsNothing);
    });

    // #Test #Bersihkan — Tombol bersihkan mengembalikan seluruh daftar.
    testWidgets('tombol bersihkan mengembalikan semua catatan', (tester) async {
      await siapkan(tester);
      await bukaPencarian(tester);

      await tester.enterText(kotakPencarian(), 'Belanja');
      await tester.pumpAndSettle();
      expect(find.text('Rencana Belajar'), findsNothing);

      // #Langkah #Bersihkan — Tombol X di AppBar.
      await tester.tap(find.byTooltip('Bersihkan pencarian'));
      await tester.pumpAndSettle();

      // #Assert #SemuaKembali
      expect(find.text('Belanja Bulanan'), findsOneWidget);
      expect(find.text('Rencana Belajar'), findsOneWidget);
      expect(find.text('Ide Aplikasi'), findsOneWidget);
    });

    // #Test #Tutup — Tombol kembali keluar dari mode pencarian.
    testWidgets('tombol tutup keluar dari mode pencarian', (tester) async {
      await siapkan(tester);
      await bukaPencarian(tester);

      await tester.enterText(kotakPencarian(), 'Belanja');
      await tester.pumpAndSettle();

      // #Langkah #Tutup
      await tester.tap(find.byTooltip('Tutup pencarian'));
      await tester.pumpAndSettle();

      // #Assert #KembaliNormal — Judul muncul lagi, kotak hilang.
      expect(find.text('Catatan Harian'), findsOneWidget);
      expect(kotakPencarian(), findsNothing);

      // #Assert #FilterDireset — Semua catatan tampil kembali.
      expect(find.text('Rencana Belajar'), findsOneWidget);
    });

    // #Test #TombolBersihkanHilang — Tombol X hanya muncul saat ada teks.
    testWidgets('tombol bersihkan hanya muncul saat ada teks', (tester) async {
      await siapkan(tester);
      await bukaPencarian(tester);

      // #Assert #Kosong — Belum ada teks, tombol X tidak ada.
      expect(find.byTooltip('Bersihkan pencarian'), findsNothing);

      await tester.enterText(kotakPencarian(), 'a');
      await tester.pumpAndSettle();

      // #Assert #AdaTeks — Sekarang muncul.
      expect(find.byTooltip('Bersihkan pencarian'), findsOneWidget);
    });
  });
}
