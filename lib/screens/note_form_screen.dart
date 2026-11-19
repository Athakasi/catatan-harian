// ============================================================
// FILE: lib/screens/note_form_screen.dart
// #Screen #NoteForm — Halaman tambah & edit catatan (satu halaman, dua mode).
//
// Kenapa satu halaman untuk dua keperluan?
// Karena form-nya IDENTIK. Yang berbeda hanya:
//   - judul AppBar ("Catatan Baru" vs "Edit Catatan")
//   - apa yang terjadi saat tombol Simpan ditekan (tambah vs perbarui)
//
// Membuat dua file terpisah berarti menduplikasi ~150 baris kode yang
// sama. Kalau nanti ada perubahan desain, Anda harus mengubah dua tempat
// dan berisiko lupa salah satunya.
//
// Cara membedakannya: parameter `catatanAwal`.
//   null      -> mode TAMBAH
//   tidak null -> mode EDIT
// ============================================================

import 'package:material_ui/material_ui.dart';

import '../models/note.dart';
import '../services/note_storage.dart';

// #Class #StatefulWidget — Form butuh state karena:
//   - isi TextField berubah saat pengguna mengetik
//   - ada status "sedang menyimpan"
//   - ada status validasi error
class NoteFormScreen extends StatefulWidget {
  // #Constructor
  //
  // `catatanAwal` opsional: kalau diisi, halaman masuk mode EDIT.
  // `storage` opsional: untuk keperluan test (dependency injection).
  const NoteFormScreen({
    super.key,
    this.catatanAwal,
    this.storage,
  });

  // #Properti #CatatanAwal — Catatan yang akan disunting (null = buat baru).
  final Note? catatanAwal;

  // #Properti #Storage — Penyimpanan yang dipakai.
  final NoteStorage? storage;

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  // #Properti #FormKey — "Pegangan" ke widget Form.
  //
  // Gunanya untuk memanggil validasi dari luar widget Form, misalnya
  // saat tombol Simpan ditekan. Tanpa ini, kita tidak punya cara
  // memeriksa apakah semua input valid.
  final _formKey = GlobalKey<FormState>();

  // #Properti #Controller — Pengendali isi TextField.
  //
  // TextEditingController menyimpan teks yang diketik DAN memberi kita
  // akses ke teks itu (`.text`). Padanan di JS: elemen input + state.
  //
  // `late final` karena kita perlu mengisinya di initState() dengan
  // nilai awal dari catatan yang sedang diedit.
  late final TextEditingController _controllerJudul;
  late final TextEditingController _controllerIsi;

  // #Properti #Fokus — Pengendali fokus keyboard.
  //
  // Dipakai untuk memindahkan kursor dari kolom judul ke kolom isi
  // saat pengguna menekan "Next" di keyboard. Detail kecil yang
  // membuat form terasa nyaman.
  final _fokusIsi = FocusNode();

  // #Properti #SedangMenyimpan — Mencegah tombol ditekan dua kali.
  // Tanpa ini, pengguna yang menekan cepat bisa menyimpan catatan ganda.
  bool _sedangMenyimpan = false;

  // #Getter #ModeEdit — Membaca properti widget untuk menentukan mode.
  //
  // `widget.catatanAwal` mengakses properti milik StatefulWidget induk.
  // Di dalam State, kita WAJIB memakai `widget.` untuk mengaksesnya.
  // Ini salah satu hal yang paling sering terlupa pemula.
  bool get _modeEdit => widget.catatanAwal != null;

  // #Method #InitState — Mengisi controller dengan data awal.
  @override
  void initState() {
    super.initState();

    // #Langkah #IsiAwal — Kalau mode edit, isi kolom dengan data lama.
    // Kalau mode tambah, `?.` membuat hasilnya null, lalu `?? ''`
    // menggantinya dengan teks kosong.
    //
    // Operator `?.` disebut "null-aware access": kalau objeknya null,
    // jangan akses propertinya, langsung kembalikan null.
    _controllerJudul = TextEditingController(
      text: widget.catatanAwal?.judul ?? '',
    );
    _controllerIsi = TextEditingController(
      text: widget.catatanAwal?.isi ?? '',
    );
  }

