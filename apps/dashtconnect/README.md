# DashTConnect Flutter Android

Flutter menangani UI dan native Android menangani mesin receiver di dalam APK yang sama. Internet ditujukan tetap di iPhone dan Android tanpa WAN. Receiver eksperimental sudah diintegrasikan tetapi identitas aksesori runtime belum disertakan, sehingga sesi iPhone belum dapat diuji. Baca [alur receiver](../../docs/receiver.md) untuk persiapan dan batasannya. Dock/rail adaptif, retensi tab dan pemisahan informasi perangkat dijelaskan dalam [audit UI dan performa](../../docs/ui-performance.md).

## Menjalankan

Gunakan Flutter stable dan Android SDK/JDK yang didukung Flutter. Sambungkan Android dengan USB debugging yang sudah disetujui.

Untuk tombol Run di IDE, buka folder aplikasi yang berisi `pubspec.yaml`: `D:\han\My Project\DashTConnect\apps\dashtconnect`. Lihat [panduan Android Studio](../../docs/android-studio.md) untuk plugin, SDK, pemilihan perangkat dan konfigurasi Run.

```powershell
Set-Location 'D:\han\My Project\DashTConnect\apps\dashtconnect'
flutter pub get
flutter analyze
flutter test
flutter run
```

APK eksperimen: `flutter build apk --debug`, hasil `build/app/outputs/flutter-apk/app-debug.apk`. APK debug menggunakan kunci debug lokal dan bukan paket distribusi produksi. Akun Apple, XCross dan signing iOS tidak diperlukan untuk app Android ini.

Pada laptop pengembangan, Java sempat gagal dengan `Unable to establish loopback connection` pada temporary directory bawaan. Memakai temporary directory yang lebih pendek membuat Gradle dapat berjalan. Jika error yang sama muncul di PowerShell Anda, jalankan ini dari folder app sebelum build (hanya mengubah environment terminal tersebut):

```powershell
$buildTemp = [IO.Path]::GetFullPath((Join-Path $PWD '..\..\.local-tools\java-tmp'))
New-Item -ItemType Directory -Path $buildTemp -Force | Out-Null
$env:TEMP = $buildTemp
$env:TMP = $buildTemp
flutter build apk --debug
```

Build pertama dapat mengunduh Gradle, Android SDK dan NDK yang diperlukan Flutter. SDK iOS/Xcode tidak diperlukan.

## Fungsi yang tersedia

- Beranda: Mulai receiver. Tutorial dan Uji tampilan berada di Panduan; pengujian gambar/sentuhan ada pada bagian Pengecekan T-Link. Informasi teknis hanya dibaca saat halaman Informasi perangkat dibuka atau diperbarui.
- Receiver: persiapan izin perangkat sekitar, pemilihan iPhone yang sudah dipasangkan, pemeriksaan jaringan/autentikasi, SurfaceView untuk decoder native, status sesi dan penghentian nyata. Halaman terkunci landscape selama aktif untuk menjaga surface.
- Panduan: empat langkah pada pembukaan pertama, dapat dilewati atau diulang dari menu Panduan. Tombol Wi-Fi/Bluetooth membuka pengaturan Android. Pilihan selesai/lewati disimpan tanpa menghapus inventaris dan catatan lama.
- Uji layar penuh: empat target sentuh, penghitung yang dapat diulang, layout menyesuaikan orientasi. Uji dari layar HU, bukan hanya menyentuh HP. Uji ini hanya memeriksa gambar/input DashTConnect.
- Pengaturan: halaman Tampilan, mode redup terpusat, informasi Android hanya-baca dan halaman Tentang DashTConnect. Menu eksperimen, laporan dan isian inventaris manual sudah dikeluarkan; data lama tetap dipertahankan oleh codec penyimpanan.
- Informasi perangkat: model/OS/ABI, fitur USB host dan Wi-Fi Direct, jaringan default dan validasi internet Android, suhu baterai dan daya eksternal. Info dapat diperbarui; OS/network validation tidak membuktikan WAN benar-benar terputus.
- Tema sistem, terang dan gelap yang tersimpan. Redesign mengikuti referensi Stitch pemilik dengan biru merek, panel putih/slate dan font lokal Space Grotesk/Inter. Navigasi dock pada portrait sempit dan rail pada landscape/tablet; halaman menyesuaikan ruang setelah rail dan tetap bergulir pada layar pendek.
- Redup: satu sakelar di **Pengaturan → Layar → Mode redup** meminta `WindowManager.LayoutParams.screenBrightness = 0.03`. Tidak ada overlay hitam atau izin mengubah setelan kecerahan sistem. `FLAG_KEEP_SCREEN_ON` hanya aktif saat mode redup pada jendela ini. Keluar aplikasi memulihkan jendela; saat kembali, permintaan redup diterapkan kembali. Mode redup tidak disimpan lintas restart.

