// ============================================================
// FILE: lib/app.dart
// #App #Root — Kerangka utama aplikasi (tema, judul, halaman awal).
//
// PERUBAHAN BESAR di fitur tema gelap:
//   StatelessWidget -> StatefulWidget
//
// Alasannya: tema sekarang bisa BERUBAH saat aplikasi berjalan
// (pengguna memilih terang/gelap). Widget yang isinya berubah
// wajib StatefulWidget, supaya Flutter tahu kapan harus menggambar
// ulang seluruh aplikasi.
//
// Perhatikan: hanya CATATAN HARIAN yang berubah tema. Seluruh
// aplikasi (daftar, form, dialog) ikut berubah otomatis, karena
// semuanya mengambil warna dari Theme.of(context).
// ============================================================

import 'package:material_ui/material_ui.dart';

import 'screens/note_list_screen.dart';
import 'screens/pengaturan_screen.dart';
import 'services/tema_service.dart';

// #Class #StatefulWidget — Sekarang punya state: pilihan tema.
class CatatanHarianApp extends StatefulWidget {
  // #Constructor — `temaService` opsional untuk keperluan TEST.
  //
  // Di aplikasi sungguhan parameter ini tidak diisi, sehingga
  // service membuat penyimpanan sendiri. Di test, kita menyuntikkan
  // penyimpanan palsu agar tidak menyentuh data asli.
  const CatatanHarianApp({super.key, this.temaService});

  // #Properti #TemaService — Service penyimpanan tema.
  final TemaService? temaService;

  @override
  State<CatatanHarianApp> createState() => _CatatanHarianAppState();
}

class _CatatanHarianAppState extends State<CatatanHarianApp> {
  // #Properti #Service — Service tema, dibuat sekali.
  late final TemaService _temaService;

  // #Properti #Tema — Pilihan tema yang sedang aktif.
  //
  // Diawali `system` supaya aplikasi langsung mengikuti pengaturan
  // perangkat sejak frame pertama. Kalau kita mulai dengan null
  // lalu menunggu pembacaan storage, akan ada "kedipan" tema terang
  // sebelum berubah ke gelap.
  ThemeMode _tema = ThemeMode.system;

  // #Method #InitState — Membaca tema tersimpan saat aplikasi dibuka.
  @override
  void initState() {
    super.initState();

    _temaService = widget.temaService ?? TemaService();

    // #Langkah #MuatTema — Baca pilihan tersimpan.
    //
    // Tidak di-await (initState tidak boleh async). Hasilnya
    // diterapkan lewat setState saat sudah siap.
    _muatTema();
  }

  // #Method #MuatTema — Mengambil tema tersimpan dari penyimpanan.
  Future<void> _muatTema() async {
    try {
      final tersimpan = await _temaService.muat();

      // #Langkah #CekMounted — Sama seperti di halaman lain.
      if (!mounted) return;

      setState(() {
        _tema = tersimpan;
      });
    } catch (e) {
      // #Langkah #Abaikan — Kalau gagal membaca tema, biarkan
      // memakai tema sistem. Ini bukan kesalahan fatal; aplikasi
      // tetap bisa dipakai.
    }
  }

  // #Method #UbahTema — Menerapkan tema baru dan menyimpannya.
  //
  // Dipanggil dari halaman pengaturan lewat nilai yang dikembalikan
  // Navigator.pop().
  Future<void> _ubahTema(ThemeMode mode) async {
    // #Langkah #TerapkanDulu — Ubah tampilan SEKARANG, jangan tunggu
    // penyimpanan selesai. Penyimpanan hanya butuh milidetik, tapi
    // menunggunya membuat UI terasa lambat.
    //
    // Ini disebut "optimistic update": tampilkan dulu, simpan di
    // belakang. Kalau penyimpanan gagal, tema tetap berubah untuk
    // sesi ini (dan itu wajar).
    setState(() {
      _tema = mode;
    });

    // #Langkah #Simpan — Simpan pilihan ke storage.
    await _temaService.simpan(mode);
  }

  // #Method #BukaPengaturan — Membuka halaman pengaturan.
  //
  // ============ JEBAKAN PENTING: context mana yang dipakai ============
  //
  // Parameter `context` di sini BUKAN context milik State ini.
  // Ia adalah context dari dalam `Builder` di build() — yaitu context
  // yang berada DI BAWAH MaterialApp.
  //
  // Kenapa harus begitu? Karena Navigator diciptakan OLEH MaterialApp.
  // Context milik State ini berada di ATAS MaterialApp, sehingga belum
  // punya Navigator. Kalau kita memakai `this.context`, Flutter akan
  // melempar error:
  //
  //   "Navigator operation requested with a context that does not
  //    include a Navigator."
  //
  // Ini jebakan klasik saat mengubah StatelessWidget menjadi
  // StatefulWidget: dulu `context` datang dari parameter build(),
  // sekarang State punya `context` sendiri yang posisinya berbeda.
  Future<void> _bukaPengaturan(BuildContext context) async {
    // #Langkah #Buka — Tunggu hasil dari halaman pengaturan.
    final pilihan = await Navigator.push<ThemeMode>(
      context,
      MaterialPageRoute(
        builder: (context) => PengaturanScreen(temaSaatIni: _tema),
      ),
    );

    // #Langkah #Terapkan — Kalau pengguna memilih, terapkan.
    if (pilihan != null) {
      await _ubahTema(pilihan);
    }
  }

  // #Method #Build — Menyusun MaterialApp dengan tema terang & gelap.
  @override
  Widget build(BuildContext context) {
    // #Langkah #Palet — Satu warna dasar menghasilkan dua palet:
    // terang dan gelap. Keduanya otomatis harmonis.
    //
    // `brightness: Brightness.dark` memberi tahu Flutter bahwa ini
    // palet gelap, sehingga warna teks, ikon, dan bayangan ikut
    // menyesuaikan tanpa kita atur satu per satu.
    final paletTerang = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    );
    final paletGelap = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Catatan Harian',
      debugShowCheckedModeBanner: false,

      // #Properti #Theme — Tema saat perangkat/aplikasi dalam mode terang.
      theme: ThemeData(colorScheme: paletTerang),

      // #Properti #DarkTheme — Tema saat mode gelap.
      darkTheme: ThemeData(colorScheme: paletGelap),

      // #Properti #ThemeMode — SIAPA yang menentukan terang/gelap.
      //
      //   ThemeMode.system -> ikut pengaturan perangkat
      //   ThemeMode.light  -> selalu terang
      //   ThemeMode.dark   -> selalu gelap
      //
      // Inilah satu-satunya baris yang membuat tema bisa diubah
      // pengguna. Tanpa ini, `darkTheme` hanya dipakai kalau
      // perangkat dalam mode gelap.
      themeMode: _tema,

      // #Properti #Home — Halaman pertama.
      //
      // Kita bungkus dengan Builder agar bisa mengirim callback
      // `onBukaPengaturan` ke NoteListScreen. Tanpa Builder, kita
      // tidak punya cara meneruskan aksi ke halaman di bawahnya.
      home: Builder(
        builder: (context) => NoteListScreen(
          // #Langkah #KirimContext — Kita kirim context DARI DALAM
          // Builder, bukan context milik State. Lihat penjelasan
          // di _bukaPengaturan() di atas.
          onBukaPengaturan: () => _bukaPengaturan(context),
        ),
      ),
    );
  }
}