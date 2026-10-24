# Receiver iPhone dalam DashTConnect

Versi 0.4.0+6 menambahkan mesin receiver dalam APK sendiri. Flutter tetap mengelola halaman, tema, persiapan dan status. Kotlin menangani Bluetooth RFCOMM/iAP2, Wi-Fi Direct lokal, AirPlay/RTSP, autentikasi, decoder MediaCodec, audio dan pengiriman sentuhan.

## Batas folder dan kontrak

- `apps/dashtconnect/lib/domain`: entitas persiapan/event dan kontrak `ReceiverGateway`, tanpa import Flutter/Android.
- `apps/dashtconnect/lib/data/platform`: validasi payload method/event channel dan implementasi gateway.
- `apps/dashtconnect/lib/presentation/pages/receiver_page.dart`: halaman persiapan dan proyeksi; SurfaceView dimasukkan memakai hybrid composition.
- `apps/dashtconnect/android/app/.../platform`: adapter inventaris, penyimpanan, settings dan redup.
- `apps/dashtconnect/android/app/.../receiver`: adapter metode, event, izin dan SurfaceView. `MainActivity` hanya merakit adapter.
- `apps/dashtconnect/android/receiver/src/main/kotlin`: orkestrasi sesi milik DashTConnect, tidak mengimpor Flutter.
- `apps/dashtconnect/android/receiver/third_party`: sumber protokol dengan lisensi dan provenance terpisah.

Channel `dashtconnect/receiver` mempunyai operasi `preparation`, `requestPermissions`, `start(viewId, phoneId)` dan `stop(viewId)`. Event `dashtconnect/receiver_events` mengirim identitas view, fase dan pesan. Tidak ada password Apple atau kode login pada kontrak ini.

## Menjalankan percobaan

1. Pada Samsung, matikan data seluler dan putuskan Wi-Fi berinternet. Pertahankan Wi-Fi serta Bluetooth aktif; jangan tethering internet iPhone ke Android.
2. Pasangkan iPhone menggunakan pengaturan Bluetooth Android. HP yang sudah dipasangkan muncul dalam daftar; pengguna harus memilih secara eksplisit.
3. Buka Beranda → Mulai receiver. Izinkan perangkat sekitar, lalu Periksa ulang jika baru kembali dari Settings.
4. Pilih iPhone dan tekan Hubungkan iPhone. Buka kunci iPhone, setujui permintaan CarPlay yang muncul.
5. DashTConnect membuat AP Wi-Fi lokal dan mengirim informasi sesi melalui iAP2 Bluetooth. Decoder dan runtime iAP2 harus siap serta frame harus benar-benar dirender sebelum UI menyatakan terhubung.
6. Gunakan Hentikan receiver atau kembali untuk melepaskan sesi dan AP yang dibuat aplikasi. Keluar ke background juga menghentikan receiver. Buka ulang/Hubungkan iPhone untuk mencoba kembali; reconnect otomatis belum tersedia.
7. Saat parkir, sambungkan Samsung ke T-Link melalui USB dan periksa gambar, sentuhan dan audio dari HU secara terpisah. Lulus uji di HP tidak membuktikan output T-Link berhasil.

## Autentikasi aksesori

Source tidak menyertakan sertifikat/kunci aksesori yang dipercaya iPhone. Tanpa dua file runtime tersebut, UI menjelaskan autentikasi belum siap dan menonaktifkan koneksi. Ini bukan masalah akun Apple pengguna.

Untuk identitas yang memang boleh Anda gunakan, letakkan `offline-mfi/identity.pk8` dan `offline-mfi/certificate.p7b` dalam direktori assets lokal di luar Git. Atur environment `DASHTCONNECT_AUTH_ASSETS_DIR` ke **direktori induk `offline-mfi`** sebelum build. Gradle memasukkan direktori itu sebagai assets aplikasi; Android Studio perlu menerima environment yang sama saat diluncurkan. Untuk build dari Android Studio, alternatif yang persisten adalah properti `dashtconnect.authAssetsDir` dalam `apps/dashtconnect/android/local.properties` yang diabaikan Git. Nilainya path absolut ke direktori induk `offline-mfi`; gunakan slash `/` pada Windows. `dashtconnect.bluetoothAddress` pada file yang sama dapat menyimpan alamat Bluetooth receiver lokal. Environment tetap didahulukan jika disetel. Build debug/profile dengan path autentikasi yang dikonfigurasi juga memvalidasi kedua file sebelum menggabungkan assets, sehingga salah path tidak menghasilkan APK yang terlihat siap tetapi kehilangan autentikasi.

Jangan commit private key, sertifikat fixture, atau kunci signing APK. Hasil APK dengan assets akan berisi material tersebut; penyimpanannya bukan perlindungan terhadap ekstraksi APK.

Loader membatasi ukuran, memvalidasi pasangan kunci/sertifikat dan tidak memanggil layanan autentikasi WAN. Identitas Ed25519 dan pasangan iPhone disimpan privat agar pairing bertahan. Sumber upstream menjelaskan identitas firmware dalam preview sebagai eksperimen yang penerimaan serta distribusi umumnya belum pasti; [notice upstream pada revisi yang diaudit](https://github.com/shihabal3amri/DiPlay/blob/143f4674b60b564a16baae5110b3b90fb7277631/docs/THIRD_PARTY_NOTICES.md).

## Offline dan batas pengujian

Preflight menolak semua jaringan dengan kapabilitas Android `INTERNET`, termasuk yang belum tervalidasi. Callback memantau perubahan jaringan selama sesi dan menghentikan receiver jika jaringan tersebut muncul. Pendekatan ini sengaja konservatif, dapat menolak jaringan lokal yang salah dilabeli internet, dan bukan audit paket WAN. Izin manifest `INTERNET` dibutuhkan untuk socket lokal, bukan permintaan mengaktifkan internet Android.

Mikrofon belum diaktifkan, sehingga Siri/panggilan dua arah belum didukung. Receiver belum dijalankan dengan identitas aksesori runtime dan belum terverifikasi dengan iPhone/T-Link pemilik. Layar benar-benar mati, suhu, kontrol dari HU, jalur audio, penerimaan identitas serta ketahanan sesi membutuhkan uji fisik. Implementasi ini tidak membuka receiver eksternal dan tidak memuat player web.