## Percobaan di perangkat dan mobil

### Build uji receiver lokal

Build release sekarang menolak aset autentikasi yang hilang, kosong atau tercampur file lain. Debug tanpa aset tetap bisa digunakan untuk mengembangkan UI, tetapi tidak dapat memulai sesi CarPlay. Siapkan hanya `offline-mfi/identity.pk8` dan `offline-mfi/certificate.p7b` di direktori lokal di luar Git, lalu tentukan path absolut pada `DASHTCONNECT_AUTH_ASSETS_DIR` di terminal build. Jangan simpan kunci dalam source atau memasukkan keystore ke direktori assets.

```powershell
$env:DASHTCONNECT_AUTH_ASSETS_DIR = 'D:\lokal\runtime-assets'
flutter build apk --release --target-platform android-arm64
```

Build pribadi 0.6.x memakai autentikasi eksperimen lokal yang dijelaskan dalam notice sumber. Pada 0.6.2, gambar dan sentuhan dari iPhone 11/iOS 27.0 sudah berhasil pada Samsung A04s/Android 14 melalui Wi-Fi lokal 2,4 GHz. Audio masih keluar dari iPhone pada uji awal; jalur audio dan output T-Link belum lulus pengujian. APK ini bukan paket publikasi. Lihat [notice komponen](../../THIRD_PARTY_NOTICES.md).

Untuk diagnosis audio 0.6.4, build lokal dapat menerima alamat Bluetooth perangkat uji melalui `DASHTCONNECT_BLUETOOTH_ADDRESS`. Alamat diperiksa sebelum dimasukkan ke BuildConfig dan hanya dipakai bila API Android tidak menyediakan alamat yang valid. Nilai tersebut ikut berada di APK; jangan memasukkan nilainya ke Git atau membagikan APK khusus perangkat ini sebagai build umum. Build Samsung saat ini memakai provisioning ini karena API Android mengembalikan alamat yang disamarkan. Ini percobaan kecocokan identitas, belum bukti perbaikan audio.

Pada 0.6.5, izin mikrofon menjadi bagian dari persiapan receiver agar penawaran audio memiliki masukan yang benar-benar dapat digunakan. Berikan izin melalui tombol di halaman receiver. Capture/uplink memakai mesin media internal hanya ketika diminta iPhone pada sesi aktif; tidak menyimpan rekaman. Dukungan ini masih perlu uji audio, Siri dan panggilan pada perangkat.

Hasil uji 0.6.5: setelah izin mikrofon diberikan, iPhone membuka stream musik AAC-LC 48 kHz stereo dan Android memulai playback. Pemilik mengonfirmasi musik terdengar dari Samsung. Gambar, sentuhan dan musik pada pasangan perangkat ini sudah berfungsi; Siri, panggilan dan keluaran ke head unit melalui T-Link belum diuji.

