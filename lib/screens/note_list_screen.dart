// ============================================================
// FILE: lib/screens/note_list_screen.dart
// #Screen #NoteList — Halaman utama: menampilkan daftar catatan.
//
// INILAH MOMEN PENTING: StatelessWidget -> StatefulWidget.
//
// Sebelumnya halaman ini hanya menampilkan teks tetap, jadi cukup
// StatelessWidget. Sekarang ia punya DATA YANG BERUBAH (daftar catatan,
// status memuat, pesan error), sehingga butuh "tempat menyimpan state".
//
// Analogi OOP:
//   StatelessWidget = objek tanpa properti yang berubah (seperti struct)
//   StatefulWidget  = objek dengan properti yang bisa berubah + reaksi
//
// Alur hidup halaman ini:
//   1. initState()  -> dipanggil sekali saat halaman pertama dibuat
//   2. _muat()      -> ambil data dari penyimpanan (async)
//   3. setState()   -> beri tahu Flutter "data berubah, gambar ulang!"
//   4. build()      -> menggambar sesuai state terbaru
//   5. dispose()    -> dipanggil saat halaman ditutup (bersih-bersih)
// ============================================================

import 'package:material_ui/material_ui.dart';

import '../models/note.dart';
import '../services/note_storage.dart';
import '../widgets/dialog_konfirmasi.dart';
import '../widgets/note_card.dart';
import 'note_form_screen.dart';

// #Class #StatefulWidget — Widget yang punya state.
//
// Perhatikan: class ini HANYA menyimpan konfigurasi (parameter).
// Tempat menyimpan data yang berubah ada di class State di bawahnya.
// Ini pemisahan yang khas Flutter dan sering membingungkan pemula.
class NoteListScreen extends StatefulWidget {
  // #Constructor — Parameter `storage` opsional untuk keperluan TEST.
  //
  // Di aplikasi sungguhan, parameter ini tidak diisi, sehingga halaman
  // membuat NoteStorage sendiri. Di test, kita menyuntikkan penyimpanan
  // palsu (in-memory) agar test tidak menyentuh storage asli.
  //
  // Pola ini sama dengan yang kita pakai di NoteStorage (Langkah 4).
  const NoteListScreen({super.key, this.storage, this.onBukaPengaturan});

  // #Properti #Storage — Penyimpanan yang dipakai halaman ini.
  final NoteStorage? storage;

  // #Properti #OnBukaPengaturan — Aksi membuka halaman pengaturan.
  //
  // Dikirim dari app.dart. Dibuat opsional (boleh null) supaya
  // halaman ini tetap bisa dipakai di test tanpa pengaturan.
  final VoidCallback? onBukaPengaturan;

  // #Method #CreateState — Wajib ada di setiap StatefulWidget.
  // Ia menghubungkan widget (konfigurasi) dengan State (data + logika).
  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

// #Class #State — Tempat data yang berubah disimpan.
//
// Tanda `_` di depan nama berarti private: hanya dipakai di file ini.
// Ini konvensi Flutter, bukan aturan bahasa.
class _NoteListScreenState extends State<NoteListScreen> {
  // #Properti #Storage — Service penyimpanan, dibuat sekali saat halaman lahir.
  //
  // `late final` artinya: nilainya belum diisi sekarang, tapi akan
  // diisi sekali dan tidak berubah lagi. Cocok karena kita butuh
  // mengakses `widget.storage` yang baru tersedia di initState().
  late final NoteStorage _storage;

  // #Properti #Daftar — Data catatan yang sedang ditampilkan.
  // Diawali list kosong agar build() pertama tidak error.
  List<Note> _daftar = <Note>[];

  // #Properti #SedangMemuat — Penanda apakah data masih diambil.
  // Dipakai untuk menampilkan indikator loading.
  bool _sedangMemuat = true;

  // #Properti #PesanError — Kalau pengambilan data gagal, isi pesannya di sini.
  // `String?` artinya boleh kosong (null = tidak ada error).
  String? _pesanError;

  // ============================================================
  // STATE PENCARIAN
  // ============================================================

  // #Properti #SedangMencari — Apakah mode pencarian aktif.
  //
  // Mode ini mengubah tampilan AppBar: judul biasa berganti menjadi
  // kotak pencarian. Menyimpan status "mode" seperti ini adalah pola
  // yang sangat umum di Flutter.
  bool _sedangMencari = false;

