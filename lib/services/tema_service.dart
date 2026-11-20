// ============================================================
// FILE: lib/services/tema_service.dart
// #Service #Tema — Membaca & menyimpan pilihan tema pengguna.
//
// Kenapa dipisah dari UI? Prinsip yang sama seperti NoteStorage:
// halaman tidak perlu tahu di mana data disimpan. Kalau nanti Anda
// ingin menyimpan tema di akun pengguna (cloud), cukup ubah file ini.
//
// Pola ini juga memudahkan pengujian: kita bisa menyuntikkan
// penyimpanan palsu tanpa menyentuh storage asli perangkat.
// ============================================================

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

// #Class #TemaService — Pengelola preferensi tema.
class TemaService {
  // #Constructor — Sama seperti NoteStorage: penyimpanan bisa disuntikkan
  // untuk keperluan test (dependency injection).
  TemaService({SharedPreferencesAsync? preferensi})
    : _preferensi = preferensi ?? SharedPreferencesAsync();

  // #Properti #Private — Instance penyimpanan.
  final SharedPreferencesAsync _preferensi;

  // #Konstanta #Kunci — Nama kunci penyimpanan.
  //
  // Diberi awalan 'catatan_harian.' agar konsisten dengan kunci lain
  // dan tidak bertabrakan di masa depan.
  static const String kunciTema = 'catatan_harian.tema';

  // #Method #Muat — Membaca tema tersimpan.
  //
  // Mengembalikan ThemeMode. Kalau belum pernah disimpan atau isinya
  // tidak dikenali, kembalikan ThemeMode.system (mengikuti pengaturan HP).
  Future<ThemeMode> muat() async {
    // #Langkah #Baca — Ambil teks dari penyimpanan.
    final tersimpan = await _preferensi.getString(kunciTema);

    // #Langkah #Cocokkan — Ubah teks menjadi ThemeMode.
    //
    // Kenapa disimpan sebagai teks, bukan angka? Karena teks lebih
    // mudah dibaca saat debugging ("gelap" vs "2") dan tidak rusak
    // kalau urutan enum berubah di masa depan.
    switch (tersimpan) {
      case 'terang':
        return ThemeMode.light;
      case 'gelap':
        return ThemeMode.dark;
      case 'sistem':
      default:
        return ThemeMode.system;
    }
  }

  // #Method #Simpan — Menyimpan pilihan tema.
  Future<void> simpan(ThemeMode mode) async {
    // #Langkah #Terjemahkan — Ubah ThemeMode menjadi teks.
    final teks = switch (mode) {
      ThemeMode.light => 'terang',
      ThemeMode.dark => 'gelap',
      ThemeMode.system => 'sistem',
    };

    await _preferensi.setString(kunciTema, teks);
  }
}
