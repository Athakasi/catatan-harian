// ============================================================
// FILE: lib/main.dart
// #Main #EntryPoint — Titik masuk aplikasi Catatan Harian.
//
// Di Flutter, file ini adalah "pintu depan" aplikasi.
// Padanan di dunia web: index.js / index.php.
// Tugasnya HANYA satu: menyalakan aplikasi lewat runApp().
// Semua pengaturan tampilan ada di lib/app.dart.
// ============================================================

import 'package:material_ui/material_ui.dart';

import 'app.dart';

// #Fungsi #Main — Fungsi pertama yang dijalankan saat aplikasi dibuka.
// Parameter `ensureInitialized()` disiapkan di sini agar nanti
// (Langkah 4) kita bisa memuat data tersimpan SEBELUM layar digambar.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CatatanHarianApp());
}