  // #Method #Dispose — WAJIB: membersihkan controller & fokus.
  //
  // TextEditingController dan FocusNode memakai memori di luar sistem
  // Dart. Kalau tidak dibersihkan, terjadi "memory leak" — memori terus
  // bertambah setiap kali halaman dibuka dan ditutup.
  //
  // Flutter akan menampilkan peringatan di console kalau Anda lupa.
  @override
  void dispose() {
    _controllerJudul.dispose();
    _controllerIsi.dispose();
    _fokusIsi.dispose();
    super.dispose();  // wajib dipanggil paling akhir
  }

  // #Method #Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // #Widget #AppBar — Judul berubah sesuai mode.
      appBar: AppBar(
        title: Text(_modeEdit ? 'Edit Catatan' : 'Catatan Baru'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),

      // #Widget #Form — Pembungkus yang mengelola validasi semua input.
      //
      // Tanpa Form, kita harus memeriksa setiap TextFormField satu per satu.
      // Dengan Form, cukup `_formKey.currentState!.validate()` dan semua
      // validator dijalankan sekaligus.
      body: Form(
        key: _formKey,

        child: ListView(
          // #Properti #Padding — Ruang di sekitar form.
          padding: const EdgeInsets.all(16),

          children: [
            // #Widget #TextFormField #Judul
            TextFormField(
              controller: _controllerJudul,

              // #Properti #Decoration — Tampilan kotak input (label, border).
              decoration: const InputDecoration(
                labelText: 'Judul',
                hintText: 'Misalnya: Belanja Bulanan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),

              // #Properti #TextInputAction — Tombol apa yang muncul di
              // keyboard. `next` menampilkan panah "berikutnya".
              textInputAction: TextInputAction.next,

              // #Properti #OnFieldSubmitted — Dipanggil saat "Next" ditekan.
              // Kita pindahkan fokus ke kolom isi.
              onFieldSubmitted: (_) => _fokusIsi.requestFocus(),

              // #Properti #Validator — Fungsi yang menentukan valid/tidak.
              //
              // Mengembalikan String = ada error (teks itu ditampilkan).
              // Mengembalikan null   = valid.
              //
              // Perhatikan: validator TIDAK dipanggil saat mengetik,
              // tapi saat validate() dipanggil atau saat field kehilangan fokus.
              validator: (nilai) {
                // #Cek #Kosong — `trim()` membuang spasi di awal/akhir,
                // supaya judul berisi spasi saja tetap dianggap kosong.
                if (nilai == null || nilai.trim().isEmpty) {
                  return 'Judul tidak boleh kosong';
                }
                if (nilai.trim().length > 100) {
                  return 'Judul maksimal 100 karakter';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // #Widget #TextFormField #Isi
            TextFormField(
              controller: _controllerIsi,
              focusNode: _fokusIsi,

              decoration: const InputDecoration(
                labelText: 'Isi catatan',
                hintText: 'Tulis apa saja di sini...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),

              // #Properti #MaxLines — null berarti TIDAK DIBATASI:
              // kolom akan memanjang sesuai isi. Ini yang kita mau
              // untuk isi catatan.
              maxLines: null,

              // #Properti #MinLines — Tinggi awal minimal 8 baris.
              minLines: 8,

              // #Properti #KeyboardType — multiline menampilkan tombol Enter,
              // bukan tombol "kirim".
              keyboardType: TextInputType.multiline,

              validator: (nilai) {
                if (nilai == null || nilai.trim().isEmpty) {
                  return 'Isi catatan tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            // #Widget #Text #Info — Petunjuk kecil untuk pengguna.
            Text(
              _modeEdit
                  ? 'Perubahan akan disimpan saat Anda menekan Simpan.'
                  : 'Catatan akan tersimpan di perangkat ini.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // #Widget #FilledButton #Simpan — Tombol utama.
            FilledButton.icon(
              // #Properti #OnPressed — Kalau null, tombol otomatis
              // nonaktif (dan terlihat pudar). Trik ini dipakai untuk
              // mencegah klik ganda saat menyimpan.
              onPressed: _sedangMenyimpan ? null : _simpan,

              icon: _sedangMenyimpan
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_sedangMenyimpan ? 'Menyimpan...' : 'Simpan'),
            ),

            const SizedBox(height: 8),

            // #Widget #TextButton #Batal
            TextButton(
              onPressed: _sedangMenyimpan ? null : _batal,
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  // #Method #Simpan — Inti logika halaman ini.
  //
  // Alurnya:
  //   1. Validasi form
  //   2. Tentukan mode (tambah / edit)
  //   3. Simpan ke storage
  //   4. Kembali ke halaman daftar sambil membawa hasil
  Future<void> _simpan() async {
    // #Langkah #Validasi — Jalankan semua validator sekaligus.
    //
    // `!` berarti "saya yakin ini tidak null". Aman karena _formKey
    // selalu terpasang ke widget Form di build().
    if (!_formKey.currentState!.validate()) {
      // #Langkah #GagalValidasi — Pesan error sudah tampil di bawah
      // masing-masing kolom. Cukup berhenti di sini.
      return;
    }

    // #Langkah #TandaiMenyimpan — Nonaktifkan tombol, tampilkan spinner.
    setState(() => _sedangMenyimpan = true);

    // #Langkah #AmbilTeks — Ambil isi kolom, buang spasi berlebih.
    final judul = _controllerJudul.text.trim();
    final isi = _controllerIsi.text.trim();

    try {
      // #Langkah #SiapkanStorage
      final storage = widget.storage ?? NoteStorage();

      if (_modeEdit) {
        // #Cabang #Edit — Perbarui catatan yang sudah ada.
        //
        // `copyWith` membuat salinan dengan judul & isi baru, sementara
        // id dan tanggal pembuatan tetap. Tanggal "diubah" akan diisi
        // otomatis oleh NoteStorage.perbarui().
        //
        // `widget.catatanAwal!` — tanda ! karena kita sudah memastikan
        // mode edit berarti catatanAwal tidak null (lihat getter _modeEdit).
        await storage.perbarui(
          widget.catatanAwal!.copyWith(judul: judul, isi: isi),
        );
      } else {
        // #Cabang #Tambah — Buat catatan baru.
        await storage.tambah(Note.baru(judul: judul, isi: isi));
      }

      // #Langkah #CekMounted — Sama seperti di halaman daftar: kalau
      // halaman sudah ditutup saat penyimpanan berjalan, jangan lanjutkan.
      if (!mounted) return;

      // #Langkah #Kembali — Tutup halaman ini dan beri tahu pemanggil
      // bahwa penyimpanan BERHASIL.
      //
      // `Navigator.pop(context, true)` — nilai `true` inilah yang akan
      // diterima oleh halaman daftar, yang lalu memuat ulang datanya.
      Navigator.pop(context, true);
    } catch (e) {
      // #Langkah #GagalSimpan — Penyimpanan error.
      if (!mounted) return;

      // #Langkah #AktifkanKembali — Izinkan pengguna mencoba lagi.
      setState(() => _sedangMenyimpan = false);

      // #Widget #SnackBar — Beri tahu pengguna dengan jelas.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan catatan. Coba lagi.'),
        ),
      );
    }
  }

  // #Method #Batal — Keluar tanpa menyimpan.
  void _batal() {
    // #Langkah #Kembali — Tanpa nilai (null), artinya "tidak ada perubahan".
    Navigator.pop(context);
  }
}
