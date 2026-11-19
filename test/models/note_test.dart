// ============================================================
// FILE: test/models/note_test.dart
// #Test #UnitTest — Menguji model Note tanpa membuka aplikasi.
//
// Unit test itu cepat (milidetik) dan tidak butuh layar.
// Ini "jaring pengaman" Anda: kalau nanti model diubah dan ada
// yang rusak, test ini langsung memberi tahu.
//
// Jalankan dengan: flutter test
// ============================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:catatan_harian/models/note.dart';

void main() {
  // #Group — Mengelompokkan beberapa test terkait agar laporannya rapi.
  group('Note', () {
    // #Test #Baru — Memastikan Note.baru() mengisi data dengan benar.
    test('Note.baru mengisi id, judul, isi, dan tanggal', () {
      final note = Note.baru(judul: 'Belanja', isi: 'Beli susu');

      // #Assert #Expect — expect(nilaiSebenarnya, nilaiYangDiharapkan).
      expect(note.judul, 'Belanja');
      expect(note.isi, 'Beli susu');

      // #Assert #NotEmpty — id harus terisi, bukan string kosong.
      expect(note.id, isNotEmpty);

      // #Assert #TanggalSama — Saat dibuat, tanggal buat dan tanggal ubah sama.
      expect(note.dibuatPada, note.diubahPada);
    });

    // #Test #IdUnik — Dua catatan yang dibuat berurutan harus punya id berbeda.
    test('dua catatan baru punya id berbeda', () {
      final a = Note.baru(judul: 'A', isi: 'isi A');
      final b = Note.baru(judul: 'B', isi: 'isi B');

      expect(a.id, isNot(b.id));
    });

    // #Test #IdUnikMassal — REGRESI: dulu test ini GAGAL di browser.
    //
    // Di web, DateTime.now() hanya presisi milidetik, sehingga catatan
    // yang dibuat dalam milidetik yang sama bisa mendapat id kembar.
    // Sekarang id memakai penghitung, jadi 50 catatan pun harus unik.
    //
    // Test ini sengaja dijalankan juga lewat `flutter test --platform chrome`
    // di CI, karena hanya di sana bug seperti ini muncul.
    test('banyak catatan yang dibuat cepat tetap punya id unik', () {
      final daftar = List.generate(50, (i) => Note.baru(judul: 'N$i', isi: 'isi'));

      // #Assert #Unik — Ubah ke Set (yang otomatis membuang duplikat).
      // Kalau panjangnya tetap 50, berarti semua id memang unik.
      final idUnik = daftar.map((n) => n.id).toSet();

      expect(idUnik.length, 50);
    });

    // #Test #Json — Uji "bolak-balik": objek -> Map -> objek harus utuh.
    // Ini yang akan terjadi di Langkah 4 saat menyimpan lalu memuat data.
    test('toJson lalu fromJson mengembalikan data yang sama', () {
      final asli = Note.baru(judul: 'Rapat', isi: 'Rapat jam 9');

      // #Langkah #Simulasi — Anggap saja ini data yang dibaca dari storage.
      final json = asli.toJson();
      final hasil = Note.fromJson(json);

      expect(hasil.id, asli.id);
      expect(hasil.judul, asli.judul);
      expect(hasil.isi, asli.isi);
      expect(hasil.dibuatPada, asli.dibuatPada);
      expect(hasil.diubahPada, asli.diubahPada);
    });

    // #Test #CopyWith — Memastikan copyWith mengganti hanya yang diminta.
    test('copyWith mengganti judul tanpa mengubah id', () {
      final asli = Note.baru(judul: 'Lama', isi: 'isi tetap');

      final baru = asli.copyWith(
        judul: 'Baru',
        diubahPada: DateTime(2026, 1, 1),
      );

      expect(baru.judul, 'Baru');
      expect(baru.isi, 'isi tetap'); // tidak diminta diubah, jadi tetap
      expect(baru.id, asli.id); // id tidak pernah berubah
      expect(baru.diubahPada, DateTime(2026, 1, 1));
      expect(baru.dibuatPada, asli.dibuatPada); // tanggal buat tidak berubah
    });

    // #Test #DataRusak — Memastikan aplikasi tidak crash saat data tidak lengkap.
    test('fromJson tetap aman saat data kosong atau rusak', () {
      final hasil = Note.fromJson(<String, dynamic>{});

      expect(hasil.id, '');
      expect(hasil.judul, '');
      expect(hasil.isi, '');
    });
  });
}
