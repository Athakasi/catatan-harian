// ============================================================
// FILE: lib/widgets/dialog_konfirmasi.dart
// #Widget #Dialog — Dialog konfirmasi yang bisa dipakai berulang.
//
// KENAPA DIBUAT FUNGSI, BUKAN WIDGET?
//
// Dialog itu bukan bagian dari tampilan halaman — ia "melayang" di atas
// segalanya dan HILANG setelah dijawab. Karena itu ia lebih tepat
// dipandang sebagai sebuah AKSI yang mengembalikan nilai:
//
//     final setuju = await tampilkanDialogKonfirmasi(context, ...);
//     if (setuju) { ... }
//
// Bentuknya persis seperti `confirm()` di JavaScript, tapi tampilannya
// bisa kita atur penuh.
//
// Padanan PHP: tidak ada padanannya di sisi server — ini murni UI.
// ============================================================

import 'package:material_ui/material_ui.dart';

// #Fungsi #TampilkanDialogKonfirmasi — Menampilkan dialog Ya/Tidak.
//
// Mengembalikan Future<bool>:
//   true  = pengguna menekan tombol aksi (misalnya "Hapus")
//   false = pengguna menekan "Batal", menutup dialog, atau menekan
//           tombol back — termasuk saat dialog ditutup dengan cara
//           apa pun selain menekan tombol aksi.
//
// Parameter:
//   judul       -> teks tebal di atas dialog
//   pesan       -> penjelasan di bawah judul
//   labelAksi   -> teks tombol utama (misalnya "Hapus")
//   warnaAksi   -> warna tombol utama; merah untuk aksi berbahaya
Future<bool> tampilkanDialogKonfirmasi(
  BuildContext context, {
  required String judul,
  required String pesan,
  String labelAksi = 'Ya',
  Color? warnaAksi,
}) async {
  // #Langkah #Tampilkan — showDialog membuka dialog dan menunggu jawabannya.
  //
  // Tipe `<bool>` memberi tahu Dart bahwa dialog ini akan mengembalikan
  // bool. Hasilnya `bool?` (boleh null) karena pengguna bisa menutup
  // dialog tanpa memilih (misalnya tekan tombol back atau klik di luar).
  final hasil = await showDialog<bool>(
    context: context,

    // #Properti #BarrierDismissible — Kalau true (default), pengguna bisa
    // menutup dialog dengan menyentuh area gelap di luarnya.
    //
    // Untuk aksi berbahaya seperti hapus, lebih aman diset false:
    // pengguna harus benar-benar memilih, tidak bisa "tidak sengaja"
    // menutup lalu bingung apakah data terhapus atau tidak.
    barrierDismissible: false,

    // #Properti #Builder — Fungsi yang membangun isi dialog.
    // Parameter `dialogContext` adalah context DI DALAM dialog —
    // dipakai untuk menutup dialog itu sendiri.
    builder: (dialogContext) {
      // #Ambil #Tema — Ambil warna dari tema agar konsisten.
      final warna = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        // #Widget #Icon — Ikon peringatan di atas judul.
        // Membantu pengguna langsung paham ini aksi penting.
        icon: Icon(
          Icons.warning_amber_rounded,
          color: warnaAksi ?? warna.error,
          size: 32,
        ),

        title: Text(judul, textAlign: TextAlign.center),

        // #Widget #Text #Pesan
        content: Text(pesan, textAlign: TextAlign.center),

        // #Properti #Actions — Deretan tombol di bawah dialog.
        actions: [
          // #Tombol #Batal — Mengembalikan `false`.
          TextButton(
            // #Langkah #TutupDialog — Navigator.pop menutup dialog.
            // Nilai `false` inilah yang diterima oleh `await` di atas.
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),

          // #Tombol #Aksi — Mengembalikan `true`.
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),

            // #Properti #Style — Tombol berwarna merah untuk aksi
            // berbahaya. Ini pola Material Design: warna memberi sinyal
            // "hati-hati" sebelum pengguna menekan.
            style: FilledButton.styleFrom(
              backgroundColor: warnaAksi ?? warna.error,
              foregroundColor: warna.onError,
            ),
            child: Text(labelAksi),
          ),
        ],
      );
    },
  );

  // #Langkah #AmankanNull — `hasil` bertipe bool?, tapi pemanggil
  // mengharapkan bool. `?? false` mengubah null menjadi false.
  //
  // Artinya: kalau dialog ditutup tanpa memilih, anggap TIDAK setuju.
  // Ini pilihan yang aman — lebih baik data tidak terhapus daripada
  // terhapus tanpa sengaja.
  return hasil ?? false;
}
