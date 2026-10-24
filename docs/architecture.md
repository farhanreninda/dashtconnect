# Arsitektur DashTConnect

Versi 0.5.0+10. Aplikasi aktif berada di `apps/dashtconnect`. Flutter/Dart mengelola UI dan aturan aplikasi; Android/Kotlin mengelola API perangkat dan mesin receiver. Susunan domain/data/presentation dipertahankan tanpa menambahkan Compose atau menggandakan aplikasi. Redesign dan optimasi berfokus pada presentasi, navigasi, pemuatan UI dan dokumentasi; kontrak/data/protokol dipertahankan. Audit serta bukti ada di [UI dan performa](ui-performance.md).

Folder aplikasi berisi `pubspec.yaml`; buka folder tersebut di Android Studio untuk menjalankan Flutter. Petunjuk lengkap ada di [panduan Android Studio](android-studio.md). Aturan ignore Git disatukan pada `.gitignore` akar repo; dua salinan pada folder aplikasi/Android sudah dihapus. File Gradle tingkat proyek/modul dan manifest setiap jenis build tetap dipakai.

## Susunan sumber

```text
lib/
  main.dart                         # Merakit implementasi dan menjalankan app
  core/
    app_version.dart
  domain/
    entities/
      experiment.dart
      experiment_record.dart        # Status dan aturan kolom bukti
      notebook.dart
      receiver_state.dart           # Persiapan, pilihan iPhone dan event sesi
    experiments.dart                # Delapan panduan eksperimen
    repositories/
      notebook_repository.dart      # Kontrak baca, simpan dan laporan
      device_gateway.dart           # Info, redup dan settings Android
      receiver_gateway.dart         # Kontrak receiver tanpa tipe Android
  data/
    models/
      notebook_codec.dart           # Validasi/serialisasi skema JSON
    repositories/
      file_notebook_repository.dart  # File privat, batas ukuran, tulis atomik
    platform/
      method_channel_device_gateway.dart
      method_channel_receiver_gateway.dart
  presentation/
    app.dart                        # Root widget dan state baca awal
    controllers/
      notebook_controller.dart      # State, retry dan penjagaan simpan bersamaan
    theme/
      app_theme.dart
    widgets/
      app_layout.dart               # Konten gulir, kolom adaptif, panel dan aksi
    pages/
      research_home_page.dart
      setup_guide_page.dart
      experiment_editor_page.dart
      device_page.dart
      display_probe_page.dart
      receiver_page.dart

android/
  app/                              # Host Flutter dan adapter platform
    src/main/kotlin/io/github/farhanreninda/dashtconnect/
      MainActivity.kt               # Bootstrap, lifecycle, registrasi channel
      platform/DeviceChannel.kt
      receiver/ReceiverChannel.kt   # Izin, metode, event dan SurfaceView
  receiver/                         # Library :receiver, tanpa import Flutter
    src/main/kotlin/io/github/farhanreninda/dashtconnect/receiver/
      LocalCarPlayReceiver.kt
      ReceiverIdentity.kt
      ReceiverResources.kt
    src/test/kotlin/
    third_party/carplay_core/       # Source protokol, lisensi dan hash upstream
```

`presentation` hanya mengenal entitas dan kontrak domain. `data` mengimplementasikan kontrak tersebut. `domain` tidak mengimpor Flutter, file I/O, JSON, data atau presentation. Versi aplikasi adalah konstanta Dart bersama di `core`.

`main.dart` menjadi tempat perakitan dependensi: adapter method channel menyediakan direktori privat kepada repository file, lalu repository dan gateway disuntikkan ke widget. Penyimpanan tidak dibuat di halaman UI. Model domain tidak memiliki `toJson`/`fromJson`; codec di data menjaga format penyimpanan dan laporan.

Tidak ditambahkan paket state management, service locator atau class use case untuk setiap operasi baca/simpan. Controller yang kecil cukup untuk operasi saat ini; aturan bukti tetap milik domain, bukan controller atau widget.

## Alur penggunaan

- Beranda membuka receiver bawaan, tutorial persiapan koneksi dan uji layar. Info Android diperiksa ulang saat aplikasi kembali aktif; kegagalan baca dapat dicoba kembali.
- Panduan menyediakan empat langkah dan tombol yang menjalankan aksi pengaturan atau uji layar. Selesai/lewati disimpan pada notebook; status ini tidak menjadi bukti keberhasilan eksperimen.
- Pengaturan menampung tema, redup jendela, informasi perangkat, buku eksperimen dan laporan. Halaman uji sentuh dibuka tersendiri agar tersedia ruang penuh untuk target.

