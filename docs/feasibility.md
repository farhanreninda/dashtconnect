# Referensi teknis receiver mandiri

## Pembaruan uji pribadi 23 Oktober 2026

Hasil terbaru 0.6.5: gambar, sentuhan dan suara musik sudah berfungsi pada Samsung. Setelah RECORD_AUDIO diberikan serta masukan mikrofon diaktifkan pada penawaran dan mesin media, iPhone membuka stream AAC-LC 48 kHz stereo; native memulai playback dan pemilik mengonfirmasi suara keluar dari Samsung. Perubahan sebelumnya pada buffered AAC dan identitas Bluetooth saja belum menyelesaikan audio. Ini mendukung dugaan bahwa penawaran masukan mikrofon diperlukan pada pasangan ini; bukan bukti persyaratan universal semua iPhone. Siri, panggilan dan penerusan ke T-Link belum diuji.

Uji 0.6.2 berhasil menampilkan CarPlay nyata dari iPhone 11/iOS 27.0 pada Samsung A04s/Android 14. Sebelumnya jaringan Wi-Fi Direct 5180 MHz tidak terlihat di iPhone dan sesi berhenti tanpa gambar. Build berikut membatasi auto-channel ke 2,4 GHz; log mengonfirmasi 2412 MHz, lalu iPhone bergabung otomatis, runtime iAP2 siap dan frame dirender. Screenshot memperlihatkan launcher CarPlay dan pemilik mengonfirmasi sentuhan berfungsi. Suara masih keluar dari iPhone; jalur audio belum terbukti dan sedang diperiksa. Ini satu keberhasilan perangkat spesifik, bukan kesimpulan penyebab seluruh kegagalan 5 GHz atau jaminan stabilitas umum. Band kompatibilitas dipertahankan; reconnect, suhu dan output T-Link masih perlu diuji.

Pemilik meminta uji pribadi lebih dahulu dengan iPhone 11/iOS 27.0 dan Samsung A04s, sebelum mempertimbangkan publikasi. Build 0.6.0 disiapkan dengan dua aset autentikasi eksperimen dari release publik DiPlay 0.2.21. APK referensi diverifikasi terhadap SHA-256 yang diumumkan GitHub release, tanpa memasang/menjalankan aplikasi tersebut. Aset berada di direktori lokal yang diabaikan Git; provenance ada pada notice komponen.

Parse kunci P-256, parse sertifikat tunggal dan verifikasi tantangan lokal berhasil. Ini membuktikan kecocokan kunci dengan sertifikat, bukan penerimaan oleh iPhone. Pemeriksaan release menolak autentikasi yang hilang/kosong serta file tambahan. Guard UI/native, pembatasan offline, serta syarat runtime iAP2 dan frame video untuk status terhubung tetap berlaku. Catatan audit 22 Oktober di bawah mencatat keadaan sebelum provisioning ini. Distribusi publik belum dipastikan dan belum dilakukan.

Tanggal audit sumber: 22 Oktober 2026. Arah aplikasi 0.4.0+6 adalah receiver bawaan DashTConnect dengan output T-Link, internet tetap di iPhone dan Android tanpa WAN. Pembuka aplikasi dan pencarian paket receiver eksternal telah dikeluarkan. Source protokol terpilih kini dikompilasi dalam library sendiri; UI aplikasi pembanding tidak disalin.

## Sumber yang diperiksa

