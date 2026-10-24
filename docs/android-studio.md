# Menjalankan DashTConnect dari Android Studio

Repo berisi dokumentasi dan satu aplikasi Flutter. Buka folder aplikasi yang mempunyai `pubspec.yaml` agar Android Studio mengenalinya sebagai proyek Flutter.

## Pengaturan pertama

1. Buka File > Settings > Plugins. Pastikan Flutter dan Dart terpasang serta aktif; restart IDE jika diminta.
2. Pilih File > Open, lalu `D:\han\My Project\DashTConnect\apps\dashtconnect`. Gunakan New Window agar repo/dokumentasi tetap dapat dibuka di jendela lama. Jangan memilih folder `android` untuk menjalankan UI Flutter.
3. Jika SDK belum terdeteksi, buka Settings > Languages & Frameworks > Flutter. Isi Flutter SDK path dengan `D:\tools\flutter`, bukan folder `bin`. Dart SDK bawaan ada di `D:\tools\flutter\bin\cache\dart-sdk`.
4. Pada terminal IDE, jalankan `flutter pub get` dan tunggu indexing selesai.
5. Sambungkan Samsung melalui kabel data, buka kuncinya, aktifkan USB debugging dan setujui permintaan debugging pada HP. Pilih Samsung pada pemilih perangkat di toolbar.
6. Buka `lib/main.dart`, klik kanan lalu Run 'main.dart', atau gunakan tombol Run pada toolbar. Untuk debugging gunakan Debug.

Jika toolbar masih menampilkan Add Configuration setelah Flutter terdeteksi, pilih Add Configuration > + > Flutter. Beri nama DashTConnect, pilih Dart entrypoint `lib/main.dart`, lalu Apply > OK. Pilih konfigurasi dan perangkat, kemudian Run. Jika jenis Flutter tidak tersedia, periksa lagi plugin dan folder yang dibuka.

Jika perangkat belum terdaftar, jalankan `flutter devices` pada terminal IDE. Tidak perlu mengirim output yang berisi identifier perangkat ke repo/chat.

UI tetap dikerjakan di `lib`. Source `.kt` berada di `android/app` untuk penghubung Flutter dan `android/receiver` untuk koneksi/media perangkat. Library `:receiver` sudah terdaftar pada Gradle dan dibangun otomatis ketika menjalankan Flutter; tidak perlu konfigurasi Run terpisah atau Jetpack Compose. Source protokol pihak ketiga dipisahkan di dalam folder `third_party` pada modul tersebut.

## Setelah aplikasi terbuka di Samsung

Versi 0.4.1+7 membuka panduan empat langkah pada pembukaan pertama, termasuk setelah update dari versi yang belum mempunyai penanda panduan. Selesaikan atau pilih Nanti saja; buka kembali dari menu Panduan jika diperlukan. Update dengan paket dan signing yang sama tidak memerlukan uninstall, sehingga catatan lama tetap tersedia. Tampilan baru mendukung navigasi samping dan panel adaptif pada landscape; lihat [catatan redesign](ui-redesign.md).

1. Gunakan tombol Wi-Fi/Bluetooth untuk membuka pengaturan Android, lalu kembali ke DashTConnect. Aplikasi tidak mengaktifkan radio atau membuat pairing secara otomatis.
2. Saat mobil parkir, sambungkan Android ke HU dengan kabel data dan buka T-Link. Buka uji layar untuk memeriksa gambar dan sentuhan dari HU.
3. Untuk persiapan offline, matikan data seluler Android dan putuskan akses internet Wi-Fi tanpa mematikan transport lokal yang diperlukan. Internet tetap digunakan di iPhone.
4. Mulai receiver membuka persiapan koneksi langsung ke iPhone. Pilih iPhone yang sudah dipasangkan dan izinkan perangkat sekitar. Build ini belum menyertakan identitas autentikasi aksesori, sehingga koneksi dinonaktifkan dengan penjelasan. Lihat [alur receiver](receiver.md). Uji layar bukan bukti sesi CarPlay, audio atau reconnect berhasil.

Rincian target dan batas implementasi ada pada [PRD](PRD.md).

## Masalah yang pernah muncul pada laptop ini

Java pernah gagal membuat koneksi loopback ketika temporary directory terlalu panjang. Jika error yang sama muncul pada Run, pada Edit Configurations > Environment variables tambahkan:

```text
TEMP=D:\han\My Project\DashTConnect\.local-tools\java-tmp
TMP=D:\han\My Project\DashTConnect\.local-tools\java-tmp
```

Pastikan folder tersebut ada. Variabel ini hanya untuk proses Run, tanpa mengubah setelan global Windows. Workaround build terminal juga ada di [README aplikasi](../apps/dashtconnect/README.md).

Build sebelumnya menggunakan mirror engine lokal saat unduhan Google ARM64 tersendat; init script tersebut tidak otomatis dipakai oleh tombol Run IDE. Jika build Run berhenti pada unduhan dependency, periksa error/log unduhannya sebelum menyimpulkan kode aplikasi rusak. Jangan memasukkan cache engine atau folder `.local-tools` ke Git.

Pesan `Waiting for another flutter command to release the startup lock` berarti proses Flutter lain masih memakai SDK. Hentikan Run lama melalui tombol Stop di IDE sebelum mengulang; jangan menghapus kunci ketika prosesnya masih berjalan. Pastikan target toolbar adalah Samsung, bukan Windows. Peringatan Java `System::load` saja belum menyatakan build gagal; periksa bagian `What went wrong` bila Gradle akhirnya melaporkan kegagalan.

## Berkas dengan nama sama

- `.gitignore`: sudah disatukan pada akar repo. Aturan Flutter, Gradle, file lokal dan signing tetap berlaku pada subfolder.
- `android/build.gradle.kts`: konfigurasi bersama proyek Android; `android/app/build.gradle.kts`: konfigurasi modul aplikasi. Keduanya dipakai.
- `AndroidManifest.xml` di `src/main`, `src/debug` dan `src/profile`: konfigurasi dasar dan tambahan untuk jenis build. Build debug/profile mendapat izin debugging Flutter dari manifest masing-masing. Ketiganya dipertahankan.
- `.metadata` dan `pubspec.lock`: metadata Flutter dan versi dependency yang dikunci untuk aplikasi; tetap dipertahankan.

Unversioned Files berarti file baru belum dicatat Git, bukan berarti tidak terpakai. Folder `.idea`, `.local-tools`, `.dart_tool` dan `build` adalah data IDE/tool/cache lokal; aturan ignore menjaganya di luar daftar commit.

Validasi konsolidasi ignore: PASS untuk 26 contoh path cache/lokal/signing yang harus diabaikan dan 18 path source/config yang harus tetap terlihat. Perbandingan daftar file baru hanya menunjukkan penghapusan dua `.gitignore` bersarang dan penambahan panduan ini; tidak ada source aplikasi yang ikut tersembunyi. Tautan lokal dan pemeriksaan whitespace juga PASS. Kode aplikasi tidak berubah, sehingga tes/build aplikasi tidak diulang untuk perubahan konfigurasi Git dan dokumentasi ini.

Panduan: [Flutter untuk Android Studio](https://docs.flutter.dev/tools/android-studio), [penggabungan manifest Android](https://developer.android.com/build/manage-manifests), dan [aturan gitignore](https://git-scm.com/docs/gitignore).
