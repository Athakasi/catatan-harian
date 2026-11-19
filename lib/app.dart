// ============================================================
// FILE: lib/app.dart
// #App #Root — Kerangka utama aplikasi (tema, judul, halaman awal).
//
// Analogi OOP: class ini adalah "konfigurasi aplikasi".
// Ia tidak menyimpan data catatan dan tidak menggambar daftar.
// Ia hanya menentukan: aplikasi ini bernama apa, warnanya apa,
// dan halaman pertama yang dibuka apa.
// ============================================================

import 'package:material_ui/material_ui.dart';

import 'screens/note_list_screen.dart';

// #Class #StatelessWidget — Widget yang tidak punya state (tidak berubah).
// Cocok untuk kerangka aplikasi yang konfigurasinya tetap sepanjang umur app.
// Bandingkan dengan StatefulWidget yang bisa berubah (dipakai di Langkah 5).
class CatatanHarianApp extends StatelessWidget {
  const CatatanHarianApp({super.key});

  // #Method #Build — Method wajib setiap widget: mengembalikan tampilan.
  // Dipanggil ulang oleh Flutter setiap kali layar perlu digambar.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // #Properti #Title — Nama aplikasi (dipakai task switcher & tab browser).
      title: 'Catatan Harian',

      // #Properti #DebugBanner — Mematikan pita "DEBUG" di pojok kanan atas.
      debugShowCheckedModeBanner: false,

      // #Properti #Theme — Tema warna aplikasi.
      // ColorScheme.fromSeed menghasilkan palet warna otomatis dari 1 warna dasar.
      // Ganti Colors.teal ke warna lain, dan seluruh aplikasi ikut berubah.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),

      // #Properti #Home — Halaman pertama yang ditampilkan saat app dibuka.
      // Untuk sekarang isinya masih placeholder (Langkah 5 akan diisi daftar catatan).
      home: const NoteListScreen(),
    );
  }
}
