// ============================================================
// FILE: lib/services/note_storage.dart
// #Service #Storage — Baca & tulis daftar catatan ke penyimpanan lokal.
//
// Inilah "lapisan penyimpanan" aplikasi. Halaman (UI) TIDAK tahu
// data disimpan di mana — ia hanya bilang "tolong simpan ini" dan
// "tolong ambil semuanya". Pemisahan ini penting: kalau nanti Anda
// ingin pindah ke database (SQLite) atau API server, cukup ganti
// file ini saja. Halaman tidak perlu diubah sama sekali.
//
// Padanan PHP: class Repository / Model yang mengurus query database.
//
// CATATAN PENTING SOAL shared_preferences:
//   - Di Android : disimpan sebagai file preferensi milik aplikasi.
//   - Di Web     : disimpan di localStorage browser.
//   - Di iOS     : disimpan di NSUserDefaults.
//   Satu kode yang sama, tiga tempat berbeda. Flutter yang mengurus.
//
// PERINGATAN: shared_preferences cocok untuk data kecil (ratusan catatan
// teks). Untuk ribuan catatan atau data sensitif, gunakan database.
// ============================================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

// #Class #NoteStorage — Pengelola penyimpanan catatan.
class NoteStorage {
  // #Constructor — Membuat service penyimpanan.
  //
  // Parameter `preferensi` opsional: kalau tidak diisi, service membuat
  // SharedPreferencesAsync sendiri. Parameter ini ada supaya saat TEST
  // kita bisa menyuntikkan penyimpanan palsu (in-memory) tanpa
  // menyentuh storage asli perangkat.
  //
  // Ini disebut "dependency injection" — salah satu teknik OOP paling
  // berguna yang akan Anda pakai terus di Flutter.
  NoteStorage({SharedPreferencesAsync? preferensi})
    : _preferensi = preferensi ?? SharedPreferencesAsync();

  // #Properti #Private — Instance penyimpanan. Tanda `_` di depan nama
  // berarti "hanya bisa diakses dari dalam file ini" (private).
  // Padanan PHP: `private $preferensi;`
  final SharedPreferencesAsync _preferensi;

  // #Konstanta #Kunci — Nama kunci tempat data disimpan.
  // Dibuat `static const` supaya hanya ada satu nilai untuk seluruh aplikasi,
  // dan bisa dipakai di test untuk memeriksa isi mentah penyimpanan.
  //
  // Beri awalan nama aplikasi (contoh: 'catatan_harian.') agar tidak
  // bertabrakan dengan kunci lain di masa depan.
  static const String kunciPenyimpanan = 'catatan_harian.daftar_catatan';

  // #Method #MuatSemua — Mengambil seluruh catatan dari penyimpanan.
  //
  // Mengembalikan List<Note>. Kalau belum ada data sama sekali,
  // hasilnya list kosong (bukan error) — supaya pemanggil tidak perlu
  // menulis pengecekan null.
  Future<List<Note>> muatSemua() async {
    // #Langkah #BacaMentah — Ambil teks JSON dari penyimpanan.
    // Hasilnya String? (boleh null) karena kunci mungkin belum pernah ditulis.
    final teks = await _preferensi.getString(kunciPenyimpanan);

    // #Langkah #CekKosong — Belum ada data = wajar, bukan kesalahan.
    if (teks == null || teks.isEmpty) {
      return <Note>[];
    }

    // #Langkah #Decode — Ubah teks JSON kembali menjadi objek Dart.
    //
    // try/catch dipakai karena isi penyimpanan bisa rusak (misalnya
    // aplikasi versi lama, atau data diutak-atik lewat DevTools browser).
    // Prinsipnya: data rusak TIDAK BOLEH membuat aplikasi crash.
    try {
      final data = jsonDecode(teks);

      // #Langkah #Validasi — Pastikan bentuknya memang daftar.
      if (data is! List) {
        return <Note>[];
      }

      // #Langkah #Konversi — Setiap item diubah dari Map menjadi Note.
      // `whereType<Map<String, dynamic>>()` menyaring item yang bentuknya
      // tidak sesuai, jadi satu data rusak tidak menggagalkan semuanya.
      final daftar = data
          .whereType<Map<String, dynamic>>()
          .map(Note.fromJson)
          .toList();

      // #Langkah #Urutkan — Yang terakhir diubah tampil paling atas.
      // Bandingkan dua tanggal: kalau b lebih baru dari a, b ditaruh lebih dulu.
      daftar.sort((a, b) => b.diubahPada.compareTo(a.diubahPada));

      return daftar;
    } on FormatException {
      // #Penanganan #FormatRusak — JSON tidak valid. Kembalikan list kosong
      // agar aplikasi tetap bisa dibuka. (Data lama dibiarkan, tidak dihapus,
      // supaya masih mungkin diselamatkan secara manual.)
      return <Note>[];
    }
  }

