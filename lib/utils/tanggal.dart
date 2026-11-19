// ============================================================
// FILE: lib/utils/tanggal.dart
// #Util #FormatTanggal — Mengubah DateTime menjadi teks Indonesia.
//
// Kenapa tidak pakai package `intl` saja? Bisa, tapi menambah dependency
// berarti menambah yang harus dipelajari. Untuk kebutuhan kita
// (tanggal pendek berbahasa Indonesia), fungsi kecil ini sudah cukup.
//
// Kalau nanti aplikasi Anda butuh format tanggal yang rumit
// (misalnya "2 hari yang lalu", atau format per negara), baru
// tambahkan `intl` dengan `flutter pub add intl`.
// ============================================================

// #Konstanta #NamaBulan — Daftar nama bulan dalam Bahasa Indonesia.
//
// `const` di luar class artinya konstanta tingkat file: dibuat sekali,
// dipakai bersama. Tanda `_` membuatnya private (hanya file ini).
//
// Perhatikan indeksnya: list dimulai dari 0, sedangkan bulan dimulai
// dari 1. Jadi nanti kita akses dengan `bulan - 1`.
const List<String> _namaBulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

// #Fungsi #FormatTanggal — Menghasilkan teks seperti "19 Nov 2026, 17:13".
//
// Parameter `waktu` bertipe DateTime (wajib).
// Hasilnya String yang siap ditampilkan di layar.
String formatTanggal(DateTime waktu) {
  // #Langkah #AmbilBagian — Ambil komponen tanggal satu per satu.
  final hari = waktu.day;
  final bulan = _namaBulan[waktu.month - 1];
  final tahun = waktu.year;

  // #Langkah #Jam — padLeft(2, '0') menambah nol di depan kalau kurang
  // dari 2 digit. Contoh: 7 -> "07", 13 -> "13".
  // Tanpa ini, jam 7:05 akan tampil sebagai "7:5" yang terlihat janggal.
  final jam = waktu.hour.toString().padLeft(2, '0');
  final menit = waktu.minute.toString().padLeft(2, '0');

  // #Langkah #Gabung — String interpolation: masukkan variabel ke dalam teks
  // dengan tanda $variabel. Untuk ekspresi, pakai ${...}.
  return '$hari $bulan $tahun, $jam:$menit';
}

// #Fungsi #FormatTanggalRelatif — Versi ramah pengguna untuk daftar catatan.
//
// Menghasilkan "Hari ini, 17:13", "Kemarin, 09:20", atau
// "19 Nov 2026, 17:13" untuk tanggal yang lebih lama.
//
// Ini detail kecil yang membuat aplikasi terasa lebih "manusiawi".
String formatTanggalRelatif(DateTime waktu) {
  // #Langkah #WaktuSekarang — Ambil waktu sekarang sebagai pembanding.
  final sekarang = DateTime.now();

  // #Langkah #HitungSelisihHari — Bandingkan TANGGAL saja, bukan jam.
  //
  // Kenapa? Kalau kita bandingkan DateTime utuh, catatan yang dibuat
  // kemarin pukul 23:00 dan sekarang pukul 01:00 akan dianggap
  // "kurang dari 1 hari" padahal sudah beda hari.
  //
  // DateTime(y, m, d) membuat tanggal tanpa jam (00:00), sehingga
  // selisihnya selalu bilangan bulat hari.
  final tanggalIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
  final tanggalCatatan = DateTime(waktu.year, waktu.month, waktu.day);

  // #Langkah #Selisih — difference() menghasilkan Duration.
  // `.inDays` mengubahnya menjadi jumlah hari bulat.
  final selisihHari = tanggalIni.difference(tanggalCatatan).inDays;

  // #Langkah #JamSaja — Ambil bagian jam:menit untuk ditampilkan.
  final jam = waktu.hour.toString().padLeft(2, '0');
  final menit = waktu.minute.toString().padLeft(2, '0');

  // #Langkah #PilihFormat — Tiga kemungkinan hasil.
  if (selisihHari == 0) {
    return 'Hari ini, $jam:$menit';
  }
  if (selisihHari == 1) {
    return 'Kemarin, $jam:$menit';
  }
  return formatTanggal(waktu);
}
