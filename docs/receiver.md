# Receiver iPhone dalam DashTConnect

Versi 0.4.0+6 menambahkan mesin receiver dalam APK sendiri. Flutter tetap mengelola halaman, tema, persiapan dan status. Kotlin menangani Bluetooth RFCOMM/iAP2, Wi-Fi Direct lokal, AirPlay/RTSP, autentikasi, decoder MediaCodec, audio dan pengiriman sentuhan.

## Batas folder dan kontrak

Mulai 0.7.6, sentuhan dikirim oleh satu worker segera setelah diterima. Gerakan yang menumpuk digabung ke posisi terbaru, sementara perubahan pointer (tekan/lepas) tetap berurutan. Antrean dibatasi 64 paket; koneksi yang tertahan melepaskan gestur lama sebelum melanjutkan input baru. Video utama menawarkan 60 fps pada resolusi yang sama; buffer musik tetap memakai cadangan untuk jeda penerimaan yang pernah terukur.

Selama sesi, receiver meminta WifiLock LOW_LATENCY pada Android 10+ (HIGH_PERF pada versi lama) dan melepasnya melalui ReceiverResources saat berhenti/gagal. Kegagalan memperoleh lock tidak memblokir koneksi. Efek LOW_LATENCY memerlukan dukungan perangkat, koneksi access point, aplikasi foreground dan layar menyala; permintaan ini tidak mengubah jaringan internet maupun kanal P2P. Penawaran 60 fps tidak menjamin iPhone/jaringan mengirim 60 fps.

- `apps/dashtconnect/lib/domain`: entitas persiapan/event dan kontrak `ReceiverGateway`, tanpa import Flutter/Android.
- `apps/dashtconnect/lib/data/platform`: validasi payload method/event channel dan implementasi gateway.
- `apps/dashtconnect/lib/presentation/pages/receiver_page.dart`: halaman persiapan dan proyeksi; SurfaceView dimasukkan memakai hybrid composition.
- `apps/dashtconnect/android/app/.../platform`: adapter inventaris, penyimpanan, settings dan redup.
- `apps/dashtconnect/android/app/.../receiver`: adapter metode, event, izin dan SurfaceView. `MainActivity` hanya merakit adapter.
- `apps/dashtconnect/android/receiver/src/main/kotlin`: orkestrasi sesi milik DashTConnect, tidak mengimpor Flutter.
- `apps/dashtconnect/android/receiver/third_party`: sumber protokol dengan lisensi dan provenance terpisah.

Channel `dashtconnect/receiver` mempunyai operasi `preparation`, `requestPermissions`, `start(viewId, phoneId)` dan `stop(viewId)`. Event `dashtconnect/receiver_events` mengirim identitas view, fase dan pesan. Tidak ada password Apple atau kode login pada kontrak ini.

## Menjalankan percobaan

1. Pada Samsung, pertahankan Wi-Fi serta Bluetooth aktif. Wi-Fi berinternet dan data seluler boleh tetap tersambung saat memulai receiver.
2. Pasangkan iPhone menggunakan pengaturan Bluetooth Android. Ponsel yang sudah dipasangkan muncul dalam daftar. Mulai 0.7.5, iPhone terakhir yang berhasil menjalankan CarPlay dipilih otomatis jika masih dipasangkan; satu-satunya ponsel juga dapat dipilih otomatis. Jika beberapa ponsel tersedia tanpa riwayat, pengguna harus memilih.
3. Buka Beranda → Mulai receiver. Aplikasi memulai satu alur prepareConnection: meminta izin bila perlu, membuka ACTION_REQUEST_ENABLE jika Bluetooth mati, lalu panel Wi-Fi jika Wi-Fi mati. Pembatalan mengakhiri alur tanpa membuka permintaan berulang. Jika belum ada ponsel yang dipasangkan, Settings Bluetooth dibuka untuk pairing pertama.
4. Setelah panel sistem ditutup dan surface receiver siap, koneksi dimulai otomatis untuk ponsel yang dipilih. Buka kunci iPhone dan setujui permintaan CarPlay. Jika pilihan belum jelas, pilih iPhone lalu tekan Hubungkan iPhone. Percobaan otomatis tidak diulang terus-menerus setelah gagal atau dibatalkan.
5. DashTConnect membuat AP Wi-Fi lokal dan mengirim informasi sesi melalui iAP2 Bluetooth. Decoder dan runtime iAP2 harus siap serta frame harus benar-benar dirender sebelum UI menyatakan terhubung.
6. Gunakan Hentikan receiver atau kembali untuk melepaskan sesi dan AP yang dibuat aplikasi. Keluar ke background juga menghentikan receiver. Buka ulang/Hubungkan iPhone untuk mencoba kembali; reconnect otomatis belum tersedia.
7. Saat parkir, sambungkan Samsung ke T-Link melalui USB dan periksa gambar, sentuhan dan audio dari HU secara terpisah. Lulus uji di HP tidak membuktikan output T-Link berhasil.

