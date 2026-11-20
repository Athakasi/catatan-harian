// ============================================================
// FILE: test/screens/tema_test.dart
// #Test #WidgetTest — Menguji fitur tema gelap.
//
// Yang diuji:
//   - aplikasi mengikuti tema sistem secara default
//   - halaman pengaturan bisa dibuka
//   - memilih "Gelap" mengubah tema seluruh aplikasi
//   - memilih "Terang" mengembalikan tema terang
//   - pilihan tema tersimpan dan dipulihkan saat aplikasi dibuka lagi
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:catatan_harian/app.dart';
import 'package:catatan_harian/services/tema_service.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  TemaService buatService() => TemaService(preferensi: SharedPreferencesAsync());

  // #Helper #TemaAktif — Membaca tema yang sedang dipakai MaterialApp.
  ThemeMode temaAktif(WidgetTester tester) {
    return tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
  }

  // #Helper #Kecerahan — Membaca kecerahan tema yang benar-benar dirender.
  //
  // Ini bukti yang lebih kuat daripada sekadar memeriksa `themeMode`:
  // kita melihat warna yang sungguh dipakai widget.
  Brightness kecerahan(WidgetTester tester) {
    final ctx = tester.element(find.byType(Scaffold).first);
    return Theme.of(ctx).brightness;
  }

  group('Tema', () {
    // #Test #DefaultSistem — Tanpa pilihan tersimpan, ikuti sistem.
    testWidgets('tema awal mengikuti sistem', (tester) async {
      await tester.pumpWidget(CatatanHarianApp(temaService: buatService()));
      await tester.pumpAndSettle();

      expect(temaAktif(tester), ThemeMode.system);
    });

    // #Test #TombolPengaturan — Ikon pengaturan tersedia di AppBar.
    testWidgets('tombol pengaturan muncul di halaman daftar', (tester) async {
      await tester.pumpWidget(CatatanHarianApp(temaService: buatService()));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Pengaturan'), findsOneWidget);
    });

    // #Test #BukaPengaturan — Halaman pengaturan menampilkan tiga pilihan.
    testWidgets('membuka halaman pengaturan menampilkan pilihan tema', (tester) async {
      await tester.pumpWidget(CatatanHarianApp(temaService: buatService()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Pengaturan'));
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Ikuti sistem'), findsOneWidget);
      expect(find.text('Terang'), findsOneWidget);
      expect(find.text('Gelap'), findsOneWidget);
    });

    // #Test #PilihGelap — Memilih "Gelap" mengubah tema ke gelap.
    testWidgets('memilih Gelap mengubah tema aplikasi', (tester) async {
      final service = buatService();
      await tester.pumpWidget(CatatanHarianApp(temaService: service));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Pengaturan'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();

      // #Assert #ModeBerubah
      expect(temaAktif(tester), ThemeMode.dark);

      // #Assert #WarnaSungguhGelap — Bukti nyata, bukan sekadar flag.
      expect(kecerahan(tester), Brightness.dark);

      // #Assert #Tersimpan — Pilihan benar-benar disimpan ke storage.
      final tersimpan = await service.muat();
      expect(tersimpan, ThemeMode.dark);
    });

    // #Test #PilihTerang — Setelah gelap, bisa kembali ke terang.
    testWidgets('memilih Terang mengembalikan tema terang', (tester) async {
      final service = buatService();
      await tester.pumpWidget(CatatanHarianApp(temaService: service));
      await tester.pumpAndSettle();

      // Gelap dulu
      await tester.tap(find.byTooltip('Pengaturan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();
      expect(kecerahan(tester), Brightness.dark);

      // Lalu terang
      await tester.tap(find.byTooltip('Pengaturan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terang'));
      await tester.pumpAndSettle();

      expect(temaAktif(tester), ThemeMode.light);
      expect(kecerahan(tester), Brightness.light);
    });

    // #Test #Dipulihkan — Pilihan tersimpan dipakai saat aplikasi dibuka lagi.
    //
    // Ini yang membuktikan fiturnya berguna: tema tidak kembali ke
    // default setiap kali aplikasi ditutup.
    testWidgets('tema tersimpan dipulihkan saat aplikasi dibuka ulang', (tester) async {
      final service = buatService();

      // #Langkah #SimpanDulu — Simpan pilihan gelap secara langsung.
      await service.simpan(ThemeMode.dark);

      // #Langkah #BukaAplikasi — Aplikasi baru dengan service yang sama.
      await tester.pumpWidget(CatatanHarianApp(temaService: service));
      await tester.pumpAndSettle();

      expect(temaAktif(tester), ThemeMode.dark);
      expect(kecerahan(tester), Brightness.dark);
    });

    // #Test #TersimpanSistem — Pilihan "Ikuti sistem" juga tersimpan benar.
    testWidgets('pilihan ikuti sistem tersimpan dengan benar', (tester) async {
      final service = buatService();
      await tester.pumpWidget(CatatanHarianApp(temaService: service));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Pengaturan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ikuti sistem'));
      await tester.pumpAndSettle();

      expect(temaAktif(tester), ThemeMode.system);
      expect(await service.muat(), ThemeMode.system);
    });
  });

  group('TemaService', () {
    // #Test #DefaultKosong — Storage kosong menghasilkan ThemeMode.system.
    test('muat mengembalikan system saat belum ada data', () async {
      final service = buatService();
      expect(await service.muat(), ThemeMode.system);
    });

    // #Test #BolakBalik — Simpan lalu muat harus mengembalikan nilai sama.
    test('simpan lalu muat mengembalikan nilai yang sama', () async {
      final service = buatService();

      for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) {
        await service.simpan(mode);
        expect(await service.muat(), mode);
      }
    });

    // #Test #DataRusak — Isi storage yang tidak dikenali tidak boleh error.
    test('nilai tidak dikenal dikembalikan sebagai system', () async {
      final preferensi = SharedPreferencesAsync();
      await preferensi.setString(TemaService.kunciTema, 'nilai-aneh');

      final service = TemaService(preferensi: preferensi);
      expect(await service.muat(), ThemeMode.system);
    });
  });
}