1. Ikuti empat langkah pada pembukaan awal; panduan yang sama tersedia dari menu Panduan.
2. Saat mobil parkir, hubungkan Samsung ke port USB head unit menggunakan kabel data. Buka T-Link di HU dan ikuti petunjuknya. Gunakan uji layar DashTConnect untuk memastikan gambar serta sentuhan dari HU diterima.
3. Saat menguji jaringan, matikan data seluler Android dan putuskan akses internet Wi-Fi. Pertahankan Wi-Fi/Bluetooth untuk koneksi lokal; internet tetap dipakai di iPhone. Jangan gunakan tethering WAN iPhone ke Android.
4. Buka Mulai receiver, izinkan perangkat sekitar dan pilih iPhone yang sudah dipasangkan. Hubungkan iPhone hanya aktif jika autentikasi aksesori siap dan jaringan Android memenuhi pemeriksaan offline. Persiapan jaringan atau diterimanya perintah start tidak menjadi bukti CarPlay aktif. Build tanpa identitas menampilkan alasan dan menonaktifkan koneksi.
5. Jika iPhone belum otomatis bergabung, pada layar proses koneksi buka **iPhone belum masuk Wi-Fi?**. Di iPhone pilih jaringan yang ditampilkan dan tekan **Tampilkan sandi** di Samsung jika diperlukan. Ini jaringan lokal sementara tanpa internet Android. Sesi memberi waktu hingga tiga menit; kredensial tidak disimpan dalam notebook atau log dan dibuang dari layar ketika percobaan berakhir. Sesudah tersambung ke Wi-Fi, sesi CarPlay tetap harus berhasil menerima gambar sebelum dinyatakan aktif.

## Penyimpanan dan batasan

Data disimpan sebagai `research.json` dalam direktori privat aplikasi melalui platform channel Android. Penulisan memakai temporary file, flush dan rename. Data rusak/versi tidak dikenali menampilkan kegagalan baca dan tidak otomatis ditimpa. Batas ukuran file 1 MB. Tidak ada unggah otomatis. Backup Android dinonaktifkan. Upgrade APK dengan paket dan signing yang sama mempertahankan data lama; menu laporan sudah dikeluarkan dari UI.

Receiver memakai socket lokal dan tidak memanggil cloud auth. Manifest library menyertakan `INTERNET` untuk socket, izin Wi-Fi/Bluetooth dan audio. Preflight/callback menolak jaringan berkapabilitas internet, bukan audit paket WAN. Tidak ada pencarian paket atau pembuka receiver eksternal. Debug Flutter juga memakai socket alat pengembangan.

Layar fisik sepenuhnya mati belum tersedia: kelanjutan T-Link saat perangkat terkunci harus diuji. Redup hanya memengaruhi jendela DashTConnect dan dipulihkan ketika aplikasi tidak di depan. Pengisian, decoding dan radio tetap menghasilkan panas. Suhu baterai bukan suhu CPU.

## Struktur

Clean Architecture dengan `lib/domain` untuk entitas/aturan/kontrak, `lib/data` untuk JSON/file/method channel, serta `lib/presentation` untuk controller, halaman dan tema. `lib/main.dart` hanya merakit dependensi. Android dibagi menjadi `android/app` untuk host/adapter dan `android/receiver` untuk mesin protokol; sumber pihak ketiga memiliki folder sendiri. Detail alur dan folder ada di [arsitektur](../../docs/architecture.md).

Versi 0.5.2+12 tetap memakai skema JSON 1 dan nama paket yang sama. Status penyelesaian panduan merupakan tambahan opsional; catatan lama tetap dibaca tanpa reset. Data perangkat pemilik ada di [inventaris Raize](../../docs/devices/toyota-raize-2022.md); tidak dipasang sebagai default universal aplikasi.

Source protokol pihak ketiga berada dalam library APK sendiri, tanpa dependensi runtime pada aplikasi pembanding. Lisensi source receiver berbeda dari kode asli; lihat [notice lisensi](../../THIRD_PARTY_NOTICES.md), [PRD](../../docs/PRD.md) dan [audit sumber](../../docs/feasibility.md).
