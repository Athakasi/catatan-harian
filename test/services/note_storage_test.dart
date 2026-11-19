// ============================================================
// FILE: test/services/note_storage_test.dart
// #Test #UnitTest — Menguji penyimpanan tanpa menyentuh storage asli.
//
// Trik di sini: kita MENGGANTI penyimpanan perangkat dengan penyimpanan
// palsu di memori (InMemorySharedPreferencesAsync). Jadi test berjalan
// cepat, tidak mengotori data aplikasi Anda, dan bisa dijalankan di
// mesin CI seperti GitHub Actions.
//
// Ini contoh nyata manfaat "dependency injection" yang saya jelaskan
// di note_storage.dart: karena penyimpanan bisa disuntikkan, ia juga
// bisa diganti saat test.
// ============================================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:catatan_harian/models/note.dart';
import 'package:catatan_harian/services/note_storage.dart';

void main() {
  // #Setup #InMemory — Sebelum tiap test, pasang penyimpanan palsu
  // yang masih kosong. Test jadi saling terisolasi: data test pertama
  // tidak bocor ke test berikutnya.
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  // #Helper #BuatStorage — Membuat service yang memakai penyimpanan palsu.
  NoteStorage buatStorage() => NoteStorage(preferensi: SharedPreferencesAsync());

  group('NoteStorage', () {
    // #Test #Kosong — Penyimpanan baru harus mengembalikan list kosong,
    // bukan error.
    test('muatSemua mengembalikan list kosong saat belum ada data', () async {
      final storage = buatStorage();

      final hasil = await storage.muatSemua();

      expect(hasil, isEmpty);
    });

    // #Test #Tambah — Satu catatan ditambahkan, lalu bisa dimuat kembali.
    test('tambah menyimpan catatan dan bisa dimuat lagi', () async {
      final storage = buatStorage();
      final catatan = Note.baru(judul: 'Belanja', isi: 'Beli susu');

      await storage.tambah(catatan);
      final hasil = await storage.muatSemua();

      expect(hasil.length, 1);
      expect(hasil.first.judul, 'Belanja');
      expect(hasil.first.isi, 'Beli susu');
      expect(hasil.first.id, catatan.id);
    });

    // #Test #Urutan — Catatan yang paling akhir diubah harus muncul pertama.
    test('muatSemua mengurutkan dari yang terakhir diubah', () async {
      final storage = buatStorage();

      // #Langkah #Siapkan — Tiga catatan dengan tanggal ubah berbeda.
      // Dibuat manual (bukan Note.baru) supaya tanggalnya bisa diatur.
      final lama = Note(
        id: '1',
        judul: 'Lama',
        isi: 'a',
        dibuatPada: DateTime(2026, 1, 1),
        diubahPada: DateTime(2026, 1, 1),
      );
      final tengah = Note(
        id: '2',
        judul: 'Tengah',
        isi: 'b',
        dibuatPada: DateTime(2026, 1, 2),
        diubahPada: DateTime(2026, 1, 2),
      );
      final baru = Note(
        id: '3',
        judul: 'Baru',
        isi: 'c',
        dibuatPada: DateTime(2026, 1, 3),
        diubahPada: DateTime(2026, 1, 3),
      );

      await storage.simpanSemua([lama, tengah, baru]);
      final hasil = await storage.muatSemua();

      // #Assert #UrutanBenar — Yang terbaru di indeks 0.
      expect(hasil.map((n) => n.judul).toList(), ['Baru', 'Tengah', 'Lama']);
    });

    // #Test #Perbarui — Mengubah isi catatan harus menyimpan perubahan
    // DAN memperbarui tanggal "diubah".
    test('perbarui mengubah isi dan memperbarui tanggal diubah', () async {
      final storage = buatStorage();

      final catatan = Note(
        id: 'abc',
        judul: 'Judul lama',
        isi: 'isi lama',
        dibuatPada: DateTime(2020, 1, 1),
        diubahPada: DateTime(2020, 1, 1),
      );
      await storage.tambah(catatan);

      await storage.perbarui(catatan.copyWith(judul: 'Judul baru'));
      final hasil = await storage.muatSemua();

      expect(hasil.length, 1);
      expect(hasil.first.judul, 'Judul baru');
      expect(hasil.first.isi, 'isi lama'); // tidak diubah

      // #Assert #TanggalBerubah — Tanggal dibuat tetap, tanggal ubah jadi baru.
      expect(hasil.first.dibuatPada, DateTime(2020, 1, 1));
      expect(hasil.first.diubahPada.isAfter(DateTime(2020, 1, 1)), isTrue);
    });

    // #Test #Hapus — Menghapus berdasarkan id.
    test('hapus membuang catatan sesuai id', () async {
      final storage = buatStorage();

      final a = Note.baru(judul: 'A', isi: 'a');
      final b = Note.baru(judul: 'B', isi: 'b');
      await storage.simpanSemua([a, b]);

      await storage.hapus(a.id);
      final hasil = await storage.muatSemua();

      expect(hasil.length, 1);
      expect(hasil.first.id, b.id);
    });

    // #Test #HapusIdSalah — Menghapus id yang tidak ada tidak boleh error.
    test('hapus id yang tidak ada tidak menimbulkan error', () async {
      final storage = buatStorage();
      await storage.tambah(Note.baru(judul: 'A', isi: 'a'));

      await storage.hapus('id-yang-tidak-ada');

      final hasil = await storage.muatSemua();
      expect(hasil.length, 1);
    });

    // #Test #DataRusak — Ini yang paling penting: data rusak tidak boleh
    // membuat aplikasi crash. Pengguna tetap bisa membuka aplikasi.
    test('data JSON rusak dikembalikan sebagai list kosong', () async {
      final penyimpanan = SharedPreferencesAsync();

      // #Langkah #RusakSengaja — Tulis teks yang bukan JSON valid.
      await penyimpanan.setString(NoteStorage.kunciPenyimpanan, 'ini bukan json {{{');

      final storage = NoteStorage(preferensi: penyimpanan);
      final hasil = await storage.muatSemua();

      expect(hasil, isEmpty);
    });

    // #Test #BukanList — JSON valid tapi bentuknya bukan daftar.
    test('JSON valid tapi bukan list juga ditangani dengan aman', () async {
      final penyimpanan = SharedPreferencesAsync();
      await penyimpanan.setString(
        NoteStorage.kunciPenyimpanan,
        jsonEncode({'bukan': 'list'}),
      );

      final storage = NoteStorage(preferensi: penyimpanan);
      final hasil = await storage.muatSemua();

      expect(hasil, isEmpty);
    });
  });
}
