// ============================================================
// FILE: lib/screens/pengaturan_screen.dart
// #Screen #Pengaturan — Halaman untuk memilih tema aplikasi.
//
// Halaman ini mengembalikan ThemeMode lewat Navigator.pop() saat
// pengguna memilih. Induknya (CatatanHarianApp) yang menyimpan
// pilihan itu dan mengubah tema seluruh aplikasi.
//
// Ini pola "anak melapor ke induk" — sama seperti form catatan
// yang mengembalikan `true` setelah menyimpan.
// ============================================================

import 'package:material_ui/material_ui.dart';

// #Class #PengaturanScreen — Halaman pengaturan tema.
class PengaturanScreen extends StatelessWidget {
  // #Constructor — Menerima tema yang sedang aktif.
  //
  // `temaSaatIni` dipakai untuk menandai pilihan mana yang aktif
  // saat halaman dibuka.
  const PengaturanScreen({super.key, required this.temaSaatIni});

  // #Properti #TemaSaatIni — Pilihan tema yang sedang berlaku.
  final ThemeMode temaSaatIni;

  // #Method #Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),

      // #Widget #ListView — Daftar pengaturan.
      //
      // Kita pakai ListView (bukan Column) karena isinya berupa daftar
      // yang mungkin bertambah nanti, dan supaya bisa digulir di layar
      // kecil.
      body: ListView(
        children: [
          // #Widget #Padding #JudulBagian — Judul kecil di atas pilihan.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Tampilan',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // #Widget #RadioGroup — Pengelola pilihan tunggal.
          //
          // Sejak Flutter 3.32, RadioListTile TIDAK lagi menerima
          // `groupValue` dan `onChanged` sendiri (keduanya deprecated).
          // Sebagai gantinya, satu RadioGroup membungkus semuanya dan
          // mengurus nilai terpilih + perubahannya.
          RadioGroup<ThemeMode>(
            groupValue: temaSaatIni,

            // #Properti #OnChanged — Dipanggil saat pengguna memilih.
            onChanged: (mode) {
              // #Langkah #Kembalikan — Kirim pilihan ke halaman sebelumnya.
              //
              // Kalau mode null (tidak mungkin terjadi di sini, tapi
              // tipenya membolehkan), abaikan saja.
              if (mode == null) return;
              Navigator.pop(context, mode);
            },

            child: Column(
              children: [
                // #Widget #RadioListTile #Sistem
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: const Text('Ikuti sistem'),
                  subtitle: const Text(
                    'Menyesuaikan pengaturan terang/gelap di perangkat Anda',
                  ),
                  secondary: const Icon(Icons.brightness_auto),
                ),

                // #Widget #RadioListTile #Terang
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: const Text('Terang'),
                  subtitle: const Text('Selalu menggunakan tampilan terang'),
                  secondary: const Icon(Icons.light_mode),
                ),

                // #Widget #RadioListTile #Gelap
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: const Text('Gelap'),
                  subtitle: const Text('Selalu menggunakan tampilan gelap'),
                  secondary: const Icon(Icons.dark_mode),
                ),
              ],
            ),
          ),

          // #Widget #Divider — Garis pemisah.
          const Divider(height: 32),

          // #Widget #Text #Info — Penjelasan tambahan.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Pilihan tema disimpan di perangkat ini dan akan tetap '
              'berlaku saat aplikasi dibuka kembali.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