  // #Properti #ControllerPencarian — Pengendali isi kotak pencarian.
  //
  // Sama seperti di form (Langkah 6), controller memegang teks yang
  // diketik dan memberi kita akses ke isinya lewat `.text`.
  //
  // Dibuat `late final` karena harus di-dispose di dispose().
  late final TextEditingController _controllerPencarian;

  // #Properti #KataKunci — Teks pencarian yang sedang aktif.
  //
  // Kenapa disimpan terpisah dari `_controllerPencarian.text`?
  // Karena kita hanya ingin MENYARING daftar saat pengguna mengetik,
  // dan menyimpan salinannya di state membuat `build()` tidak perlu
  // membaca controller setiap kali.
  String _kataKunci = '';

  // #Getter #DaftarTampil — Daftar yang BENAR-BENAR ditampilkan.
  //
  // Inilah inti fitur pencarian: satu tempat yang memutuskan
  // catatan mana yang lolos filter. Semua bagian lain (jumlah item,
  // empty state, daftar kartu) memakai getter ini, bukan `_daftar`
  // langsung. Dengan begitu, aturan penyaringan hanya ditulis SEKALI.
  List<Note> get _daftarTampil {
    // #Kondisi #TanpaPencarian — Tidak ada kata kunci = tampilkan semua.
    // Tanpa pengecekan ini, `contains('')` selalu true, tapi lebih
    // jelas dan lebih cepat kalau kita kembalikan list aslinya.
    if (_kataKunci.isEmpty) {
      return _daftar;
    }

    // #Langkah #Normalisasi — Ubah kata kunci ke huruf kecil.
    //
    // Kenapa? Agar "belanja", "Belanja", dan "BELANJA" dianggap sama.
    // Pencarian yang membedakan huruf besar/kecil terasa "rusak"
    // bagi pengguna.
    final kunci = _kataKunci.toLowerCase();

    // #Langkah #Saring — `where` menyaring, `toList` mengubah hasilnya
    // kembali menjadi List.
    //
    // `where` mengembalikan Iterable (mirip generator di PHP/JS) —
    // ia malas (lazy): baru benar-benar dihitung saat dipakai. Karena
    // ListView butuh `.length`, kita perlu `toList()`.
    return _daftar.where((note) {
      // #Langkah #Cocokkan — Cari di judul DAN isi.
      //
      // Pengguna biasanya mengingat kata kunci dari salah satunya,
      // jadi mencari di keduanya jauh lebih berguna daripada hanya judul.
      final judul = note.judul.toLowerCase();
      final isi = note.isi.toLowerCase();

      return judul.contains(kunci) || isi.contains(kunci);
    }).toList();
  }

  // #Method #InitState — Dipanggil SEKALI saat halaman pertama kali dibuat.
  //
  // Di sini kita mulai mengambil data. Perhatikan: kita TIDAK boleh
  // memakai `await` langsung di initState. Karena itu _muat() dipanggil
  // tanpa await — ia berjalan di latar belakang dan akan memanggil
  // setState() sendiri saat selesai.
  @override
  void initState() {
    super.initState(); // wajib: menjalankan initState milik induk

    // #Langkah #SiapkanStorage — Pakai yang disuntikkan, atau buat baru.
    _storage = widget.storage ?? NoteStorage();

    // #Langkah #SiapkanController — Buat pengendali kotak pencarian.
    _controllerPencarian = TextEditingController();

    // #Langkah #MuatData — Mulai memuat. Tidak di-await, sengaja.
    _muat();
  }

  // #Method #Dispose — Membersihkan controller saat halaman ditutup.
  //
  // WAJIB. Tanpa ini terjadi memory leak, sama seperti di form (Langkah 6).
  @override
  void dispose() {
    _controllerPencarian.dispose();
    super.dispose();
  }

  // #Method #BukaPencarian — Mengaktifkan mode pencarian.
  void _bukaPencarian() {
    setState(() {
      _sedangMencari = true;
    });

    // #Langkah #Fokus — Pindahkan fokus keyboard ke kotak pencarian
    // agar pengguna bisa langsung mengetik tanpa menyentuh kotak dulu.
    //
    // `Future.microtask` menunda perintah ini sampai Flutter selesai
    // menggambar ulang AppBar. Kalau dipanggil langsung, widget
    // kotak pencariannya belum ada sehingga fokus akan gagal.
    Future.microtask(() {
      if (!mounted) return;
      _fokusPencarian.requestFocus();
    });
  }

