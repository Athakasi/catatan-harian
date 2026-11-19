// ============================================================
// FILE: lib/models/note.dart
// #Model #Class — Representasi satu catatan dalam bentuk kode.
//
// Ini adalah "bentuk data" aplikasi kita. Sebelum data bisa disimpan
// atau ditampilkan, ia harus punya wujud yang jelas: apa saja isinya.
//
// Padanan di dunia yang Anda kenal:
//   PHP  : class Note { public string $judul; ... }
//   JS   : const note = { id: '1', judul: '...', isi: '...' }
//
// Bedanya di Dart: bentuk data ditulis sebagai class (bukan object literal),
// sehingga salah ketik nama properti langsung ketahuan saat menulis kode,
// bukan saat aplikasi sudah jalan.
// ============================================================

// #Class #Note — Satu catatan milik pengguna.
//
// Semua properti di bawah bertanda `final`, artinya TIDAK BISA diubah
// setelah objek dibuat (immutable). Kalau ingin mengubah isi catatan,
// kita tidak mengubah objek lama, tapi membuat objek baru lewat copyWith().
//
// Kenapa begitu? Karena data yang tidak bisa berubah di tengah jalan
// jauh lebih mudah dilacak saat ada bug. Ini prinsip yang sama dengan
// "immutable value object" di OOP.
class Note {
  // #Constructor — Cara membuat objek Note.
  //
  // `required` = wajib diisi saat membuat objek.
  // `this.id` = singkatan Dart: langsung memasukkan nilai parameter
  //             ke properti dengan nama yang sama. Tanpa ini, kita harus
  //             menulis `id: id` di dalam badan constructor.
  const Note({
    required this.id,
    required this.judul,
    required this.isi,
    required this.dibuatPada,
    required this.diubahPada,
  });

  // #Penghitung #IdUnik — Penghitung naik untuk menjamin id tidak kembar.
  //
  // KENAPA INI PERLU? (bug nyata yang ditemukan saat menguji di browser)
  //
  // Awalnya id dibuat dari microsecondsSinceEpoch saja. Di Dart VM (Android)
  // nilainya presisi mikrodetik, tapi DI BROWSER JavaScript hanya presisi
  // MILIDETIK — tiga digit terakhir selalu nol, sama seperti Date.now() di JS.
  //
  // Akibatnya: dua catatan yang dibuat dalam milidetik yang sama mendapat
  // id IDENTIK. Di web, menghapus satu catatan ikut menghapus yang lain.
  // Test "dua catatan baru punya id berbeda" menangkap bug ini saat
  // dijalankan dengan `flutter test --platform chrome`.
  //
  // Solusi: tambahkan penghitung yang selalu naik. Karena aplikasi berjalan
  // dalam satu proses, penghitung ini tidak mungkin memberi angka sama
  // dua kali. Hasil id: "1763484000123-0", "1763484000123-1", dst.
  //
  // `static` artinya milik class, bukan milik objek — semua objek Note
  // berbagi satu penghitung yang sama.
  static int _penghitungId = 0;

  // #Factory #Constructor — Membuat catatan BARU (belum pernah disimpan).
  //
  // Disebut `factory` karena ia boleh mengembalikan objek yang sudah
  // dirakit sedemikian rupa, bukan sekadar mengisi properti.
  // Di sini kita otomatis membuat id dan mengisi kedua tanggal.
  //
  // `factory` juga dipakai saat kita butuh logika sebelum objek jadi —
  // sesuatu yang tidak bisa dilakukan constructor biasa.
  factory Note.baru({required String judul, required String isi}) {
    // #Langkah #Waktu — Ambil waktu sekarang sekali saja.
    // Penting: diambil sekali, lalu dipakai untuk id dan kedua tanggal,
    // supaya nilainya konsisten (tidak selisih milidetik).
    final sekarang = DateTime.now();

    return Note(
      // #ID — Gabungan waktu + penghitung, dijamin unik di semua platform.
      id: '${sekarang.microsecondsSinceEpoch}-${_penghitungId++}',
      judul: judul,
      isi: isi,
      dibuatPada: sekarang,
      diubahPada: sekarang,
    );
  }

