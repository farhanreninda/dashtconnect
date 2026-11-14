# Audit receiver Android Auto internal

Audit 30 Oktober 2026 untuk 0.8.0+40. Target pemilik: **satu Android, receiver wajib di dalam DashTConnect, HU tetap T-Link**. Tidak memakai aplikasi receiver eksternal atau mensyaratkan HU Android Auto native.

## Status implementasi

Tahap 1 (12 November 2026): modul `android/androidauto` berisi receiver AAP minimal. DashTConnect tersambung sebagai klien ke head unit server Android Auto di `127.0.0.1:5277`, menjalankan pertukaran versi dan TLS sebagai head unit, mengumumkan layanan video H.264 1280x720 30 fps, layar sentuh, serta sensor status mengemudi dan mode malam. Video didekode ke `AndroidAutoProjectionActivity` (layar penuh, landscape) dan sentuhan pada layar itu dikirim balik ke Android Auto. T-Link meneruskan layar tersebut ke HU.

Belum diuji pada HP maupun HU. Unit test hanya mencakup encoder protobuf, penggabungan fragmen, dan jawaban sesi terhadap pesan Android Auto.

Prasyarat:

1. Setelan developer Android Auto aktif, lalu **Start head unit server** dijalankan sebelum membuka layar Android Auto.
2. Build membawa sertifikat dan kunci privat head unit (PEM, kunci PKCS#8) yang diterima Android Auto. Taruh sebagai `androidauto/headunit.crt` dan `androidauto/headunit.key` di dalam folder lokal di luar Git, lalu isi `dashtconnect.androidAutoIdentityDir` di `android/local.properties` atau variabel `DASHTCONNECT_ANDROID_AUTO_IDENTITY_DIR`. Repo tidak menyertakan identitas ini. Kunci yang dibundel dapat diekstrak dari APK.

Status sesi yang dikirim ke Flutter: `idle`, `connecting`, `waiting_video` (TLS selesai), `projecting` (frame pertama terdekode), `failed`, `ended`. Status tampil hanya muncul setelah frame nyata.

## Jalur teknis yang dituju

Sumber Android Auto pada HP ini -> receiver protokol Android Auto internal -> surface gambar/audio/input DashTConnect -> T-Link -> HU. Balasan sentuhan HU harus kembali ke receiver lokal. Deteksi kabel atau paket Android Auto tidak membuktikan jalur tersebut berjalan.

Dokumentasi Google menjelaskan proyeksi normal ke HU kompatibel dan pengujian lewat Desktop Head Unit. Itu tidak memberikan API receiver lokal siap pakai untuk aplikasi Android biasa. Persyaratan HU native pada jalur normal tidak dipakai untuk menolak target self-mode pemilik.

Referensi implementasi self-mode yang diaudit: [OpenHeadunit](https://github.com/andreknieriem/open-headunit/tree/112ad13a4be59bcc4d1ccc466fb7c6ca3e9224a0), revisi `112ad13a4be59bcc4d1ccc466fb7c6ca3e9224a0`, lisensi AGPL-3.0. Source hanya dibaca dari checkout lokal yang diabaikan Git; tidak disalin atau dibundel ke aplikasi.

Temuan source:

- Paket `aap` mengimplementasikan framing, negosiasi kanal, TLS, transport dan layanan media/input. Ini mesin receiver, bukan widget atau API status.
- Self-mode memakai koneksi loopback ke Head Unit Server Android Auto. Catatan upstream untuk versi 17.4+ dan implementasi HomeFragment menunjukkan kebutuhan mengaktifkan server dari pengaturan developer. Android Auto pada HP uji terbaca 17.9; koneksi otomatis tanpa persiapan manual belum dibuktikan.
- Implementasi receiver terkait lifecycle, renderer, audio, SSL dan kode aplikasi upstream. Build upstream juga memuat CMake/AAudio, FFmpeg dan libusb. Tidak semua komponen itu harus dipakai untuk loopback; ekstraksi mesin minimal belum selesai.
- Bila mengadaptasi source tersebut, lisensi AGPL dan kewajiban source/notice harus ditangani. Repo DashTConnect juga telah memuat receiver CarPlay GPL; label MIT pada kode asli bukan izin mengabaikan lisensi gabungan.

## Pekerjaan yang belum selesai

1. Uji pada HP: handshake TLS dengan sertifikat yang dipasang, frame pertama, sentuhan, putus dan sambung ulang.
2. Audio: belum ada layanan audio sink maupun mikrofon. Suara Android Auto tidak diteruskan oleh receiver.
3. Penyalaan head unit server masih manual. Jalur Android Auto 17.3 ke bawah (Android Auto memanggil port 5288) tidak dibuat.
4. Antrean decoder belum dibatasi; bila decoder tertinggal di perangkat, ganti dengan pembuangan frame dan permintaan keyframe.
5. Uji melalui HU T-Link pemilik: rotasi, background, sesi panjang.

## Bagian native yang tersedia

`AndroidAutoChannel` pada `app/androidauto` membaca PackageManager untuk paket `com.google.android.projection.gearhead` (tersedia, aktif, versi), SDK dan keberadaan USB dari UsbManager. Package visibility hanya untuk paket tersebut. Tidak membuka interface USB atau meminta izin USB yang mengambil alih T-Link.

MethodChannel `dashtconnect/android_auto`: `refresh` menghasilkan `{sdk:int, installed:bool, enabled:bool, version:String, usbAccessory:bool, usbHostDevice:bool, identity:bool, session:String, sessionDetail:String}`; `openSettings` membuka preferensi yang diekspor, dengan fallback informasi aplikasi sistem; `start` membuka `AndroidAutoProjectionActivity`; `stop` mengirim ByeBye lalu menutup soket. EventChannel `dashtconnect/android_auto_events` mengirim kontrak yang sama. Tidak mengirim kontak, alamat perangkat, kredensial atau media.

Receiver USB dipasang hanya saat stream berlangganan dan Activity foreground; dilepas pada pause/cancel/dispose. Dart memvalidasi kontrak, menolak payload rusak, dan mengutamakan event terbaru daripada respons refresh lama. Error pembacaan serta error membuka pengaturan ditampilkan terpisah. Tidak ada polling periodik.

## Verifikasi dan sumber

Tes mencakup layanan hilang/nonaktif/aktif, USB tanpa sesi, payload tidak valid, retry/error, refresh terlambat, pergantian mode/tab, pembatalan subscription dan data lama. Widget test mencakup tombol mulai/hentikan dan status gagal. Hasil perangkat dan build: [validasi](validation-flutter.md). Alur yang benar-benar tersedia: [panduan dua mode](dual-mode.md).

- [Android Auto overview](https://developer.android.com/training/cars/platforms/android-auto): peran sumber HP dan HU pada proyeksi normal.
- [Connection API](https://developer.android.com/training/cars/apps/library/connection-api): informasi koneksi, bukan receiver.
- [Desktop Head Unit](https://developer.android.com/training/cars/testing/dhu): alur Head Unit Server untuk pengujian.
- [OpenHeadunit, source yang diaudit](https://github.com/andreknieriem/open-headunit/tree/112ad13a4be59bcc4d1ccc466fb7c6ca3e9224a0): referensi self-mode dan lisensi; tidak dibundel.
