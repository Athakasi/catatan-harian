// ============================================================
// FILE: lib/widgets/note_card.dart
// #Widget #NoteCard — Satu kartu catatan di dalam daftar.
//
// Widget ini dipisah dari halaman karena:
//   1. Bisa dipakai ulang di tempat lain (misalnya halaman pencarian).
//   2. Halaman daftar jadi lebih mudah dibaca.
//   3. Bisa diuji sendiri tanpa membuka seluruh aplikasi.
//
// Prinsipnya sama seperti membuat "partial" atau "component" di
// PHP/Laravel atau React: satu bagian tampilan = satu file.
// ============================================================

import 'package:material_ui/material_ui.dart';

import '../models/note.dart';
import '../utils/tanggal.dart';

// #Class #StatelessWidget — Kartu tidak menyimpan data sendiri.
// Semua yang ia tampilkan datang dari luar lewat constructor.
// Widget seperti ini disebut "dumb widget" atau "presentational widget".
class NoteCard extends StatelessWidget {
  // #Constructor — Menerima satu catatan.
  //
  // `required this.catatan` = wajib diisi, langsung masuk ke properti.
  const NoteCard({
    super.key,
    required this.catatan,
    this.onTap,
    this.onHapus,
  });

  // #Properti #Catatan — Data yang ditampilkan.
  final Note catatan;

  // #Properti #OnTap — Fungsi yang dipanggil saat kartu disentuh.
  //
  // Tipe `VoidCallback?` artinya "fungsi tanpa parameter dan tanpa
  // nilai balik, boleh kosong (null)".
  //
  // Tanda `?` penting: kalau null, kartu tetap bisa ditampilkan,
  // hanya saja tidak bisa disentuh. Jadi kartu ini fleksibel.
  final VoidCallback? onTap;

  // #Properti #OnHapus — Fungsi yang dipanggil saat tombol hapus ditekan.
  //
  // Sama seperti onTap, boleh null. Kalau null, tombol hapus tidak
  // ditampilkan sama sekali — kartu bisa dipakai di tempat yang
  // memang tidak mengizinkan penghapusan.
  final VoidCallback? onHapus;

  // #Method #Build — Menyusun tampilan kartu.
  @override
  Widget build(BuildContext context) {
    // #Ambil #Tema — Ambil palet warna aplikasi supaya kartu otomatis
    // serasi kalau tema di app.dart diganti.
    final warna = Theme.of(context).colorScheme;

    // #Widget #Card — Kotak dengan sudut membulat dan bayangan tipis.
    return Card(
      // #Properti #Margin — Jarak kartu ke kartu lain.
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      // #Properti #ClipBehavior — Memotong isi agar tidak keluar dari
      // sudut membulat saat kartu disentuh (efek ripple tetap rapi).
      clipBehavior: Clip.antiAlias,

      // #Widget #InkWell — Memberi efek "splash" saat disentuh.
      // Harus berada DI DALAM Card agar efeknya terpotong rapi.
      child: InkWell(
        // #Properti #OnTap — Teruskan aksi dari luar. Kalau null,
        // efek sentuh otomatis mati.
        onTap: onTap,

        child: Padding(
          // #Properti #Padding — Ruang kosong di dalam kartu.
          padding: const EdgeInsets.all(14),

          child: Column(
            // #Properti #CrossAxisAlignment — Ratakan anak-anaknya ke kiri.
            // Default-nya center, yang membuat teks panjang terlihat aneh.
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // #Widget #Text #Judul — Judul catatan, tebal.
              Text(
                catatan.judul,
                // #Properti #Style — Gaya teks dari tema (bukan ukuran
                // manual), supaya konsisten dengan seluruh aplikasi.
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),

                // #Properti #MaxLines — Batasi 1 baris.
                maxLines: 1,

                // #Properti #Overflow — Kalau kepanjangan, potong dengan "...".
                overflow: TextOverflow.ellipsis,
              ),

              // #Widget #SizedBox — Jarak vertikal 6 pixel.
              const SizedBox(height: 6),

              // #Widget #Text #Isi — Cuplikan isi catatan.
              Text(
                catatan.isi,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  // #Properti #Color — Warna lebih pudar agar judul tetap
                  // jadi fokus utama.
                  color: warna.onSurfaceVariant,
                ),

                // #Properti #MaxLines — Cukup 2 baris sebagai cuplikan.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // #Widget #Row — Menyusun anak secara HORIZONTAL.
              // Di sini: ikon jam + teks tanggal + tombol hapus.
              Row(
                children: [
                  // #Widget #Icon — Ikon kecil sebagai penanda waktu.
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: warna.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),

                  // #Widget #Text #Tanggal — Waktu terakhir diubah,
                  // ditampilkan dalam format ramah ("Hari ini, 17:13").
                  Text(
                    formatTanggalRelatif(catatan.diubahPada),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: warna.onSurfaceVariant,
                    ),
                  ),

                  // #Widget #Spacer — Mengisi SEMUA ruang kosong yang
                  // tersisa di antara anak-anak Row.
                  //
                  // Efeknya: semua yang ada di kiri didorong ke kiri,
                  // dan semua yang ada di kanan didorong ke kanan.
                  // Ini cara paling sederhana membuat tata letak
                  // "kiri-kanan" di Flutter.
                  const Spacer(),

                  // #Widget #IconButton #Hapus — Hanya muncul kalau
                  // onHapus diisi. Pola `if (...)` di dalam list widget
                  // disebut "collection if" — khas Dart, tidak ada di PHP/JS.
                  //
                  // Kalau onHapus null, ekspresi ini menghasilkan list
                  // kosong, sehingga tidak ada tombol yang digambar.
                  if (onHapus != null)
                    IconButton(
                      // #Properti #OnPressed — Teruskan aksi dari luar.
                      onPressed: onHapus,

                      // #Properti #Tooltip — Teks bantuan saat kursor
                      // diarahkan (di web/desktop) atau ditekan lama (HP).
                      tooltip: 'Hapus catatan',

                      // #Properti #IconSize — Ukuran ikon lebih kecil dari
                      // default agar tidak mendominasi kartu.
                      iconSize: 20,

                      // #Properti #VisualDensity — Membuat area sentuh
                      // lebih rapat, sehingga tombol tidak memakan
                      // banyak ruang vertikal.
                      visualDensity: VisualDensity.compact,

                      // #Properti #Color — Warna error (merah) menandakan
                      // aksi berbahaya.
                      color: warna.error,

                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
