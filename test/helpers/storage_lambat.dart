// ============================================================
// FILE: test/helpers/storage_lambat.dart
// #Helper #Test #StorageLambat — Penyimpanan palsu yang sengaja lambat.
//
// KENAPA FILE INI ADA?
//
// Saat menguji tampilan "sedang memuat", penyimpanan in-memory biasa
// terlalu cepat: ia selesai dalam satu microtask, sehingga indikator
// loading hilang sebelum test sempat melihatnya.
//
// Dengan menambahkan jeda buatan (misalnya 300 ms), kita bisa memastikan
// tampilan loading benar-benar muncul, seperti yang dialami pengguna
// di perangkat sungguhan.
//
// Ini teknik umum dalam pengujian: membuat tiruan (fake) yang
// perilakunya bisa kita kendalikan.
// ============================================================

import 'package:catatan_harian/models/note.dart';
import 'package:catatan_harian/services/note_storage.dart';

// #Class #StorageLambat — Subclass NoteStorage yang menambah jeda.
//
// `extends NoteStorage` artinya mewarisi semua method (muatSemua,
// simpanSemua, tambah, dst). Kita hanya MENIMPA satu method yang
// perlu diperlambat. Ini contoh nyata inheritance + polymorphism
// dalam Dart: pemanggil tidak tahu (dan tidak peduli) bahwa ini
// versi lambat.
class StorageLambat extends NoteStorage {
  // #Constructor — Meneruskan parameter ke induk.
  //
  // `super(preferensi: preferensi)` memanggil constructor induk.
  // Tanpa ini, NoteStorage akan membuat SharedPreferencesAsync sendiri,
  // yang di test bisa menimbulkan error karena platform belum disiapkan.
  StorageLambat({
    super.preferensi,
    this.jeda = const Duration(milliseconds: 300),
  });

  // #Properti #Jeda — Lama waktu tunggu buatan.
  final Duration jeda;

  // #Method #MuatSemua — @override menimpa versi induk.
  //
  // `super.muatSemua()` memanggil versi induk (yang benar-benar membaca
  // penyimpanan), lalu kita tambahkan jeda sebelum mengembalikannya.
  @override
  Future<List<Note>> muatSemua() async {
    // #Langkah #Tunggu — Simulasi penyimpanan yang lambat.
    await Future<void>.delayed(jeda);

    // #Langkah #Delegasi — Serahkan pekerjaan sebenarnya ke induk.
    return super.muatSemua();
  }
}
