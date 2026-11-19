// ============================================================
// FILE: test/widget_test.dart
// #Test #WidgetTest — Menguji halaman daftar catatan.
//
// Perbedaan penting dari Langkah 2: halaman ini sekarang MEMUAT DATA
// secara async. Artinya setelah widget digambar, masih ada proses
// berjalan di latar belakang. Test harus "menunggu" proses itu selesai
// dengan `pumpAndSettle()`.
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:catatan_harian/app.dart';
import 'package:catatan_harian/models/note.dart';
import 'package:catatan_harian/screens/note_list_screen.dart';
import 'package:catatan_harian/services/note_storage.dart';

import 'helpers/storage_lambat.dart';

void main() {
  // #Setup #InMemory — Pakai penyimpanan palsu agar test tidak menyentuh
  // data asli perangkat dan selalu mulai dari kondisi kosong.
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  // #Helper #BuatStorage — Service yang memakai penyimpanan palsu di atas.
  NoteStorage buatStorage() => NoteStorage(preferensi: SharedPreferencesAsync());

  // #Test #AplikasiUtuh — Aplikasi lengkap bisa dibuka dan judulnya benar.
  testWidgets('Aplikasi tampil dan judulnya benar', (WidgetTester tester) async {
    await tester.pumpWidget(const CatatanHarianApp());

    // #Langkah #Tunggu — Biarkan proses memuat data selesai.
    // pumpAndSettle menunggu sampai tidak ada animasi/proses tersisa.
    await tester.pumpAndSettle();

    expect(find.text('Catatan Harian'), findsOneWidget);
  });

  // #Test #Kosong — Saat belum ada data, tampil empty state yang informatif.
  testWidgets('menampilkan pesan kosong saat belum ada catatan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: NoteListScreen(storage: buatStorage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada catatan'), findsOneWidget);

    // #Assert #Petunjuk — Empty state harus memberi tahu apa yang harus
    // dilakukan, bukan hanya "tidak ada data".
    expect(find.textContaining('Tekan tombol +'), findsOneWidget);
  });

  // #Test #AdaData — Kalau ada catatan tersimpan, judulnya tampil di layar.
  testWidgets('menampilkan catatan yang tersimpan', (tester) async {
    // #Langkah #SiapkanData — Tulis data dulu ke penyimpanan palsu.
    final storage = buatStorage();
    await storage.tambah(Note.baru(judul: 'Belanja', isi: 'Beli susu'));
    await storage.tambah(Note.baru(judul: 'Rapat', isi: 'Rapat jam 9'));

    await tester.pumpWidget(
      MaterialApp(home: NoteListScreen(storage: storage)),
    );
    await tester.pumpAndSettle();

    // #Assert #JudulTampil
    expect(find.text('Belanja'), findsOneWidget);
    expect(find.text('Rapat'), findsOneWidget);

    // #Assert #KosongHilang — Empty state tidak boleh muncul.
    expect(find.text('Belum ada catatan'), findsNothing);
  });

  // #Test #Loading — Indikator loading tampil SEBELUM data selesai dimuat.
  //
  // CATATAN PENTING: penyimpanan in-memory biasa terlalu cepat (selesai
  // dalam satu microtask), sehingga spinner hilang sebelum test sempat
  // melihatnya. Karena itu kita pakai StorageLambat dengan jeda buatan.
  //
  // Ini bukan mengakali test — justru ini meniru kondisi nyata di HP,
  // di mana membaca storage butuh waktu beberapa milidetik.
  testWidgets('menampilkan indikator loading saat data dimuat', (tester) async {
    final storage = StorageLambat(
      preferensi: SharedPreferencesAsync(),
      jeda: const Duration(milliseconds: 300),
    );

    await tester.pumpWidget(
      MaterialApp(home: NoteListScreen(storage: storage)),
    );

    // #Langkah #FramePertama — Baru satu frame digambar, data belum siap.
    // Jangan pakai pumpAndSettle di sini, karena kita justru ingin
    // menangkap keadaan "masih memuat".
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // #Langkah #Selesaikan — Lewati jeda buatan, lalu pastikan loading hilang.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    // #Assert #HasilAkhir — Setelah selesai, empty state tampil.
    expect(find.text('Belum ada catatan'), findsOneWidget);
  });

  // #Test #TombolTambah — Tombol + membuka halaman form.
  testWidgets('tombol tambah membuka halaman form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: NoteListScreen(storage: buatStorage())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // #Assert #FormTerbuka — Judul AppBar form muncul.
    expect(find.text('Catatan Baru'), findsOneWidget);

    // #Assert #DaftarTertutup — Halaman daftar sudah tidak terlihat
    // (tertutup oleh halaman form di atasnya).
    expect(find.text('Belum ada catatan'), findsNothing);
  });

  // #Test #AlurLengkap — Uji end-to-end: tambah catatan lewat UI,
  // lalu pastikan catatan itu muncul di daftar.
  //
  // Ini test paling berharga karena meniru perilaku pengguna sungguhan:
  // tekan +, isi form, simpan, lihat hasilnya.
  testWidgets('menambah catatan lewat form lalu tampil di daftar', (tester) async {
    final storage = buatStorage();

    await tester.pumpWidget(
      MaterialApp(home: NoteListScreen(storage: storage)),
    );
    await tester.pumpAndSettle();

    // #Langkah #BukaForm
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // #Langkah #IsiForm
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Judul'),
      'Catatan Pertama',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Isi catatan'),
      'Isi catatan pertama saya',
    );

    // #Langkah #Simpan — Form tertutup dan kembali ke daftar.
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    // #Assert #KembaliKeDaftar — Judul AppBar daftar muncul lagi.
    expect(find.text('Catatan Harian'), findsOneWidget);

    // #Assert #CatatanTampil — Data baru terlihat di daftar.
    expect(find.text('Catatan Pertama'), findsOneWidget);
    expect(find.text('Isi catatan pertama saya'), findsOneWidget);

    // #Assert #EmptyStateHilang
    expect(find.text('Belum ada catatan'), findsNothing);

    // #Assert #TersimpanDiStorage — Bukan hanya tampilan, tapi benar tersimpan.
    final isi = await storage.muatSemua();
    expect(isi.length, 1);
    expect(isi.first.judul, 'Catatan Pertama');
  });

  // #Test #Batal — Menekan Batal tidak menyimpan apa pun.
  testWidgets('menekan batal tidak menyimpan catatan', (tester) async {
    final storage = buatStorage();

    await tester.pumpWidget(
      MaterialApp(home: NoteListScreen(storage: storage)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Judul'),
      'Tidak Jadi',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Isi catatan'),
      'isi',
    );

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    // #Assert #KembaliTanpaData
    expect(find.text('Belum ada catatan'), findsOneWidget);

    final isi = await storage.muatSemua();
    expect(isi, isEmpty);
  });

  // #Test #BukaEdit — Menyentuh kartu membuka form mode edit.
  testWidgets('menyentuh kartu membuka form edit', (tester) async {
    final storage = buatStorage();
    await storage.tambah(Note.baru(judul: 'Catatan Lama', isi: 'isi lama'));

    await tester.pumpWidget(
      MaterialApp(home: NoteListScreen(storage: storage)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catatan Lama'));
    await tester.pumpAndSettle();

    // #Assert #ModeEdit — Judul AppBar berubah.
    expect(find.text('Edit Catatan'), findsOneWidget);
  });

  // #Test #Urutan — Catatan terbaru tampil paling atas.
  //
  // Cara memeriksa urutan: cari posisi vertikal (dy) tiap teks.
  // Yang dy-nya lebih kecil berarti lebih atas.
  testWidgets('catatan terbaru tampil paling atas', (tester) async {
    final storage = buatStorage();

    final lama = Note(
      id: '1',
      judul: 'Catatan Lama',
      isi: 'isi',
      dibuatPada: DateTime(2026, 1, 1),
      diubahPada: DateTime(2026, 1, 1),
    );
    final baru = Note(
      id: '2',
      judul: 'Catatan Baru',
      isi: 'isi',
      dibuatPada: DateTime(2026, 5, 5),
      diubahPada: DateTime(2026, 5, 5),
    );
    await storage.simpanSemua([lama, baru]);

    await tester.pumpWidget(
      MaterialApp(home: NoteListScreen(storage: storage)),
    );
    await tester.pumpAndSettle();

    // #Langkah #AmbilPosisi — getTopLeft mengembalikan koordinat widget.
    final posisiBaru = tester.getTopLeft(find.text('Catatan Baru')).dy;
    final posisiLama = tester.getTopLeft(find.text('Catatan Lama')).dy;

    // #Assert #BaruDiAtas — Koordinat y lebih kecil = lebih dekat ke atas.
    expect(posisiBaru, lessThan(posisiLama));
  });
}