Adapter Android membuka pengaturan Wi-Fi/Bluetooth melalui allowlist. Pencarian paket dan pembuka receiver eksternal sudah dikeluarkan. Receiver berjalan di library Android milik APK sendiri, dengan Flutter tetap mengelola halaman dan status. Arah dependensi native adalah `app → receiver → third_party`; tidak ada dependensi dari receiver ke host Flutter. Detail protokol, persiapan identitas dan batas uji ada di [alur receiver](receiver.md).

Source receiver GPL dipisahkan dari kode integrasi milik proyek dan memiliki revisi, hash, daftar patch serta notice tersendiri. MIT pada kode asli tidak menjadikan seluruh APK gabungan MIT; lihat [pemberitahuan lisensi](../THIRD_PARTY_NOTICES.md). Tidak ada identitas aksesori runtime yang disertakan.

Redup tetap memakai `screenBrightness` jendela DashTConnect. Lifecycle Android memulihkan kecerahan dan melepas `FLAG_KEEP_SCREEN_ON` ketika aplikasi tidak di depan; permintaan redup berlaku kembali saat kembali. Kecerahan sistem tidak diubah.

## Alur dan jaminan data

1. Controller memuat notebook melalui kontrak repository. Gagal baca menampilkan retry tanpa mereset catatan.
2. Halaman membuat perubahan, memanggil controller, dan baru memakai state baru setelah repository berhasil menyimpan.
3. Repository memvalidasi skema JSON saat membaca, membatasi ukuran 1 MB, dan menyimpan lewat file sementara, flush, lalu rename.
4. Penulisan bersamaan ditolak sampai penulisan pertama selesai. Kegagalan simpan mempertahankan isian dan state sebelumnya.
5. Laporan berasal dari codec yang sama dengan penyimpanan; clipboard hanya diisi setelah tindakan pengguna.

Nama paket `io.github.farhanreninda.dashtconnect`, lokasi privat `files/research.json` dan skema 1 dipertahankan. Penanda panduan menambah field opsional; codec menerima catatan lama tanpa field tersebut dan tetap memvalidasi tipenya bila tersedia. Inventaris, tema, hasil dan versi pada catatan lama tidak direset. Update tidak membutuhkan uninstall; menghapus data aplikasi/uninstall tetap menghapus catatan lokal.

## Tes

`test/` mengikuti lapisan sumber: `domain`, `data`, `presentation/controllers` dan `presentation`. Fake repository/gateway ada di `test/support`. Tes arsitektur di `test/architecture_test.dart` memeriksa arah import agar data tidak bocor ke UI atau domain. Cakupan mencakup kompatibilitas catatan lama, validasi bukti, tutorial, tindakan platform, navigasi dan pemulihan kegagalan. Hasil pemeriksaan terbaru dicatat di [validasi Flutter](validation-flutter.md).

## Pembersihan repo

Sesuai permintaan pemilik, berkas yang sudah digantikan dihapus dari `lib/` dan tes lama dipindahkan ke lapisan yang sesuai. Komentar contoh yang tidak dipakai di pubspec/analyzer dibuang. Source Android, Gradle wrapper, metadata Flutter, lockfile dan cache engine yang diperlukan build dipertahankan.

Bagian berikut dikeluarkan dari repo ke arsip lokal `D:\han\My Project\DashTConnect-archive\2026-10-22-cleanup`, dengan struktur asal dipertahankan:

- `apps/iphone_probe` beserta hasil build lamanya.
- `docs/windows-setup.md`, `docs/sideloadly-test.md`, `docs/experiments/EXP-01-iphone.md` dan `docs/CODEX_PROMPT.md`.
- `.local-tools/Sideloadly`, `.local-tools/xcross` dan laporan autentikasi lama.
- `.local-tools/installers`, termasuk arsip unduhan dan potongan unduhan yang sudah tidak dipakai setelah SDK terpasang.

Daftar modul IDE lokal diperbaiki dengan menghapus referensi ke workspace XCross yang sudah dikeluarkan. Pengaturan IDE lainnya dipertahankan.

Data versi iPhone yang pernah diverifikasi sudah dirangkum dalam [inventaris perangkat](devices/toyota-raize-2022.md). Arsip ini bukan dependency aplikasi atau bagian Git. Tidak ada perubahan terhadap instalasi tool sistem, akun Apple atau data di HP. Tidak dilakukan commit/push.