| Sumber | Hasil pemeriksaan | Implikasi |
| --- | --- | --- |
| [DiPlay](https://github.com/shihabal3amri/DiPlay#readme) | README 0.2.21 mencantumkan paket `com.shihab.diplay`, Android 7+ dan fokus dukungan HU BYD. Koneksi wired/wireless dengan autentikasi lokal merupakan klaim upstream. | Bukan hasil pengujian Toyota/T-Link atau Samsung A04s. Kebutuhan internet yang pernah dialami pengguna masih perlu direproduksi dengan versi APK dan tahapan yang diketahui. |
| [Lisensi DiPlay](https://github.com/shihabal3amri/DiPlay/blob/143f4674b60b564a16baae5110b3b90fb7277631/LICENSE) | GPL-3.0; UI/website DiAuto memiliki lisensi AGPL tersendiri. | Source protokol GPL dari revisi tersebut diintegrasikan sebagai komponen dengan provenance/hash/notice terpisah. UI AGPL tidak disalin. APK gabungan bukan keseluruhan MIT. |
| [Build DiPlay](https://github.com/shihabal3amri/DiPlay/blob/main/docs/BUILD.md) / README | Source biasa tidak menyertakan identitas aksesori runtime. README menjelaskan identitas eksperimental pada release berasal dari firmware Carlinkit publik dan dapat diekstrak. | Tidak ada identitas/kunci yang diambil untuk DashTConnect. Identitas dan ketentuan distribusinya harus dinilai sebelum receiver dibundel. |
| [TiPlay](https://github.com/uJZk/TiPlay#readme) / [Install](https://github.com/uJZk/TiPlay/blob/main/docs/Install.md) | Ditujukan untuk Android phone 9+ dan browser mobil dengan WebCodecs serta akses LAN. Muatan pertama player HTTPS memerlukan internet; halaman tercache mungkin bekerja offline. | HU harus menyediakan browser yang bisa dibuka, menjangkau Android dan memberi input. Instalasi atau launcher berhasil bukan bukti sesi offline maupun kompatibilitas Raize. |
| [Build TiPlay](https://github.com/uJZk/TiPlay/blob/main/docs/Build.md) | Paket release `com.ujzk.tiplay`; debug `com.ujzk.tiplay.hudtest`. Source build biasa tidak mempunyai identitas aksesori. | Identitas paket ini tidak dipakai oleh DashTConnect. Tidak ada penyalinan runtime identity atau kode receiver. |
| [Lisensi TiPlay](https://github.com/uJZk/TiPlay/blob/main/LICENSE) | GPL-3.0. | Tidak ada kode atau aset runtime yang disalin. |
| [Apple CarPlay](https://developer.apple.com/documentation/carplay) / [entitlements](https://developer.apple.com/documentation/carplay/requesting-carplay-entitlements) | API dan entitlement untuk aplikasi CarPlay iOS. | Bukan API receiver Android generik atau bukti HU T-Link kompatibel. |
| [Flutter platform channels](https://docs.flutter.dev/platform-integration/platform-channels) | Flutter dapat memanggil API host. | UI/catatan memakai Dart; inventaris dan kecerahan jendela memakai API Android. Tidak perlu paket tambahan untuk pembungkus ini. |
| [Android screenBrightness](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#screenBrightness) | Pengaturan kecerahan per jendela. | Tidak mengubah gambar dengan overlay. Kelanjutan output T-Link tetap harus diuji. Ini bukan API untuk menjamin layar fisik mati sambil proyeksi berjalan. |

## Keputusan saat ini

DashTConnect adalah aplikasi mandiri dengan mesin protokol dalam library `android/receiver`, lalu output permukaan native di dalam halaman Flutter. Pencarian paket dan pembuka receiver eksternal telah dikeluarkan dari UI, domain, adapter dan manifest Android. Referensi TiPlay tidak disalin. Provenance source yang diintegrasikan ada pada [notice lisensi](../THIRD_PARTY_NOTICES.md).

Persiapan Wi-Fi/Bluetooth, tutorial, uji layar dan catatan lokal tersedia. Integrasi receiver mencakup bootstrap iAP2 Bluetooth, Wi-Fi Direct, AirPlay/RTSP, decoder, audio serta input sentuh. Belum ada identitas aksesori runtime, sehingga koneksi nyata belum diuji. UI hanya boleh menyatakan terhubung setelah runtime iAP2 siap dan frame dirender; diterimanya perintah start tidak cukup. Tidak dibuat server browser, mikrofon atau reconnect otomatis.

Internet tetap digunakan di iPhone. Android harus tanpa WAN selama sesi inti; transport Wi-Fi/Bluetooth/USB lokal tetap boleh aktif. Tidak ada tethering WAN iPhone ke Android. Mode redup hanya mengubah jendela DashTConnect selama di depan; layar sepenuhnya mati dan penurunan suhu belum terbukti.

## Prasyarat sebelum menyatakan fungsi utama berhasil

1. Foto HU sudah mencatat Application 1.1.0005.4400 dan M-Toyota 0.0.2. Lengkapi model HU/versi T-Link, kemudian buktikan mirroring serta input balik dengan probe ini (EXP-03). Lihat [inventaris perangkat](devices/toyota-raize-2022.md).
2. Baseline receiver sudah diintegrasikan tetapi belum diberi identitas aksesori atau diuji dengan iPhone. Bila USB Samsung dipakai HU, mulai dari koneksi iPhone nirkabel; satu port USB tidak diasumsikan dapat sekaligus menjadi jalur iPhone dan HU. Reproduksi online/offline dengan versi APK dan link lokal yang jelas (EXP-02/05).
3. Jika memakai browser, verifikasi browser HU, WebCodecs, konteks keamanan, LAN, pemuatan player tanpa WAN, dan input (EXP-04).
4. Pertahankan Wi-Fi/Bluetooth yang dibutuhkan transport lokal ketika mematikan WAN Android. Uji gambar, sentuh, audio, reconnect dan stabilitas terpisah; jangan menganggap validasi jaringan OS sebagai bukti tidak ada WAN.
5. Tinjau komponen receiver, identitas aksesori dan ketentuan distribusinya sebelum memilih integrasi.

## Catatan audit implementasi awal

Bagian ini mencatat keadaan historis sebelum perapian Clean Architecture, bukan hasil pemeriksaan git terbaru. Source dan panduan iPhone lama kemudian dikeluarkan ke arsip lokal di luar repo sesuai permintaan pemilik; lihat [arsitektur dan daftar pembersihan](architecture.md).

Branch awal: `main`. Sebelum perubahan: ` M README.md`, `?? .gitignore`, `?? apps/`, `?? docs/`. File terlacak hanya README.md dan LICENSE. Tidak ada PRD terlacak; PRD baru datang dari Downloads/ZIP pengguna.

README akar kini hanya menjelaskan kemampuan APK, sesuai permintaan pemilik. Panduan pengembangan tetap ada pada dokumentasi aplikasi. LICENSE asli dipertahankan untuk kode asli, sedangkan source receiver baru menyimpan lisensi GPL dan notice komponen tersendiri. Aset identitas aksesori tidak dimasukkan. Perubahan lokal tidak otomatis menjadi commit atau publikasi.