## Autentikasi aksesori

Source tidak menyertakan sertifikat/kunci aksesori yang dipercaya iPhone. Tanpa dua file runtime tersebut, UI menjelaskan autentikasi belum siap dan menonaktifkan koneksi. Ini bukan masalah akun Apple pengguna.

Untuk identitas yang memang boleh Anda gunakan, letakkan `offline-mfi/identity.pk8` dan `offline-mfi/certificate.p7b` dalam direktori assets lokal di luar Git. Atur environment `DASHTCONNECT_AUTH_ASSETS_DIR` ke **direktori induk `offline-mfi`** sebelum build. Gradle memasukkan direktori itu sebagai assets aplikasi; Android Studio perlu menerima environment yang sama saat diluncurkan. Untuk build dari Android Studio, alternatif yang persisten adalah properti `dashtconnect.authAssetsDir` dalam `apps/dashtconnect/android/local.properties` yang diabaikan Git. Nilainya path absolut ke direktori induk `offline-mfi`; gunakan slash `/` pada Windows. `dashtconnect.bluetoothAddress` pada file yang sama dapat menyimpan alamat Bluetooth receiver lokal. Environment tetap didahulukan jika disetel. Build debug/profile dengan path autentikasi yang dikonfigurasi juga memvalidasi kedua file sebelum menggabungkan assets, sehingga salah path tidak menghasilkan APK yang terlihat siap tetapi kehilangan autentikasi.

Jangan commit private key, sertifikat fixture, atau kunci signing APK. Hasil APK dengan assets akan berisi material tersebut; penyimpanannya bukan perlindungan terhadap ekstraksi APK.

Loader membatasi ukuran, memvalidasi pasangan kunci/sertifikat dan tidak memanggil layanan autentikasi WAN. Identitas Ed25519 dan pasangan iPhone disimpan privat agar pairing bertahan. Sumber upstream menjelaskan identitas firmware dalam preview sebagai eksperimen yang penerimaan serta distribusi umumnya belum pasti; [notice upstream pada revisi yang diaudit](https://github.com/shihabal3amri/DiPlay/blob/143f4674b60b564a16baae5110b3b90fb7277631/docs/THIRD_PARTY_NOTICES.md).

## Jaringan bersamaan dan batas pengujian

Mulai 0.7.4+37, `ReceiverPreparation.canStart` tidak bergantung pada `internetAvailable`. Native preflight dan callback yang sebelumnya menolak jaringan `INTERNET` dihapus. `ReceiverNetworkStatus.hasInternetNetwork` hanya menyediakan informasi persiapan; sesi tidak lagi dihentikan hanya karena Wi-Fi atau data seluler mempunyai akses internet. Listener RTSP tetap di-bind ke alamat grup Wi-Fi Direct dan Bonjour memakai mDNS pada interface lokal yang sama; default network Android tidak diubah. Pengelola Wi-Fi Direct yang sudah ada mencoba kanal 2,4 GHz yang selaras dengan Wi-Fi station jika tersedia, lalu fallback dalam band 2,4 GHz. Tidak ada pemutusan Wi-Fi, pematian data seluler, penghapusan jaringan tersimpan, atau pemanggilan API privat. Dukungan Wi-Fi station + grup P2P tetap bergantung pada hardware/firmware. Internet CarPlay tetap mengikuti iPhone; ini bukan tethering internet Android ke iPhone.

Mikrofon belum diaktifkan, sehingga Siri/panggilan dua arah belum didukung. Receiver belum dijalankan dengan identitas aksesori runtime dan belum terverifikasi dengan iPhone/T-Link pemilik. Layar benar-benar mati, suhu, kontrol dari HU, jalur audio, penerimaan identitas serta ketahanan sesi membutuhkan uji fisik. Implementasi ini tidak membuka receiver eksternal dan tidak memuat player web.

Riwayat iPhone disimpan dalam SharedPreferences privat hanya pada callback connected yang memerlukan runtime iAP2 dan frame video. Status Wi-Fi menjadi prasyarat teknis; internet tetap hanya informasi. Headset/perangkat non-phone tidak menjadi kandidat otomatis, kecuali perangkat yang sebelumnya benar-benar berhasil menjalankan sesi. Riwayat yang sudah tidak dipasangkan diabaikan. Tidak memindai RSSI untuk menebak perangkat terdekat, tidak memakai API enable/disable radio yang dibatasi, dan tidak mencoba pairing tanpa persetujuan sistem. SurfaceView yang hilang saat Settings terbuka mengirim surface_lost; start menunggu surface_ready dan lifecycle resumed.