  // #Method #SimpanSemua — Menimpa seluruh isi penyimpanan dengan daftar ini.
  //
  // Ini "tulis total", bukan "tambah satu". Sederhana dan aman untuk
  // data kecil: tidak ada risiko data setengah tersimpan.
  Future<void> simpanSemua(List<Note> daftar) async {
    // #Langkah #Encode — Ubah List<Note> menjadi teks JSON.
    //
    // Alurnya: Note -> (toJson) -> Map -> (jsonEncode) -> String.
    // `map((note) => note.toJson())` mengubah tiap Note jadi Map,
    // lalu `.toList()` menjadikannya List<Map>.
    final teks = jsonEncode(daftar.map((note) => note.toJson()).toList());

    // #Langkah #Tulis — Simpan teks tersebut. Operasi ini async,
    // jadi harus di-`await` agar kita tahu kapan benar-benar selesai.
    await _preferensi.setString(kunciPenyimpanan, teks);
  }

  // #Method #Tambah — Menambahkan satu catatan baru ke penyimpanan.
  //
  // Pola "baca -> ubah -> tulis" ini akan Anda temui di hampir semua
  // aplikasi yang menyimpan data ke file.
  Future<void> tambah(Note catatan) async {
    final daftar = await muatSemua();
    daftar.add(catatan);
    await simpanSemua(daftar);
  }

  // #Method #Perbarui — Mengganti catatan lama dengan versi barunya.
  //
  // Catatan dicari berdasarkan `id`, bukan berdasarkan posisi di list.
  // Alasannya: posisi bisa berubah karena pengurutan, sedangkan id unik
  // dan tidak pernah berubah. Ini prinsip yang sama dengan PRIMARY KEY
  // di database.
  Future<void> perbarui(Note catatan) async {
    final daftar = await muatSemua();

    // #Langkah #Cari — indexWhere mengembalikan posisi item pertama yang
    // cocok, atau -1 kalau tidak ditemukan.
    final posisi = daftar.indexWhere((note) => note.id == catatan.id);

    // #Langkah #CekTidakAda — Catatan sudah dihapus di tempat lain?
    // Tidak perlu error; cukup berhenti diam-diam.
    if (posisi == -1) {
      return;
    }

    // #Langkah #PerbaruiTanggal — Tanggal "diubah" diisi otomatis di sini,
    // supaya halaman tidak perlu mengingatnya. Satu tempat, satu aturan.
    daftar[posisi] = catatan.copyWith(diubahPada: DateTime.now());

    await simpanSemua(daftar);
  }

  // #Method #Hapus — Menghapus satu catatan berdasarkan id.
  Future<void> hapus(String id) async {
    final daftar = await muatSemua();

    // #Langkah #Saring — removeWhere membuang semua item yang id-nya cocok.
    // (id seharusnya unik, tapi removeWhere lebih aman daripada removeAt.)
    daftar.removeWhere((note) => note.id == id);

    await simpanSemua(daftar);
  }
}