  // #Method #TutupPencarian — Mematikan mode pencarian dan mengosongkan filter.
  void _tutupPencarian() {
    setState(() {
      _sedangMencari = false;
      _kataKunci = '';
      _controllerPencarian.clear();
    });

    // #Langkah #TutupKeyboard — Sembunyikan keyboard di HP.
    FocusScope.of(context).unfocus();
  }

  // #Properti #FokusPencarian — Pengendali fokus untuk kotak pencarian.
  final _fokusPencarian = FocusNode();

  // #Method #KataKunciBerubah — Dipanggil setiap kali pengguna mengetik.
  void _kataKunciBerubah(String nilai) {
    // #Langkah #SetState — Perbarui state agar daftar disaring ulang.
    //
    // Setiap ketikan memicu build() ulang. Untuk daftar catatan
    // berukuran wajar ini sangat cepat, jadi tidak perlu optimasi
    // tambahan seperti debounce.
    setState(() {
      _kataKunci = nilai;
    });
  }

  // #Method #Muat — Mengambil daftar catatan dari penyimpanan.
  //
  // Kata `async` membuat method ini mengembalikan Future<void>,
  // sehingga boleh memakai `await` di dalamnya.
  Future<void> _muat() async {
    // #Langkah #TandaiMemuat — Tampilkan indikator loading.
    //
    // Kenapa dibungkus setState? Karena perubahan variabel saja tidak
    // cukup — Flutter perlu diberi tahu agar menggambar ulang layar.
    setState(() {
      _sedangMemuat = true;
      _pesanError = null;
    });

    // #Langkah #Coba — Ambil data, tapi siap kalau gagal.
    try {
      final hasil = await _storage.muatSemua();

      // #Langkah #CekMasihHidup — PENTING dan sering terlewat.
      //
      // Kalau pengguna menutup halaman ini sebelum data selesai dimuat,
      // memanggil setState() akan menimbulkan error "setState() called
      // after dispose()". Pengecekan `mounted` mencegahnya.
      if (!mounted) return;

      setState(() {
        _daftar = hasil;
        _sedangMemuat = false;
      });
    } catch (e) {
      // #Langkah #TanganiError — Penyimpanan gagal (misalnya izin ditolak).
      // Tampilkan pesan yang bisa dimengerti pengguna, bukan pesan teknis.
      if (!mounted) return;

      setState(() {
        _pesanError = 'Gagal memuat catatan. Coba lagi.';
        _sedangMemuat = false;
      });
    }
  }

  // #Method #Build — Menggambar halaman sesuai state saat ini.
  //
  // Perhatikan strukturnya: SATU method, TIGA kemungkinan tampilan.
  // Ini pola yang sangat umum di Flutter: pilih tampilan berdasarkan state.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // #Widget #AppBar — Bilah judul atas.
      //
      // Perhatikan: AppBar ini BERUBAH BENTUK tergantung `_sedangMencari`.
      // Saat pencarian aktif, judul diganti kotak input dan tombol
      // di kanan berganti menjadi tombol tutup. Ini pola "mode" yang
      // sangat umum di aplikasi Android.
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,

        // #Kondisi #ModeMencari — Tampilan AppBar berbeda per mode.
        title: _sedangMencari
            // #Widget #TextField #Pencarian — Kotak input di dalam AppBar.
            ? TextField(
                controller: _controllerPencarian,
                focusNode: _fokusPencarian,

                // #Properti #OnChanged — Dipanggil setiap ketikan.
                onChanged: _kataKunciBerubah,

                // #Properti #Autofocus — Langsung siap menerima ketikan.
                autofocus: true,

                // #Properti #TextInputAction — Tombol "cari" di keyboard.
                textInputAction: TextInputAction.search,

                // #Properti #Decoration — Tanpa garis bawah, agar
                // menyatu dengan AppBar.
                decoration: const InputDecoration(
                  hintText: 'Cari judul atau isi catatan...',
                  border: InputBorder.none,
                ),

                // #Properti #Style — Warna teks mengikuti tema.
                style: Theme.of(context).textTheme.titleMedium,
              )
            // #Widget #Text #JudulBiasa — Mode normal.
            : const Text('Catatan Harian'),

        // #Properti #Leading — Tombol di sisi KIRI AppBar.
        //
        // Saat mencari, tampilkan panah kembali untuk keluar dari
        // mode pencarian.
        leading: _sedangMencari
            ? IconButton(
                onPressed: _tutupPencarian,
                tooltip: 'Tutup pencarian',
                icon: const Icon(Icons.arrow_back),
              )
            : null,