  // #Factory #FromJson — Mengubah Map (hasil baca dari penyimpanan) jadi objek Note.
  //
  // Ini kebalikan dari toJson(). Dipakai di Langkah 4 saat memuat data
  // yang tersimpan di HP/browser.
  //
  // Parameter `Map<String, dynamic>` artinya: objek mirip array asosiatif
  // dengan kunci teks dan nilai bebas (bisa String, angka, dll).
  // Padanan PHP: array asosiatif. Padanan JS: object biasa.
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      // `as String` = memberitahu Dart "percayalah, ini String".
      // `?? ''` = kalau ternyata null, pakai teks kosong sebagai cadangan.
      // Kombinasi ini membuat aplikasi tidak crash kalau file datanya rusak.
      id: json['id'] as String? ?? '',
      judul: json['judul'] as String? ?? '',
      isi: json['isi'] as String? ?? '',

      // #Langkah #Tanggal — Tanggal disimpan sebagai teks ISO-8601
      // (contoh: "2026-11-18T23:06:35.123456").
      // tryParse mengembalikan null kalau formatnya tidak valid,
      // lalu kita ganti dengan waktu sekarang agar catatan tetap bisa dibuka.
      dibuatPada: DateTime.tryParse(json['dibuatPada'] as String? ?? '') ?? DateTime.now(),
      diubahPada: DateTime.tryParse(json['diubahPada'] as String? ?? '') ?? DateTime.now(),
    );
  }

  // #Properti — Isi dari satu catatan.

  // #ID — Pengenal unik. Dipakai untuk mencari & menghapus catatan tertentu.
  final String id;

  // #Judul — Judul singkat catatan.
  final String judul;

  // #Isi — Isi lengkap catatan.
  final String isi;

  // #TanggalDibuat — Kapan catatan ini pertama kali dibuat. Tidak pernah berubah.
  final DateTime dibuatPada;

  // #TanggalDiubah — Kapan catatan ini terakhir disunting.
  // Dipakai untuk mengurutkan daftar: yang terbaru diubah muncul paling atas.
  final DateTime diubahPada;

  // #Method #ToJson — Mengubah objek Note menjadi Map agar bisa disimpan.
  //
  // Map inilah yang nanti diubah jadi teks JSON oleh jsonEncode().
  // Perhatikan: DateTime TIDAK bisa disimpan langsung, jadi diubah
  // dulu ke teks lewat toIso8601String().
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'isi': isi,
      'dibuatPada': dibuatPada.toIso8601String(),
      'diubahPada': diubahPada.toIso8601String(),
    };
  }

  // #Method #CopyWith — Membuat salinan catatan dengan beberapa isi diganti.
  //
  // Karena semua properti `final`, kita tidak bisa menulis:
  //   note.judul = 'baru';   // ❌ ERROR: properti final tidak bisa diubah
  //
  // Cara yang benar:
  //   note = note.copyWith(judul: 'baru');
  //
  // Parameter yang tidak diisi akan memakai nilai lama (`?? this.judul`).
  // Pola ini sangat umum di Flutter, jadi biasakan sejak sekarang.
  Note copyWith({
    String? judul,
    String? isi,
    DateTime? diubahPada,
  }) {
    return Note(
      // id dan dibuatPada sengaja TIDAK bisa diganti — keduanya identitas catatan.
      id: id,
      judul: judul ?? this.judul,
      isi: isi ?? this.isi,
      dibuatPada: dibuatPada,
      diubahPada: diubahPada ?? this.diubahPada,
    );
  }

  // #Method #ToString — Teks bantuan saat objek di-print untuk debugging.
  // Tanpa ini, print(note) hanya menghasilkan "Instance of 'Note'" yang
  // tidak membantu. Method ini otomatis dipanggil oleh print() dan log.
  @override
  String toString() {
    return 'Note(id: $id, judul: $judul)';
  }
}