        // #Properti #Actions — Tombol tambahan di kanan AppBar.
        actions: [
          // #Kondisi #TombolKanan — Berbeda per mode.
          if (_sedangMencari)
            // #Tombol #Bersihkan — Hanya muncul kalau ada teks.
            //
            // `ValueListenableBuilder` mendengarkan perubahan pada
            // controller tanpa perlu setState tambahan. Ia menggambar
            // ulang HANYA bagian ini, bukan seluruh halaman.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controllerPencarian,
              builder: (context, nilai, _) {
                // #Kondisi #AdaTeks — Sembunyikan tombol saat kotak kosong.
                if (nilai.text.isEmpty) {
                  return const SizedBox.shrink();
                }

                return IconButton(
                  onPressed: () {
                    _controllerPencarian.clear();
                    _kataKunciBerubah('');
                    _fokusPencarian.requestFocus();
                  },
                  tooltip: 'Bersihkan pencarian',
                  icon: const Icon(Icons.close),
                );
              },
            )
          else ...[
            // #Tombol #Cari — Membuka mode pencarian.
            //
            // Dinonaktifkan saat data masih dimuat atau kosong:
            // tidak ada gunanya mencari di daftar kosong.
            IconButton(
              onPressed: (_sedangMemuat || _daftar.isEmpty)
                  ? null
                  : _bukaPencarian,
              tooltip: 'Cari catatan',
              icon: const Icon(Icons.search),
            ),

            // #Tombol #MuatUlang — Berguna saat pengembangan
            // dan untuk pengguna yang ingin memuat ulang data.
            IconButton(
              onPressed: _sedangMemuat ? null : _muat,
              tooltip: 'Muat ulang',
              icon: const Icon(Icons.refresh),
            ),

            // #Tombol #Pengaturan — Membuka halaman pengaturan tema.
            //
            // Hanya ditampilkan kalau callback-nya tersedia, supaya
            // test lama yang tidak mengirim callback tetap berjalan.
            if (widget.onBukaPengaturan != null)
              IconButton(
                onPressed: widget.onBukaPengaturan,
                tooltip: 'Pengaturan',
                icon: const Icon(Icons.settings),
              ),
          ],
        ],
      ),

      // #Properti #Body — Isi halaman. Di sini kita MEMILIH tampilan
      // berdasarkan state, memakai method bantuan di bawah.
      body: _bangunBody(),

      // #Widget #FloatingActionButton — Tombol bulat mengambang.
      // Untuk sementara menampilkan pesan; Langkah 6 akan menggantinya
      // dengan navigasi ke halaman form.
      floatingActionButton: FloatingActionButton(
        onPressed: _tombolTambahDitekan,
        tooltip: 'Tambah catatan',
        child: const Icon(Icons.add),
      ),
    );
  }

  // #Method #BangunBody — Memilih tampilan yang tepat.
  //
  // Memecah logika ke method terpisah membuat build() tetap pendek
  // dan mudah dibaca. Ini lebih baik daripada if-else bertingkat
  // di dalam build().
  Widget _bangunBody() {
    // #Kondisi1 #Memuat — Data belum siap.
    if (_sedangMemuat) {
      return const Center(child: CircularProgressIndicator());
    }

    // #Kondisi2 #Error — Pengambilan data gagal.
    if (_pesanError != null) {
      return _bangunTampilanError();
    }

    // #Kondisi3 #Kosong — Tidak ada catatan sama sekali.
    //
    // PENTING: yang dicek adalah `_daftar` (data asli), BUKAN
    // `_daftarTampil`. Alasannya: kalau pengguna sedang mencari dan
    // tidak ada hasil, kita tidak ingin menampilkan "Belum ada catatan"
    // — itu menyesatkan, seolah semua catatannya hilang.
    if (_daftar.isEmpty) {
      return _bangunTampilanKosong();
    }

    // #Kondisi4 #TidakAdaHasil — Ada catatan, tapi tidak ada yang cocok.
    if (_daftarTampil.isEmpty) {
      return _bangunTampilanTidakDitemukan();
    }

    // #Kondisi5 #AdaData — Tampilkan daftarnya.
    return _bangunDaftar();
  }

  // #Method #BangunTampilanTidakDitemukan — Hasil pencarian kosong.
  //
  // Dibedakan dari empty state biasa. Kalau digabung, pengguna akan
  // bingung: "catatan saya hilang?" padahal hanya tidak cocok dengan
  // kata kunci. Pesan yang tepat + tombol bersihkan jauh lebih menolong.
  Widget _bangunTampilanTidakDitemukan() {
    final warna = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 72,
              color: warna.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),

            Text(
              'Tidak ada hasil',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            // #Widget #Text #KataKunci — Tampilkan apa yang dicari,
            // supaya pengguna sadar mungkin ada salah ketik.
            Text(
              'Tidak ada catatan yang cocok dengan "$_kataKunci".',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: warna.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // #Widget #OutlinedButton — Jalan keluar yang jelas.
            OutlinedButton.icon(
              onPressed: () {
                _controllerPencarian.clear();
                _kataKunciBerubah('');
                _fokusPencarian.requestFocus();
              },
              icon: const Icon(Icons.close),
              label: const Text('Bersihkan pencarian'),
            ),
          ],
        ),
      ),
    );
  }

  // #Method #BangunTampilanKosong — "Empty state".
  //
  // Empty state yang baik bukan sekadar "tidak ada data", tapi memberi
  // tahu pengguna APA yang harus dilakukan. Ini detail kecil yang
  // membedakan aplikasi rapi dari aplikasi asal jadi.
  Widget _bangunTampilanKosong() {
    final warna = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        // #Properti #Padding — Beri jarak dari tepi layar.
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // #Widget #Icon — Ikon besar dan pudar sebagai hiasan.
            Icon(
              Icons.menu_book_outlined,
              size: 72,
              color: warna.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),

            // #Widget #Text #JudulKosong
            Text(
              'Belum ada catatan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            // #Widget #Text #Petunjuk — Beri tahu langkah berikutnya.
            Text(
              'Tekan tombol + di pojok kanan bawah untuk\nmembuat catatan pertama Anda.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: warna.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // #Method #BangunTampilanError — Tampilan saat data gagal dimuat.
  Widget _bangunTampilanError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),

            // #Widget #Text #PesanError — Teks dari state.
            // Tanda `!` berarti "saya yakin ini tidak null".
            // Aman di sini karena _bangunTampilanError hanya dipanggil
            // saat _pesanError sudah dipastikan tidak null.
            Text(_pesanError!, textAlign: TextAlign.center),

            const SizedBox(height: 16),

            // #Widget #FilledButton — Tombol "Coba lagi".
            FilledButton.icon(
              onPressed: _muat,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // #Method #BangunDaftar — Daftar catatan yang bisa digulir.
  Widget _bangunDaftar() {
    // #Widget #RefreshIndicator — Tarik ke bawah untuk memuat ulang.
    // Ini gestur yang sudah dikenal pengguna Android.
    return RefreshIndicator(
      onRefresh: _muat,

      // #Widget #ListView.builder — Cara EFISIEN menampilkan daftar panjang.
      //
      // Bedanya dengan ListView(children: [...]): `.builder` hanya membuat
      // widget yang TERLIHAT di layar. Kalau Anda punya 1000 catatan,
      // Flutter hanya menggambar ~10 sekaligus. Ini yang membuat daftar
      // tetap ringan.
      child: ListView.builder(
        // #Properti #Padding — Beri ruang di atas dan bawah daftar,
        // supaya kartu pertama tidak menempel ke AppBar dan kartu
        // terakhir tidak tertutup tombol +.
        padding: const EdgeInsets.only(top: 6, bottom: 88),

        // #Properti #ItemCount — Jumlah item. Flutter memakai ini untuk
        // tahu kapan daftar berakhir.
        //
        // Memakai `_daftarTampil` (hasil saringan), bukan `_daftar`.
        itemCount: _daftarTampil.length,

        // #Properti #ItemBuilder — Fungsi yang dipanggil untuk SETIAP item.
        // Parameter `index` adalah posisi item (0, 1, 2, ...).
        itemBuilder: (context, index) {
          // #Langkah #AmbilItem — Ambil dari daftar yang sudah disaring,
          // supaya indeksnya cocok dengan yang digambar.
          final catatan = _daftarTampil[index];

          // #Widget #NoteCard — Kartu yang kita buat di widgets/note_card.dart.
          //
          // `key` WAJIB diberi nilai unik agar Flutter bisa melacak
          // kartu mana yang mana saat daftar berubah (misalnya setelah
          // menghapus item). Tanpa key, Flutter bisa "menempelkan" state
          // kartu ke item yang salah.
          return NoteCard(
            key: ValueKey(catatan.id),
            catatan: catatan,
            onTap: () => _bukaCatatan(catatan),
            onHapus: () => _hapusCatatan(catatan),
          );
        },
      ),
    );
  }

  // #Method #TombolTambahDitekan — Membuka form dalam mode TAMBAH.
  //
  // Ini contoh NAVIGASI di Flutter:
  //   Navigator.push()  -> membuka halaman baru (ditumpuk di atas)
  //   Navigator.pop()   -> menutup halaman dan kembali ke sebelumnya
  //
  // Bayangkan sebagai tumpukan kartu: push = menaruh kartu baru di atas,
  // pop = mengambil kartu teratas.
  //
  // `await` di sini artinya: tunggu sampai halaman form ditutup,
  // lalu terima nilai yang dikirim balik lewat Navigator.pop(context, hasil).
  Future<void> _tombolTambahDitekan() async {
    // #Langkah #BukaForm — Buka halaman form tanpa catatan awal (= mode tambah).
    //
    // `MaterialPageRoute` adalah jenis transisi halaman (slide dari kanan).
    // `builder` adalah fungsi yang membuat isi halaman tersebut.
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => NoteFormScreen(storage: _storage),
      ),
    );

    // #Langkah #CekHasil — Kalau form mengembalikan `true`, berarti
    // ada data baru yang tersimpan. Muat ulang daftar agar tampil.
    //
    // Kalau pengguna menekan "Batal", hasilnya null/false, dan kita
    // tidak perlu melakukan apa pun.
    if (berhasil == true) {
      await _muat();
    }
  }

  // #Method #BukaCatatan — Membuka form dalam mode EDIT.
  //
  // Bedanya dengan _tombolTambahDitekan hanya satu: kita mengirim
  // `catatanAwal`, sehingga form tahu ia harus mengisi kolom dengan
  // data lama dan menyimpan sebagai perubahan, bukan catatan baru.
  Future<void> _bukaCatatan(Note catatan) async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => NoteFormScreen(
          catatanAwal: catatan,
          storage: _storage,
        ),
      ),
    );

    if (berhasil == true) {
      await _muat();
    }
  }

  // #Method #HapusCatatan — Menghapus catatan dengan konfirmasi lebih dulu.
  //
  // Alurnya sengaja dibuat tiga tahap:
  //   1. Tanya pengguna (dialog)
  //   2. Hapus dari penyimpanan
  //   3. Perbarui tampilan + beri umpan balik
  //
  // Langkah 1 tidak boleh dilewati. Menghapus data tanpa konfirmasi
  // adalah salah satu kesalahan UX paling umum di aplikasi pemula —
  // dan satu-satunya yang tidak bisa di-undo oleh pengguna.
  Future<void> _hapusCatatan(Note catatan) async {
    // #Langkah #Konfirmasi — Tampilkan dialog dan tunggu jawabannya.
    //
    // `await` di sini penting: kita menunggu sampai pengguna memilih.
    final setuju = await tampilkanDialogKonfirmasi(
      context,
      judul: 'Hapus catatan?',
      pesan: '"${catatan.judul}" akan dihapus permanen.\n'
          'Tindakan ini tidak bisa dibatalkan.',
      labelAksi: 'Hapus',
    );

    // #Langkah #Batal — Pengguna menolak. Berhenti tanpa melakukan apa pun.
    if (!setuju) return;

    // #Langkah #CekMounted — Setelah await, halaman bisa saja sudah
    // ditutup. Ini pengecekan yang sama seperti di tempat lain.
    if (!mounted) return;

    // #Langkah #CobaHapus — Hapus dari penyimpanan.
    try {
      await _storage.hapus(catatan.id);

      if (!mounted) return;

      // #Langkah #MuatUlang — Ambil daftar terbaru dari penyimpanan.
      //
      // Kenapa tidak cukup `_daftar.remove(catatan)` lalu setState?
      // Karena itu mengubah tampilan tanpa memastikan penyimpanan
      // benar-benar terhapus. Dengan memuat ulang, tampilan SELALU
      // mencerminkan isi penyimpanan yang sebenarnya.
      await _muat();

      if (!mounted) return;

      // #Langkah #UmpanBalik — Beri tahu pengguna bahwa berhasil.
      //
      // SnackBar penting setelah aksi yang menghilangkan sesuatu:
      // tanpa itu, pengguna mungkin bingung apakah catatan terhapus
      // atau hanya tersembunyi.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${catatan.judul}" dihapus'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // #Langkah #GagalHapus — Penyimpanan error.
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus catatan. Coba lagi.')),
      );
    }
  }
}
