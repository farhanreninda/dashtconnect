# Validasi aplikasi eksperimen Flutter

Tanggal: 22 Oktober 2026. Bagian berikut merekam validasi awal versi 0.2.0+1. Source tes sudah dipindahkan mengikuti [Clean Architecture](architecture.md); hasil refactor versi 0.2.1+2 dicatat terpisah di akhir dokumen. Receiver CarPlay dan koneksi ke head unit belum tersedia untuk diuji.

## Hasil pemeriksaan

| Pemeriksaan | Hasil dan bukti |
| --- | --- |
| Analisis Dart | `flutter analyze`: No issues found. |
| Tes otomatis | 9 tes lulus: 2 penyimpanan/parser dan 7 widget. Tes kini berada di [tes data](../apps/dashtconnect/test/data/repositories/file_notebook_repository_test.dart) dan [tes UI](../apps/dashtconnect/test/presentation/app_test.dart). |
| Penyimpanan | Roundtrip file nyata menjaga inventaris, tema, bukti dan status. JSON rusak/skema tidak didukung ditolak tanpa menimpa berkas asli. |
| Validasi bukti | Status BERHASIL tanpa bukti ditolak, termasuk ketika kolom bukti berada di luar viewport. Hasil lengkap menyimpan snapshot inventaris lalu menutup editor. |
| Navigasi dan laporan | Tes widget menjalankan inventaris, simpan, pratinjau laporan, salin clipboard, empat target sentuh dan reset. Tema, redup, pemulihan serta aktivasi keyboard Tab/Enter juga diuji. |
| Layout | Tes 320 x 640 dengan skala teks 2 dan 1000 x 720 lulus tanpa exception layout; target tetap dapat dijangkau dan layar lebar memakai navigation rail. |
| Build Android | Gradle `assembleDebug`: BUILD SUCCESSFUL. APK debug ditandatangani dan `apksigner verify` berhasil. |
| Pemasangan | `adb install -r`: Success. Aplikasi dibuka pada samsung SM-A047F, Android 14/API 34, hardware exynos850. Pengguna mengonfirmasi halaman Riset relay Android terlihat. |
| Tema fisik | Terang dan gelap dipilih pada Samsung; screenshot setelah idle diperiksa. Pilihan `dark` tersimpan dalam JSON privat dan bertahan setelah proses dihentikan/dibuka ulang. |
| Info Android | Model, API, hardware, fitur USB host/Wi-Fi Direct, transport jaringan dan suhu baterai tampil. Tombol Perbarui info Android dijalankan. |
| Sentuh fisik | Pada halaman Uji layar, Target 1 berubah dari 0 menjadi 1 setelah ditekan di Samsung; Ulangi penghitung mengembalikannya ke 0. Aplikasi ditinggalkan pada halaman Eksperimen dengan tema gelap dan kecerahan dipulihkan. Ini bukan input dari HU. |
| Redup fisik | Window Android menunjukkan `sbrt=0.03` dan flag berubah dari `81810100` ke `81810180` (bit KEEP_SCREEN_ON 0x80). Pemulihan menghapus override kecerahan dan bit tersebut. Screenshot tetap berisi konten aplikasi, tanpa overlay hitam. |
| Log aplikasi | Pemeriksaan log proses aplikasi setelah peluncuran tidak menemukan marker E/flutter atau FATAL EXCEPTION. Ini bukan uji ketahanan jangka panjang. |

Screenshot QA berada dalam `.local-tools/qa` yang diabaikan Git. Tidak ada serial/IMEI, akun Apple atau kode verifikasi di catatan aplikasi. Data eksperimen fisik tidak diisi sebagai keberhasilan dari hasil tes widget.

APK awal 0.2.0+1: 150412938 byte, dengan SHA-256 berikut. File output lokal sudah digantikan APK 0.2.1+2; gunakan checksum pada bagian refactor untuk memeriksa file saat ini.

```text
F61B2268C28AB085A0F52BA5632A5FDBBE4813DDE71414DEC52835F922ACF845
```

## Catatan build Windows

Flutter 3.47.7 / Dart 3.13.5, Android Studio JBR 25, platform Android 36 dan NDK 28.2.13676358 digunakan. Build pertama mengunduh komponen SDK/NDK. Tidak diperlukan Xcode, XCross atau autentikasi Apple untuk APK ini.

Java pada laptop ini memerlukan temporary directory yang lebih pendek; caranya ada di [README aplikasi](../apps/dashtconnect/README.md). Unduhan engine ARM64 resmi tersendat sehingga artefak Google yang sama diunduh bertahap, diperiksa CRC32C/isi ZIP, lalu disediakan melalui mirror Maven lokal. Init script hanya berlaku saat build tersebut; tidak ada perubahan dependency sumber atau repository Gradle aplikasi. NDK resmi juga diperiksa SHA-1 sebelum dipasang. Helper dan cache berada di `.local-tools`, bukan dalam sumber aplikasi.

Gradle menampilkan deprecation flag dari template Flutter dan peringatan versi XML SDK; keduanya tidak menggagalkan build. APK ini debug multi-ABI, berukuran sekitar 143 MiB, dan belum disiapkan sebagai rilis produksi. Manifest debug Flutter memuat izin INTERNET untuk alat pengembangan; aplikasi tidak membuat request WAN.

## Cakupan perubahan dan Git

| Bagian | Keputusan |
| --- | --- |
| `apps/dashtconnect` | Aplikasi Flutter baru, bridge Android, tes dan arah desain. |
| `README.md` | Arah utama menjadi riset relay Android, dengan fungsi yang sudah ada dan batasnya. |
| `docs/PRD.md`, `docs/CODEX_PROMPT.md` | Requirement revisi dan keputusan pengguna memakai Flutter, tema dan redup dicatat. |
| `docs/feasibility.md`, `docs/experiments/android-relay.md` | Audit sumber/lisensi, arsitektur, status eksperimen dan kriteria uji fisik. |
| Probe iPhone dan panduan lama | Dipertahankan, diberi penanda arsip. |
| `LICENSE` | MIT asli dipertahankan; kode/identitas aksesori proyek receiver lain tidak disalin. |

Sebelum maupun sesudah pekerjaan, status Git tingkat akar: `M README.md`, `?? .gitignore`, `?? apps/`, `?? docs/`. Awalnya hanya README dan LICENSE yang tracked; status untracked tidak menunjukkan bahwa file lama dihapus. Tidak dilakukan reset/clean, commit atau push. Build/cache/screenshot tidak masuk Git. Pemeriksaan whitespace dan tautan Markdown lokal dilakukan.

## Gate desain antislop

Berlaku untuk UI alat eksperimen yang diimplementasikan, dengan arah dan alasan di [DESIGN.md](../apps/dashtconnect/DESIGN.md). PASS di sini tidak meluluskan kelayakan CarPlay atau T-Link.

| Aturan | Status dan bukti |
| --- | --- |
| R-02 | PASS: teks sumber UI tidak memakai em dash. |
| R-03 | PASS: tes viewport sempit/skala teks 2 dan lebar tidak menghasilkan overflow; screenshot Samsung diperiksa. |
| R-17 | PASS: tidak ada statistik pemasaran; suhu/jaringan diberi sumber Android dan batas interpretasi. |
| R-18 | PASS: tidak ada testimonial. |
| R-23 | PASS: launcher bawaan dinyatakan placeholder pengembangan; navigasi berasal dari tiga fungsi PRD. |
| R-24 | PASS: ketiga tujuan navigasi memiliki halaman; tautan dokumentasi lokal diperiksa. |
| R-25 | PASS: teks memakai pasangan ColorScheme Material; empat target putih pada warna khusus memiliki rasio kontras 7.58 sampai 8.88:1. Kedua tema diperiksa. |
| R-26 | PASS: kontrol mengarah ke handler nyata; tes menjalankan simpan, salin, tema, redup, reset dan sentuh. Tidak ada tombol memulai CarPlay palsu. |
| R-27 | PASS: baca/simpan punya status berlangsung, belum ada hasil punya BELUM DIUJI, kegagalan baca/penyimpanan punya pesan dan cara mencoba kembali. |
| R-28 | PASS: tidak ada FAQ pengisi. |
| R-32 | PASS: kontrol Material mempertahankan fokus; tes Tab lalu Enter mengaktifkan redup. |
| R-33 | PASS: perilaku ditulis pada sumber Flutter/Kotlin, tanpa injeksi DOM/CSS. |
| R-34 | PASS: terang/gelap dipilih dan diperiksa di Samsung; tema tersimpan setelah restart proses. |
| R-35 | PASS: build, pemasangan dan peluncuran nyata berhasil; catatan interaksi native dan tes keluarga kontrol tercantum pada tabel validasi. |
| R-36 | PASS: aplikasi menyatakan CarPlay belum tersedia dan tidak menjanjikan dingin/offline dari metadata OS. |
| R-37 | PASS: brief pemilik, pembacaan desain dan dial dicatat di DESIGN.md. |
| R-38 | PASS: hasil eksperimen tidak dibuat otomatis; fixture tes terpisah dari catatan perangkat. |
| R-01 | PASS: tidak memakai gradien/glow. |
| R-04 | PASS: ikon Material menyatakan tindakan perangkat, sentuh, eksperimen, tema, redup dan laporan. |
| R-06 | PASS: tipografi Material dipilih untuk keterbacaan/ukuran teks; huruf kapital hanya status riset dari PRD. |
| R-07 | PASS: tidak memakai pola latar dekoratif. |
| R-08 | PASS: panah hanya menjelaskan urutan perangkat. |
| R-09 | PASS: tidak ada badge promosi. |
| R-10 | PASS: tidak ada glassmorphism. |
| R-12 | PASS: permukaan dan pembatas menggantikan bayangan besar berulang. |
| R-13 | PASS: tidak ada efek glow. |
| R-14 | PASS: hasil disajikan sebagai daftar, bukan kumpulan kartu fitur seragam; empat target sama besar untuk membandingkan posisi sentuh. |
| R-19 | PASS: hanya transisi Material, tanpa animasi dekoratif berulang. |
| R-22 | PASS: tidak ada ilustrasi stok. |
| Liveliness: dial | PASS: ENERGY 1 / RHYTHM 2 / MOTION 1, sesuai alat riset dengan panel tujuan, daftar dan formulir. |
| Liveliness: fokus | PASS: tujuan riset, inventaris dan target uji menjadi fokus masing-masing halaman. |
| Liveliness: ruang | PASS: jarak memisahkan petunjuk, data, isian dan tindakan; teks bergulir saat ruang kurang. |
| Liveliness: aksen | PASS: hijau diwarisi dari probe sebelumnya; warna tambahan hanya untuk target pembanding. |
| Liveliness: motif | PASS: status berbukti dan tindakan berlabel dipakai konsisten di seluruh alur riset. |
| Liveliness: Design Read | PASS: brief dan pembacaan desain tertulis di DESIGN.md. |
| C-1 | PASS: alasan warna, tipe, navigasi, target dan ruang tercatat di DESIGN.md. |
| C-2 | PASS: kontrol memiliki callback nyata dan interaksi utama dijalankan pada tes/native. |
| C-3 | PASS: setiap halaman melayani inventaris, bukti atau kalibrasi tampilan dari PRD. |
| C-4 | PASS: dua breakpoint, teks besar, dua tema dan aktivasi keyboard diuji. |
| C-5 | PASS: tidak ada klaim keberhasilan eksperimen fisik yang direkayasa. |
| R-05 | PASS: komposisi mengikuti data riset, tanpa harga, testimonial atau kartu metrik. |
| R-11 | PASS: bentuk panel, tombol dan formulir berbeda; tidak semuanya kapsul. |
| R-15 | PASS: CTA menyebut tindakan nyata seperti Simpan inventaris lokal dan Uji tampilan T-Link. |
| R-16 | PASS: teks menjelaskan aksi dan batas eksperimen, tanpa jargon promosi. |
| R-20 | PASS: inventaris HU/T-Link, status riset dan empat target memberi fungsi khusus proyek. |
| R-21 | PASS: tema mengikuti sistem secara awal, dengan pilihan terang/gelap sesuai permintaan pengguna. |
| R-29 | PASS: palet utama hijau/netral; empat warna target memiliki tujuan kalibrasi tertulis. |
| R-30 | PASS: memakai pola Material Android, tidak meniru merek aplikasi lain. |
| R-31 | PASS: alasan setiap keputusan visual utama tersedia di DESIGN.md. |

## Langkah berikutnya

Lengkapi EXP-01 dari menu Perangkat: model/firmware head unit, versi T-Link/aplikasi pendamping, model dan build iOS, kabel/adaptor/port. Kemudian saat mobil parkir jalankan EXP-03: tampilkan Uji layar melalui T-Link, tekan keempat target dari HU, cocokkan penghitung, aktifkan redup dan ulangi. Catat bukti serta kegagalan apa adanya.

Belum diuji: proyeksi dan input T-Link, receiver CarPlay, browser HU, sesi Android tanpa WAN, audio, pemulihan koneksi, durasi dan perubahan suhu. Layar sepenuhnya mati belum diimplementasikan. Menurunkan kecerahan tidak menjamin HP tidak panas; pengisian/radio/decoding tetap menjadi beban.

## Validasi refactor 0.2.1+2

Clean Architecture dan pembersihan folder selesai pada 22 Oktober 2026. UI, method channel dan skema penyimpanan tetap sama. [Arsitektur](architecture.md) menjelaskan batas lapisan dan daftar arsip di luar repo. [Inventaris](devices/toyota-raize-2022.md) mencatat Application Version HU 1.1.0005.4400 dan M-Toyota 0.0.2 dari foto pemilik, tanpa menyimpan nomor seri atau foto asli.

| Pemeriksaan | Hasil |
| --- | --- |
| Tes regresi | PASS: seluruh 16 tes lulus, termasuk 7 widget yang mempertahankan alur/theme/redup/layout sebelumnya. |
| Aturan domain | PASS: kebutuhan bukti untuk BERHASIL/GAGAL dan status belum konklusif diuji terpisah dari UI. |
| Arah dependensi | PASS: tes import melarang data/presentation/Flutter/I/O/JSON masuk ke domain, serta melarang data/I/O masuk ke presentation. |
| Kompatibilitas data | PASS: JSON schema 1 dari versi 0.2.0 dibaca, ditulis ulang dan diekspor dengan isi yang sama, termasuk versi catatan lama. |
| Controller | PASS: gagal baca lalu retry, gagal tulis tanpa mengubah state, penolakan save bersamaan dan penyelesaian async setelah dispose diuji. |
| Build | PASS: Gradle assembleDebug berhasil dalam 26 detik; signature APK diverifikasi. Deprecation template Gradle dan peringatan XML SDK masih sama dengan build awal. |
| Versi paket | PASS: aapt membaca versionName 0.2.1 dan versionCode 2 dengan nama paket yang sama. |
| Upgrade perangkat | PASS: adb install -r berhasil pada Samsung; checksum byte catatan privat sebelum/sesudah upgrade identik. Tidak dilakukan uninstall atau hapus data. |
| Peluncuran | PASS: proses aplikasi hidup, activity berstatus ok dan memiliki fokus. Pemeriksaan log proses tidak menemukan E/flutter atau FATAL EXCEPTION. |
| Pembersihan | PASS: source/tes yang digantikan tidak tersisa di lokasi lama; probe iPhone, panduan signing dan installer lama berada pada arsip luar repo. |

Gate antislop untuk refactor: PASS. Arah visual dari DESIGN.md dan keputusan gate sebelumnya dipertahankan; 7 tes widget dijalankan ulang dan UI tidak didesain ulang. Klaim produk tetap dibatasi pada alat eksperimen. Belum ada hasil baru pengujian T-Link/CarPlay/thermal.

Sesudah upgrade, Samsung berada pada kondisi Dozing dan UI yang dapat diakses berasal dari System UI. Karena itu, peluncuran proses tidak dianggap pemeriksaan visual build baru. Screenshot/interaksi native versi awal dan tes widget refactor menjadi bukti UI yang tersedia; pemeriksaan visual ulang setelah perangkat dibuka belum dilakukan.

APK sebelum perubahan branding: `apps/dashtconnect/build/app/outputs/flutter-apk/app-debug.apk`, 150414066 byte. File output sudah digantikan versi 0.2.2+3; checksum versi baru tercantum pada bagian branding. SHA-256 historis versi 0.2.1:

```text
839F224126B4E1C9B645496D61249853D6DD1EEA9073D0D2AAC2C07D8EA93FF4
```

Tidak ada commit/push. Catatan fisik di HP tidak diisi sebagai hasil BERHASIL oleh proses refactor.

## Penggantian nama folder aplikasi

Folder aplikasi memakai nama software: `apps/dashtconnect`. Referensi dokumentasi, ignore Git dan helper build lokal diperbarui. `flutter pub get` dan `flutter analyze` berhasil; Gradle assembleDebug dari lokasi baru BUILD SUCCESSFUL dalam 1 menit 10 detik. Versi/paket dan kode aplikasi tidak berubah. Checksum APK saat ini di atas diperbarui mengikuti hasil build pada lokasi baru. Aplikasi tidak dipasang ulang untuk perubahan nama folder ini.

## Pembersihan cache setelah rename

Folder lama di apps sempat muncul kembali sebagai direktori build kosong, tanpa source atau file lain. Metadata outputs.json Flutter lama masih menyimpan path sebelum rename. Flutter clean dan pub get dijalankan; direktori kosong dikeluarkan ke .local-tools/cache-before-folder-rename, yang diabaikan Git. Build ulang assembleDebug berhasil dalam 50 detik. Sesudah build, hanya apps/dashtconnect tersisa dan metadata output Flutter baru tidak merujuk path lama. Checksum APK saat ini di atas mengikuti build ulang ini. Tidak ada perubahan kode aplikasi atau pemasangan ulang ke HP.

## Branding biru 0.2.2+3

Pemilik memilih #006BFD dari gambar referensi. Tema, empat target uji, logo toolbar, launcher dan splash memakai keluarga biru. Detail desain, aset terpilih dan prompt imagegen ada di [branding](branding.md).

| Pemeriksaan | Hasil |
| --- | --- |
| Regresi Flutter | PASS: 20 tes lulus setelah logo ditambahkan, termasuk 4 tes baru untuk warna/kontras tema terang dan gelap. |
| Analisis/format | PASS: flutter analyze tanpa masalah dan dart format tanpa perubahan. |
| Resource Android | PASS: XML terurai; dua salinan logo untuk Flutter/Android identik; ikon Flutter lama sudah dikeluarkan. |
| Build | PASS: clean assembleDebug berhasil dalam 54 detik. Build incremental pertama tidak memasukkan resource splash setelah override lama dikeluarkan; build bersih memproses ulang resource dan mengatasi kegagalan linking tersebut. |
| Paket | PASS: signature valid, versionName 0.2.2 dan versionCode 3. Nama paket tetap sama. |
| Upgrade Samsung | PASS: install -r berhasil; isi catatan privat sebelum/sesudah upgrade identik. Activity dimulai dan halaman aplikasi terlihat. |
| Pemeriksaan visual awal | PASS: screenshot halaman utama gelap pada Samsung diperiksa; logo, aksen biru dan teks tampil tanpa overflow. |
| Tema terang dan probe | PASS: tema terang dipilih, halaman uji dengan empat nada biru diperiksa, lalu halaman utama terang diperiksa lagi setelah cold start agar tangkapan tidak berada di tengah transisi. Preferensi gelap dipulihkan. Log proses tidak menunjukkan E/flutter atau FATAL EXCEPTION. |

APK historis versi 0.2.2+3: `apps/dashtconnect/build/app/outputs/flutter-apk/app-debug.apk`, 152590538 byte. File output sudah digantikan build terbaru di bagian berikut. SHA-256 historis:

```text
07E303BF8E71CEBFDA3511B730AF161276DB7813FD352D01577DF32E2F7100BB
```

Gate desain dan kontras dijelaskan di dokumen branding. Tidak ada perubahan transport atau kemampuan CarPlay; pengujian head unit/thermal tetap menyusul. Tidak ada commit/push.

## Aplikasi mandiri 0.3.1+5

Pemilik menetapkan receiver harus berada di DashTConnect, internet tetap di iPhone dan Android tanpa WAN. Seluruh pencarian paket, pembuka receiver eksternal, entitas yang hanya mendukung integrasi tersebut serta teksnya dikeluarkan dari source aplikasi dan manifest. Referensi teknis hanya berada di audit pengembangan. T-Link tetap menjadi jalur output yang dituju.

Beranda sekarang menyediakan Siapkan koneksi dan Uji tampilan. Tutorial menjelaskan koneksi lokal dan pengujian Android tanpa internet. Receiver CarPlay bawaan belum tersedia; persiapan jaringan tidak ditampilkan sebagai sesi iPhone aktif.

| Pemeriksaan | Hasil |
| --- | --- |
| Regresi | PASS: 34 tes, termasuk penyimpanan lama, retry, tutorial, pengaturan Android, laporan, tema, redup dan navigasi. Tes launcher yang sudah dikeluarkan diganti cakupan persiapan serta pemulihan pembacaan info. |
| Aksesibilitas | PASS: seluruh langkah tutorial dan navigasi utama pada 320 × 640 dengan teks 200%, rail layar lebar, keyboard dan kontras tema terang/gelap. |
| Format/analisis | PASS: Dart format tanpa perubahan; Flutter analyze tanpa masalah. |
| Pembersihan | PASS: source Dart, tes dan source Android tidak mengandung nama/paket maupun API integrasi receiver eksternal yang telah dihapus. |
| APK | PASS: clean assembleDebug berhasil dalam 1 menit 14 detik; signature valid; versionName 0.3.1 dan versionCode 5. Label/paket lama tidak ditemukan pada kernel Dart, DEX, manifest dan resource APK, termasuk encoding UTF-8/UTF-16. |
| Upgrade Samsung | PASS: install -r berhasil, byte catatan privat sebelum/sesudah upgrade identik dan activity versi baru berjalan. |
| Visual/perangkat | PASS: Beranda gelap pada Samsung diperiksa; tombol persiapan dan uji terlihat, teks terbaca, tidak ada integrasi receiver lain. Proses baru tanpa E/flutter atau FATAL EXCEPTION. |

Gate antislop: PASS untuk perubahan ini. Arah biru #006BFD dari pemilik dipertahankan. Panel mengelompokkan persiapan dengan satu tombol utama; informasi teknis tetap di Pengaturan. Tombol berlabel, teks dapat digulir dan status dibatasi pada fungsi yang tersedia. Tidak ada aset baru atau status koneksi simulasi.

APK terbaru: `apps/dashtconnect/build/app/outputs/flutter-apk/app-debug.apk`, 152610350 byte. SHA-256:

```text
8617F5D953320CE9B5E2BD04FF7B7C4BA76B7A2A88B1D354478D484F9F3B788B
```

Belum diuji/tersedia pada versi 0.3.1: penerimaan CarPlay bawaan, sesi iPhone → Android → T-Link, audio/reconnect sesi dan Android tanpa WAN selama sesi tersebut. Build tersebut menyelesaikan pengeluaran integrasi eksternal dan penyesuaian alur; belum memenuhi fungsi receiver. Tidak ada commit/push atau penghapusan data perangkat.

## Pemisahan Flutter dan Android 0.4.0+6

UI Flutter, adapter host Android, mesin receiver dan source pihak ketiga dipisahkan. Kotlin dipertahankan untuk protokol/hardware; tidak dilakukan migrasi Compose. Library native tidak mengimpor Flutter. Hanya `apps/dashtconnect` yang aktif, tanpa folder aplikasi lama atau modul receiver ganda. Arsitektur dan provenance ada di [arsitektur](architecture.md) dan [alur receiver](receiver.md).

| Pemeriksaan | Hasil dan batas bukti |
| --- | --- |
| Flutter | PASS: analisis bersih, format tanpa perubahan, 40 tes lulus. Termasuk parsing native, prasyarat offline/autentikasi, input tidak valid, izin, status start versus connected, pemisahan event antar view dan surface tetap ketika status berubah. |
| Native | PASS: 19 tes lulus. Crypto/MFi/media memakai fixture sintetis, tanpa identitas runtime. Tes tambahan memeriksa resource dilepas tepat sekali ketika shutdown berlomba dengan akuisisi, urutan penutupan, dan penolakan koordinat sentuh tidak valid. |
| Build | PASS: `:receiver:testDebugUnitTest` dan APK debug berhasil. Build akhir setelah sinkronisasi Dart 31 detik. Paket tetap `io.github.farhanreninda.dashtconnect`, versionName 0.4.0, versionCode 6, minSdk 24, targetSdk 36, compileSdk 37. Signature diverifikasi dengan apksigner. |
| Sumber/aset | PASS: 289 file sumber vendor mempunyai hash upstream dan satu patch PairingStore tercatat. Notice/GPL/Opus ada dalam assets APK. Tidak ada `.pk8`/`.p7b` atau runtime identity pada APK. Source integrasi tidak mencari/membuka paket receiver lain. Nama upstream tetap dipertahankan dalam atribusi source vendor. |
| Upgrade Samsung | PASS: `adb install -r` berhasil; byte `files/research.json` sebelum dan sesudah identik. Tidak dilakukan uninstall/reset atau pengubahan setelan jaringan. |
| Halaman fisik | PASS: Beranda membuka Receiver iPhone, halaman native/Flutter dalam landscape tampil di Samsung dan bisa kembali ke Beranda. Kesiapan autentikasi belum ada, internet Android terdeteksi dan izin perangkat sekitar belum diberikan ditampilkan sesuai keadaan. Tombol redup dan pulihkan dijalankan. Screenshot dark diperiksa tanpa overflow; bagian bawah tersedia melalui scroll. |

Gate antislop untuk UI yang diubah:

- Hard gate PASS: layar persiapan nyata dijalankan di Samsung; tes start/stop dan filter event memakai fake yang terpisah. Tidak mengklaim sesi CarPlay nyata. Kontrol standar memiliki label/tooltip; koneksi nonaktif disertai alasan.
- Purpose gate PASS: biru dan tipografi mengikuti DESIGN.md. Satu tombol koneksi, informasi prasyarat sebelum pemilihan iPhone, serta toolbar berhenti/redup memiliki tujuan langsung.
- Liveliness PASS: ENERGY 1 / RHYTHM 2 / MOTION 1 dipertahankan, warna merek tetap #006BFD, tanpa aset atau animasi baru.
- Craftsmanship PASS: tes receiver 320 × 640 dengan teks 200%, navigasi, state kosong/error serta dua tema dari regresi lulus. Perubahan status tidak membuang platform surface, dibuktikan tes. Konten CarPlay dari iPhone belum menjadi cakupan visual/aksesibilitas yang terverifikasi.

APK: `apps/dashtconnect/build/app/outputs/flutter-apk/app-debug.apk`, 157231682 byte. SHA-256:

```text
21CE45E14464FA63359106DE9A263283EF7AAF31A7282D45211207DDC8DC7715
```

Pemilik memilih menyelesaikan perapian folder terlebih dahulu; identitas eksperimen tidak dimasukkan. Belum diuji: autentikasi aksesori pada iPhone, bootstrap dan penerimaan video/audio nyata, output/sentuhan T-Link, Android tanpa WAN selama sesi, ketahanan dan panas. Mikrofon serta reconnect otomatis belum tersedia. Pemeriksaan kapabilitas internet OS bersifat konservatif dan bukan audit trafik WAN.

Peringatan build yang tersisa: AGP 9.1 diuji sampai SDK 36.1 sedangkan source memakai SDK 37; migrasi KGP menuju built-in Kotlin akan diperlukan pada Flutter mendatang. Build saat ini berhasil tanpa menyembunyikan peringatan. Tidak ada commit/push.

## Redesign seluruh UI 0.4.1+7

Lihat [laporan redesign dan pemeriksaan landscape](ui-redesign.md) untuk cakupan halaman, design system, bukti serta batas pekerjaan.

- PASS: 50 tes Flutter, analisis bersih dan format tanpa perubahan. Cakupan baru meliputi semua rute pada landscape, dua tema, teks hingga 200%, font aplikasi sebenarnya, rotasi sambil mengisi, keyboard, dialog, laporan dan fokus.
- PASS: APK akhir dibangun 27 detik, signature valid, versi 0.4.1+7 dan terpasang sebagai upgrade pada Samsung A04s. Byte catatan privat tetap sama selama pemasangan.
- PASS: inspeksi fisik portrait/landscape mengoreksi ambang dua kolom dari 700 ke 600 dp berdasarkan lebar setelah navigation rail. Tombol koneksi terlihat sebelum scroll pada landscape normal.
- PASS: tema dan rotasi awal dipulihkan. Inventaris dan hasil percobaan tetap identik setelah uji UI; tidak dibuat catatan pengujian palsu pada HP. Tidak ditemukan E/flutter atau FATAL EXCEPTION pada proses sendiri.
- Batas: redesign tidak mengubah protokol atau menambahkan identitas aksesori. CarPlay/T-Link nyata serta performa/thermal sesi masih belum terverifikasi. APK yang diperiksa adalah build debug, tanpa klaim angka FPS/latensi dari referensi.

APK redesign 0.4.1+7: 157761576 byte, SHA-256 `E2DFA125AB8F1264CF7E67967EC81681164445D67D0F6570087909D78DF96F9F`. Tidak ada commit/push.

### Splash 0.4.2+8

Latar splash Android dan Flutter sekarang putih/hitam sesuai tema. Warna biru tetap di logo. Flutter memberi fade 65–100% dan skala 92–100% selama 600 ms, satu kali saat startup. Reduce motion melewati animasi. Latar native window juga memakai logo selama engine disiapkan; status/navigation bar memakai warna dan kontras sesuai tema.

- PASS: 55 tes Flutter lulus, termasuk lima tes splash; lima tes tersebut diulang setelah perapian akhir. Memeriksa kedua tema, landscape pendek, aset logo, animasi, reduce motion, data yang belum selesai dibaca serta error dan retry. Analisis kode bersih.
- PASS: build akhir 39 detik, signature APK valid, versi 0.4.2+8 dipasang sebagai upgrade pada Samsung A04s. Byte data privat tetap identik. Screenshot pembukaan terang/gelap dan logo Flutter membulat diperiksa; tema sistem dipulihkan dan pilihan tema aplikasi tidak diubah. Log proses sendiri menunjukkan nol error Flutter dan nol FATAL EXCEPTION.
- APK: 157768468 byte; SHA-256 `45D6D3E51B5FFD57042A6C8A76FBDCCDA71D3FE8A2A2873F178E8A574AA17B55`.
- Batas: splash Android pertama mengikuti tema sistem; setelah data terbaca, Flutter mengikuti pilihan tema aplikasi tersimpan. Belum diuji pada Android di bawah versi 12. Perubahan ini tidak menyentuh protokol receiver atau data catatan.

Gate desain untuk perubahan splash:

- Hard gate PASS: kedua tema dan landscape diuji; tidak ada kontrol baru atau klaim koneksi. Error dan retry tetap bekerja.
- Purpose gate PASS: animasi singkat diminta pemilik dan menekankan logo; tanpa loop, glow atau elemen dekoratif tambahan.
- Liveliness PASS: ENERGY 1 / RHYTHM 2 / MOTION 1 dipertahankan; satu logo biru menjadi fokus pada bidang netral.
- Craftsmanship PASS: aset lama dipakai, reduce motion diuji, screenshot Samsung diperiksa dan upgrade mempertahankan data. Android di bawah 12 belum diperiksa secara fisik.

### Kontrol redup terpusat 0.4.3+9

Mode redup kini hanya di Pengaturan → Layar → Mode redup. Duplikat pada toolbar utama, toolbar receiver dan halaman Uji tampilan dihapus, beserta parameter/callback dan StatefulBuilder yang tidak lagi diperlukan. State redup tetap dimiliki ResearchHome sehingga tetap aktif saat berpindah halaman dan bisa dipulihkan dari sakelar yang sama. Mekanisme native dan penyimpanan tidak berubah.

Petunjuk Uji tampilan menjelaskan tujuan pemeriksaan gambar serta input T-Link: saat mobil parkir, tampilkan Android pada HU dan tekan empat kotak dari HU. Penghitung HP harus ikut bertambah. Ini tidak membuktikan sesi CarPlay berhasil.

- PASS: 55 tes Flutter, termasuk regresi lokasi tunggal kontrol redup, akses keyboard, perubahan tema, penghitung sentuhan dan pemulihan kecerahan setelah kembali dari probe. Pemeriksaan dua tema, landscape pendek dan teks 200% tetap lulus. Analisis kode bersih.
- Hard gate PASS: kontrol yang tersisa memiliki tindakan nyata; state redup dan penghitung diuji. Tidak ada kontrol duplikat atau klaim koneksi baru.
- Purpose gate PASS: satu sakelar mengurangi pilihan berulang; petunjuk probe langsung menjelaskan langkah dan hasil yang diperiksa.
- Liveliness PASS: desain ENERGY 1 / RHYTHM 2 / MOTION 1 dipertahankan; warna dan komponen memakai tema yang sama.
- Craftsmanship PASS: caller dan tes diperbarui, parameter yang tak terpakai dihapus, error handling dan pemulihan kecerahan dipertahankan. Perubahan presentasi tidak mengubah protokol receiver.
- PASS fisik Samsung A04s: versi 0.4.3+9 dipasang sebagai upgrade dengan data privat identik. Toolbar beranda tanpa tombol redup, satu sakelar pada Pengaturan → Layar, halaman probe tanpa tombol redup, target sentuhan bertambah dan sakelar dikembalikan ke nonaktif. Screenshot pengaturan/probe diperiksa. Koneksi gambar dan input pada head unit mobil belum diuji.
- APK debug: build berhasil 1 menit 6 detik dan signature valid. Ukuran 157766960 byte; SHA-256 `763B659403835B850BDD7CB3A195F0D59CC8475D50E1CD0E2313784625431488`.

### Redesign dan optimasi UI 0.5.0+10

Beranda tidak lagi membaca atau menampilkan info Android. Informasi perangkat dikategorikan di Pengaturan, dock/rail memakai komponen khusus, dan tab yang sudah dibuka dipertahankan. Tema dicache dan decode logo dibatasi sesuai ukuran tampil. Seluruh perubahan, audit bottleneck, bukti dan batas pengukuran tercatat di [UI dan performa](ui-performance.md).

62 tes Flutter lulus, analisis bersih, build akhir 31 detik dan signature APK valid. Upgrade pada Samsung mempertahankan byte data privat; tema dan rotasi uji dipulihkan. Tidak ada benchmark FPS release atau uji CarPlay/T-Link nyata untuk perubahan ini. APK terbaru: 157770476 byte, SHA-256 `8B17F66302D8142AFB53E6A73FB3642F26F3737582CAEBD6C1A5EDF45F8FC8A7`.

### Halaman Tampilan 0.5.1+11

Pilihan tema pindah dari popup ke Pengaturan → Layar → Tampilan. Halaman penuh menyediakan Sesuai perangkat, Terang dan Gelap, dengan penjelasan singkat. Pengaturan memakai judul dan deskripsi yang lebih ringkas. Sakelar redup tetap satu tempat.

- 67 tes Flutter lulus dan analisis bersih. Cakupan baru: pilihan tersimpan, teks 200% pada landscape pendek dalam kedua tema, pilihan tetap saat save gagal, retry dan pencegahan save bersamaan. Navigasi kembali dan integrasi preferensi aplikasi tetap diuji.
- Samsung A04s: menu terbuka sebagai halaman penuh, pilihan terang/gelap dan tombol kembali diperiksa. Screenshot kedua tema ditinjau. Tema awal gelap dipulihkan dan byte data privat tetap identik setelah uji. Perangkat lain belum diuji secara fisik.
- Build debug 30 detik; APK 0.5.1+11 terpasang sebagai upgrade dan signature valid. Ukuran 157773108 byte; SHA-256 `34777CB11F30CB6E3DC5AB78E3F40C8A1922F7891CEF11912948EF3EB400D1E9`.
- Hard gate PASS: popup dihapus, tiga opsi memiliki aksi simpan nyata, reflow serta error/retry diuji. Tidak ada fitur koneksi baru.
- Purpose gate PASS: halaman tersendiri diminta pemilik, label lebih pendek dan pilihan aktif tetap jelas. Tidak ada dekorasi atau animasi tambahan.
- Liveliness PASS: ENERGY 1 / RHYTHM 2 / MOTION 1 dipertahankan; warna dan tipografi mengikuti tema bersama.
- Craftsmanship PASS: caller, regresi navigasi dan data preferensi diperbarui. Pilihan yang gagal tidak ditandai sebagai tersimpan; state data pengguna dipertahankan pada upgrade.

### Pengaturan ringkas dan Tentang 0.5.2+12

Catatan pengujian, laporan lokal dan formulir inventaris manual dikeluarkan dari UI. Informasi perangkat hanya membaca data Android aktual; snapshot inventaris lama tidak ditampilkan sebagai data perangkat saat ini. Halaman Tentang tersendiri menampilkan logo, versi, tujuan aplikasi dan status receiver.

- 64 tes fitur aktif lulus dan analisis bersih. Tiga tes khusus editor/form eksperimen dipensiunkan bersama UI tersebut; tes codec, validasi data lama dan penyimpanan tetap dipertahankan. Regresi memeriksa menu yang dihapus, ketiadaan form, pembacaan native, retry, About dan data yang tidak berubah. Kedua tema, landscape dan teks 200% tetap diuji.
- Samsung A04s: menu Pengaturan, halaman About dan data model/Android asli diperiksa. Upgrade dan kunjungan halaman tidak mengubah byte catatan privat. Screenshot ditinjau; belum diuji fisik pada perangkat lain.
- APK debug 0.5.2+12: build 26 detik, signature valid dan dipasang sebagai upgrade. Ukuran 157756192 byte; SHA-256 `BE93CB2AB9CDE4D2FC0A213995021473B0AD0CE0DD4BD5C153A688DFC01C12C6`.
- Hard gate PASS: menu lama benar-benar tidak ada, informasi berasal dari gateway Android dan halaman tidak menulis inventaris atau hasil. Navigasi serta reflow lulus tes.
- Purpose gate PASS: hanya informasi perangkat dan Tentang dipertahankan sesuai permintaan. Logo/versi serta uraian singkat memberi hierarki pada halaman Tentang tanpa elemen dekoratif tambahan.
- Liveliness PASS: ENERGY 1 / RHYTHM 2 / MOTION 1 dan aksen biru dipertahankan; informasi perangkat memakai kategori, Tentang memakai identitas aplikasi.
- Craftsmanship PASS: UI editor tak terpakai beserta callback/import dihapus. Data persisten, tema, tutorial dan receiver tidak direset atau diubah protokolnya.

### Informasi perangkat otomatis 0.5.3+13

Sumber nilai diverifikasi pada DeviceChannel: model/versi memakai Build Android, jaringan memakai ConnectivityManager/NetworkCapabilities, dan suhu/daya memakai informasi baterai sistem. Tidak ada spesifikasi Samsung yang ditanam pada UI. Pembacaan terjadi saat membuka halaman atau menekan Perbarui, tanpa polling.

Ringkasan model/Android menggantikan judul dan accordion besar. Kartu Koneksi serta Baterai dan daya menunjukkan nilai umum; fitur USB/Wi-Fi Direct, arsitektur, hardware dan field tambahan tetap dapat dibuka melalui Detail teknis. Waktu pembaruan ditampilkan dari pembacaan terakhir yang berhasil. Error tampil dekat tombol Perbarui dan tidak menghapus data terakhir.

- 64 tes lulus, analisis bersih. Regresi mengubah nilai gateway ke model lain lalu membaca ulang, memeriksa field tambahan, retry dan data terakhir saat gagal. Kedua tema, landscape pendek serta teks 200% tetap lulus.
- Samsung A04s: ringkasan model/Android, nilai jaringan/baterai dan detail teknis diperiksa secara fisik. Screenshot ditinjau. Upgrade dan kunjungan halaman mempertahankan byte data privat. Perangkat lain belum diuji secara fisik.
- Build debug 22 detik, signature APK valid dan 0.5.3+13 terpasang sebagai upgrade. Ukuran 157758416 byte; SHA-256 `81E4193BCE0DD35D492AA073B646628F5C61426436AC8E210A7B90F44B74CEBE`.
- Hard gate PASS: nilai berasal dari gateway sistem, tidak ada model atau suhu contoh. Pembacaan ulang/error dan reflow diuji.
- Purpose gate PASS: kartu memisahkan identitas, koneksi dan daya; ikon sesuai kategori. Detail langka tidak memenuhi ringkasan.
- Liveliness PASS: ENERGY 1 / RHYTHM 2 / MOTION 1 dipertahankan, dengan aksen biru dan tanpa animasi berulang.
- Craftsmanship PASS: data native tetap utuh, waktu baca terpisah, state error mempertahankan snapshot terakhir, dan callback/tes diperbarui. Tidak mengubah izin atau protokol receiver.
### Perapian Detail teknis dan pembaruan 0.5.4+14

Padding header/isi Detail teknis disamakan menjadi 20. Waktu pembacaan terakhir dan tombol selebar kartu digabung dalam satu panel. Pembacaan, retry dan penyimpanan data tidak berubah.

- 66 tes lulus dan analisis bersih, termasuk detail terbuka serta pembaruan pada 320×640 dan 640×320 dengan teks 200%.
- Build debug berhasil 23 detik; signature valid. Upgrade terpasang pada Samsung A04s dan byte catatan privat tetap sama. Panel pembaruan ditinjau melalui screenshot; struktur detail terbuka diperiksa melalui UI perangkat. Perangkat lain belum diuji fisik.
- APK 157758980 byte; SHA-256 `9cd2f77f266ab6cfcaae6c168fe5c5a5acdd8a8ccc590a5dc2b436b877703c64`.
- Hard gate PASS: nilai tetap berasal dari gateway; tes refresh/error dan snapshot terakhir lulus.
- Purpose gate PASS: padding konsisten, waktu dan tindakan berada dalam satu kartu.
- Liveliness PASS: aksen biru dan gaya kartu dipertahankan tanpa animasi tambahan.
- Craftsmanship PASS: nilai panjang membungkus, teks besar serta landscape diuji; tidak menambah dependensi atau polling.

### Navigasi dan build release 0.5.5+15

- Efek fade seluruh tab dihapus. Retensi element/posisi, lazy tab dan TickerMode tetap dipertahankan. 66 tes lulus, analisis bersih; regresi tema, landscape, teks 200%, retry dan navigasi tetap lulus.
- Build release arm64 berhasil dalam 4 menit 10 detik, termasuk AOT Dart dan R8. APK ditandatangani lokal memakai sertifikat development yang sama dengan APK sebelumnya agar bisa dipasang sebagai upgrade; ini belum merupakan konfigurasi signing distribusi produksi. Signature diverifikasi dan digest sertifikat dibandingkan.
- Samsung A04s menerima upgrade 0.5.5+15 tanpa uninstall/reset. Flag DEBUGGABLE tidak ada. Tema gelap dan tutorial selesai tetap terbaca. Hash catatan sebelum upgrade dicatat; byte privat sesudah upgrade tidak dibaca ulang karena run-as tidak tersedia pada release.
- Beranda → Panduan → Pengaturan serta kembali ke Beranda/Pengaturan diperiksa pada perangkat. Posisi/state dipertahankan melalui tes widget; tidak ada pengukuran FPS antarmenu. Tidak mengklaim semua stutter sudah hilang.
- Tiga pengukuran process cold start menggunakan `am start -W`: TotalTime debug 8460/6751/7121 ms, release 860/876/930 ms pada perangkat yang sama. Ini sampel waktu Activity mencapai tampilan awal, bukan FPS, waktu splash selesai, atau benchmark statistik terkontrol. Mode build dan penghapusan fade berubah bersamaan.
- APK release arm64 21146364 byte; SHA-256 `69c2588546b955d16590060f702196bf60a70f3f2389d201c4d09355d1eeb041`. APK debug lama tetap artefak versi sebelumnya dan bukan hasil pengujian release ini.
- Hard gate PASS: regresi fungsi/error, aksesibilitas dan state lulus; tidak menambahkan data atau klaim koneksi palsu.
- Purpose gate PASS: transisi tab langsung mengurangi pekerjaan opacity seluruh halaman; indikator navigasi tetap memberi umpan balik.
- Liveliness PASS: identitas biru, dock dan gerak indikator singkat dipertahankan.
- Craftsmanship PASS: controller fade yang tidak diperlukan dihapus, versi/build diperbarui, release diverifikasi. Perangkat lain serta sesi CarPlay/T-Link belum diuji pada build ini.

### Splash stabil dan Beranda ringkas 0.5.6+16

- Splash Flutter tidak lagi mengubah skala/opacity logo. Logo tetap 128 dp, nama aplikasi memakai fade 320 ms. Nama tidak ditampilkan pada tinggi konten kurang dari 280 dp; reduce motion tetap melewati intro. Tes memeriksa bounds logo tidak bergerak selama animasi, dua tema, layar pendek, penyelesaian sekali, error dan data tertunda.
- Android 12+ memakai drawable splash khusus dengan inset 27,777778%, alih-alih ikon launcher adaptive. Perhitungan mengikuti area ikon tanpa latar 288 dp pada [panduan Android](https://developer.android.com/develop/ui/views/launch/splash-screen), untuk target logo 128 dp. Pada tangkapan Samsung, logo native berukuran 240×240 piksel pada density 1,875. Tangkapan berurutan tidak mencakup setiap frame animasi.
- Beranda memakai “Koneksi ke layar mobil”, penjelasan singkat pemeriksaan perangkat dan satu pintasan Uji tampilan. Tombol Siapkan koneksi dihapus. Tutorial tetap dapat dibuka melalui Panduan → Buka tutorial. Kartu P diganti satu baris “Lakukan pengaturan saat mobil terparkir.” Status autentikasi dan receiver tidak diubah.
- 67 tes lulus dan analisis bersih; tes alur tutorial mengikuti pintasan yang baru. Regresi landscape, dua tema, teks 200%, retensi tab dan retry tetap lulus.
- Build release arm64 berhasil 1 menit 44 detik. Signature diverifikasi; upgrade ke Samsung berhasil tanpa uninstall atau reset. Flag DEBUGGABLE tidak ada, tema gelap dan tutorial selesai tetap terbaca. Beranda dan akses Panduan diperiksa secara fisik; perangkat lain belum diuji.
- APK 21146420 byte; SHA-256 `992b884c4e6a0bfee8f21fd62d3ae443e4b14a579887e79e93cc14fa20cd50c0`.
- Hard gate PASS: bounds tetap, reduce motion, pemuatan gagal/tertunda dan reflow diuji; tidak ada klaim CarPlay aktif.
- Purpose gate PASS: satu pintasan tutorial di Panduan, pengingat sekunder tanpa kartu besar, identitas splash tetap diam.
- Liveliness PASS: biru merek dan fade nama singkat dipertahankan, tanpa zoom atau animasi berulang.
- Craftsmanship PASS: sumber native/Flutter, caller tutorial, tes dan versi diperbarui; tema dan data tidak direset. Tidak menambah dependensi.

### Handoff splash dan uji T-Link 0.5.7+17

- Frame pertama ditahan sampai gambar logo selesai dimuat melalui ImageCache; pasangan deferFirstFrame/allowFirstFrame tetap dilepas setelah precache selesai, termasuk error. Tidak ada zoom atau penundaan buatan. Tes baru memastikan handoff melepas frame pertama dan ukuran logo tetap 128 dp; tes intro, reduce motion dan kegagalan catatan tetap lulus.
- Uji tampilan dipindahkan dari Beranda ke Panduan → Pengecekan T-Link. Tutorial tetap membuka halaman yang sama. Beranda hanya berfokus pada receiver.
- Area uji menampilkan empat warna, ikon untuk target yang disentuh, jumlah target unik dan reset selebar kartu. Petunjuk ada setelah area uji. Angka tidak diberi status lulus/terhubung karena input HP juga dihitung.
- Pada landscape pendek, intro dipersingkat dan empat kolom dipakai jika cukup lebar. Inspeksi awal perangkat menunjukkan target bawah terpotong pada desain dua panel; layout diubah menjadi area uji selebar halaman. Tes memeriksa semua target terlihat dalam 800×360 pada font normal. Font 200% tetap dapat menggulir.
- 68 tes lulus; analisis bersih. Regresi lokasi menu, tutorial, empat target, ringkasan/reset, state saat rotasi, kontras dua tema dan landscape diperbarui.
- Build release arm64 akhir berhasil dalam 51 detik; signature valid dan upgrade terpasang tanpa uninstall/reset. Paket 0.5.7, code 17, tanpa flag DEBUGGABLE. Tema gelap dan status tutorial tetap terbaca.
- Samsung A04s: lokasi menu diperiksa, satu target disentuh melalui input Android, nilai 1 tetap ada setelah rotasi. Empat target terlihat sekaligus dalam landscape; reset kembali 0 dan portrait lock 0 dipulihkan. Screenshot portrait/landscape ditinjau. Ini bukan pengujian input head unit.
- Tangkapan raw splash menunjukkan logo native tetap 240×240 piksel pada sampel awal. Tangkapan ini tidak mencakup setiap frame handoff dan bukan pengukuran FPS. Belum ada uji T-Link fisik atau sesi CarPlay.
- APK akhir 21146420 byte; SHA-256 `205f0d0e9777ef1c3531d0c3ab2c9090a66b89994ac64893439610391a69a4ac`.
- Hard gate PASS: kontras, reflow, reset dan state diuji; tidak menampilkan kelulusan atau koneksi palsu.
- Purpose gate PASS: tes ditempatkan dalam Panduan, empat target menjadi fokus, petunjuk setelah pengujian.
- Liveliness PASS: empat tingkat biru diperlukan untuk membandingkan tampilan; indikator sentuh merespons input tanpa animasi berulang.
- Craftsmanship PASS: caller, tutorial, tes, versi dan penjelasan fitur diperbarui; tidak menambah dependency atau mengubah protokol receiver.

### Splash tanpa kotak dan antarmuka padat 0.5.8+18

- Bitmap splash diganti simbol garis biru dengan bagian dalam/latar transparan. Android menggunakan vector 288 dp dengan grup 128 dp dan AnimatedVectorDrawable trimPathEnd 240 ms; Flutter menggambar geometri yang sama melalui CustomPainter. Nama memakai fade 180 ms. Decode/precache/deferFirstFrame lama dihapus karena tidak ada bitmap yang perlu dimuat. Ikon launcher/header tidak berubah.
- Tes raster memeriksa piksel sudut dan bagian dalam simbol transparan, serta warna garis RGBA 0/107/253/255. Bounds 128 dp tetap selama animasi; dua tema, reduce motion, layar pendek dan pemuatan catatan gagal/tertunda tetap lulus. Screenshot startup memperlihatkan simbol garis dan nama tanpa tile biru. Tidak mengklaim hasil pengukuran FPS atau seluruh frame animasi native.
- Beranda menampilkan receiver dan diagram alur dalam kolom adaptif. Teks “pilih iPhone…” dihapus; teks berulang “siapkan” pada Beranda/Panduan diganti. Tidak menambahkan status koneksi atau data simulasi.
- Bantuan koneksi memakai panel per topik, ikon dan langkah bernomor. Informasi autentikasi yang belum tersedia tetap dijelaskan. Bagian Layar memadatkan dua kontrol dan memakai subtitle redup; Informasi perangkat/Tentang menjadi kelompok dua ListTile dengan metrik sama. Tes font asli pada 384×820 memeriksa tinggi kedua baris identik; UI perangkat juga menunjukkan tinggi 135 piksel per baris.
- Padding konten/kartu dan gap kolom dipadatkan. Intro pendek, diagram horizontal ringkas, header Tentang satu baris dan judul tutorial kecil digunakan untuk landscape. Pilihan tema memakai tiga kolom jika lebar cukup dan font normal, dengan fallback vertikal untuk ruang sempit/teks besar. Ketiga pilihan terlihat pada 800×360 dan tetap dapat dipilih pada 200%.
- 71 tes lulus; analisis bersih. Matrix dua tema, seluruh rute, landscape, teks 200%, retensi tab, retry dan penyimpanan tema lulus. Pemeriksaan perangkat mencakup Beranda, bantuan, Pengaturan, Tampilan, Tentang dan informasi Android dalam landscape; screenshot ditinjau. Rotasi awal lock 0 dan tema gelap dipertahankan. Receiver nyata, input head unit dan perangkat selain Samsung A04s belum diuji secara fisik.
- Build release arm64 akhir berhasil 51 detik; signature valid dan upgrade terpasang tanpa uninstall/reset. Paket 0.5.8, code 18, tanpa flag DEBUGGABLE. APK 21150628 byte; SHA-256 `a13aa577e39227238861946b86741446adef2b7c6bc7db379cc3c0251fc9e2e5`.
- Hard gate PASS: transparansi/warna raster, reflow, kontrol, state dan kontras diuji; validasi receiver tidak dilonggarkan.
- Purpose gate PASS: halaman berfokus pada aksi/diagram, bantuan dipecah menjadi langkah, pengaturan dan informasi tidak memakai kartu dengan tinggi berbeda.
- Liveliness PASS: simbol biru tanpa bidang kotak, gerak garis singkat dan fade nama; tanpa zoom, glow atau animasi berulang.
- Craftsmanship PASS: bitmap splash/callback decode yang tidak diperlukan diganti, caller dan regresi mengikuti layout aktual, tidak menambah dependency dan tidak mereset catatan.

### Ukuran kartu Panduan 0.5.9+19

- AppActionTile memakai tinggi minimum seragam 112 dp yang mengikuti skala teks, tanpa batas tinggi maksimum. Deskripsi Bluetooth/uji dipersingkat; ikon dekoratif memberi ruang pada teks di atas 125%.
- Tiga regresi baru memeriksa ukuran identik untuk Wi-Fi, Bluetooth dan Uji tampilan pada 320×640/800×360 dan teks 100/150/200%. 74 tes lulus; analisis bersih. Keyboard, aksi asli, dua tema dan alur tutorial tetap lulus.
- Release arm64 berhasil 1 menit 19 detik, signature valid, upgrade terpasang tanpa reset. Samsung A04s: UI bounds ketiga kartu sama, masing-masing 645×210 piksel, dan screenshot ditinjau. Ini pemeriksaan portrait pada font perangkat saat ini; landscape/font besar diperiksa otomatis.
- APK 21150628 byte; SHA-256 `da4d5fddd2b5a205abed57e5f7d4e7c773c88e8af52ba50421b424ccefa12ca7`.
- Hard gate PASS: ukuran, wrapping, pembesaran teks dan tindakan lulus tanpa ellipsis atau pemotongan teks.
- Purpose gate PASS: tiga aksi Panduan memakai dimensi/radius/warna konsisten.
- Liveliness PASS: ikon biru dan feedback fokus/tekan dipertahankan.
- Craftsmanship PASS: batas minimum diperbaiki pada komponen bersama, tidak memakai tinggi maksimum yang dapat memotong konten; regresi mengikuti label nyata.

### Kartu ringkas, peringatan dan tema 0.5.10+20

- Tiga kartu Panduan menjadi 80 dp pada teks normal, padding 12 dp dan ikon 40 dp. Pada teks di atas 125%, minimum mengikuti 104 dp dikali skala teks; tidak ada batas maksimum. Regresi ukuran identik pada 320×640/800×360, teks 100/150/200%, tetap lulus dan memeriksa tinggi normal tidak melebihi 80 dp.
- AppNotice.warning menyatukan peringatan parkir, receiver/autentikasi, jaringan, Bluetooth, redup dan pengujian. Ikon segitiga memiliki label aksesibilitas “Peringatan”, dengan latar/garis amber sesuai tema. Pesan gagal memakai ikon error dan kartu merah. Dua tes baru memeriksa ikon, garis tepi dan kontras teks minimal 4,5:1 pada kedua tema.
- Beranda memakai “Kelola koneksi iPhone dan layar mobil dari satu tempat.” Bagian Layar memakai judul di luar panel, ikon palet/kecerahan sejajar, keterangan singkat dan hanya satu sakelar redup. Informasi perangkat/Tentang tetap berukuran sama.
- Halaman Tampilan memakai tiga kartu pilihan dengan pratinjau tema, radio dan garis pilihan aktif. Layout tiga kolom pada landscape cukup lebar, vertikal pada ruang sempit/teks besar. Pratinjau dekoratif hilang di atas 150% agar tulisan mendapat ruang. Guard penyimpanan, kegagalan/retry, keyboard dan semantik radio dipertahankan.
- 76 tes lulus; flutter analyze bersih. Screenshot Samsung A04s untuk Beranda, Pengaturan dan halaman Tampilan ditinjau. Pemeriksaan landscape dan teks besar dilakukan otomatis; perangkat kemudian digunakan untuk aplikasi lain sehingga pemeriksaan UI fisik lanjutan dihentikan.
- Hard gate PASS: ukuran kartu, reflow, kontrol, state dan kontras lulus. Tidak ada status koneksi palsu atau perubahan validasi receiver.
- Purpose gate PASS: kartu aksi ringkas, peringatan dibedakan dari informasi, pilihan tema menampilkan contoh visual.
- Liveliness PASS: feedback tekan/fokus dan pilihan aktif dipertahankan tanpa animasi berulang atau dependency baru.
- Craftsmanship PASS: komponen bersama, seluruh caller peringatan dan regresi diperbarui; data pengguna tidak direset. Head unit, CarPlay nyata dan HP lain belum diuji secara fisik.
- Release arm64 akhir berhasil 41 detik; signature terverifikasi dan pembaruan terpasang menggunakan install -r tanpa uninstall/reset. APK 21150628 byte; SHA-256 `f54be3262c86c903c611feb56966da6ad8c041cbb12c95f76aafd5fe10a7526f`. Paket terpasang 0.5.10/code 20 tanpa flag DEBUGGABLE. Aplikasi lain yang sedang digunakan tidak diambil alih setelah pemasangan akhir.

### Provisioning dan uji iPhone 0.6.0+21

- Pemilik memilih mencoba untuk dirinya sendiri sebelum mempertimbangkan publikasi. Dua aset eksperimen diambil dari release publik DiPlay 0.2.21, tanpa memasang atau membuka APK referensi. Digest APK sumber cocok dengan GitHub release; provenance ada di THIRD_PARTY_NOTICES.md dan lokal yang diabaikan Git. Kunci P-256 dan sertifikat tunggal berhasil diparse serta cocok melalui tantangan lokal. Kedua assets pada APK keluaran cocok byte-for-byte dengan input terverifikasi; tidak ada kunci dicetak pada keluaran tool.
- Release wajib menjalankan validateReceiverAuthentication sebelum mergeReleaseAssets. Pemeriksaan nyata menolak environment yang hilang dan direktori dengan file tambahan; input yang dipilih lulus. Debug UI tetap dapat dibuat tanpa aset. Guard offline serta pemeriksaan autentikasi pada UI/native tetap aktif.
- 76 tes Flutter, analyze bersih, dan 20 tes native lulus. Tes baru membuktikan diagnostik protokol mempertahankan ID pesan/tahap tanpa meneruskan payload, nama, alamat atau sandi. Bonjour memakai diagnosticSummary dari sumber, berisi hitungan, status dan kategori. Kesalahan startup mencatat kelas exception dan posisi kode, tanpa pesan exception yang mungkin berisi data sensitif. Pesan Wi-Fi mati kini memberi tindakan yang spesifik.
- Samsung A04s/Android 14, iPhone 11/iOS 27.0, keduanya dekat dan Samsung melalui USB ke laptop. Upgrade mempertahankan data. Warning autentikasi yang hilang menghilang; memilih iPhone membuat tombol Hubungkan iPhone aktif. Percobaan pertama dengan Wi-Fi Samsung mati gagal. Setelah Wi-Fi dinyalakan tanpa WAN, bootstrap menerima identification dan authentication, lalu 0x5702/0x5703, 0x4e0d/0x4e0e dan 0x4300/0x4301. Ini bukti penerimaan autentikasi awal, bukan sesi CarPlay lengkap.
- Pengguna tidak melihat popup iPhone dan menyatakan ada entri DashTConnect/Samsung di Pengaturan CarPlay. Permintaan mencari izin saat terkunci tidak membantu karena pengguna tidak menemukan opsi; instruksi diganti agar iPhone tetap terbuka. Jangan menganggap opsi tersebut penyebab yang sudah terbukti.
- Percobaan dengan diagnostik berakhir IPHONE_VIDEO_TIMEOUT. Snapshot: bonjourAdded=0, bonjourResolved=0, connectProbes=0, mdnsFamilies=IPv4. Belum dapat menyimpulkan apakah iPhone tidak bergabung Wi-Fi, discovery tidak sampai, atau izin/sesi belum lengkap. Gambar, audio, sentuhan, dan T-Link pada receiver baru belum terbukti. Pemeriksaan berikut membutuhkan tampilan Pengaturan CarPlay pada iPhone; pairing tidak dihapus atau direset secara otomatis.
- Build akhir release arm64 berhasil, signature terverifikasi, versi 0.6.0/code 21 tanpa DEBUGGABLE terpasang. APK uji pribadi ini tidak dipublikasikan. Kelayakan distribusi identitas eksperimen belum dipastikan.

### Bantuan perpindahan Wi-Fi 0.6.1+22

- Screenshot iPhone pemilik memperlihatkan entri DashTConnect dengan sakelar CarPlay aktif. Opsi izin saat terkunci tidak terlihat; tidak dianggap prasyarat pengujian dengan iPhone terbuka atau akar masalah yang terbukti.
- Setelah paket start sesi dikirim melalui Bluetooth, native meneruskan SSID/sandi jaringan sementara melalui event terstruktur. Adapter menolak payload yang salah tipe, panjang tidak valid, NUL atau kredensial pada fase selain connecting. Event lama tanpa Wi-Fi tetap diterima.
- Pada layar koneksi, panel “iPhone belum masuk Wi-Fi?” memberi langkah bergabung manual. Sandi tersembunyi sampai diminta dan tidak disalin otomatis, disimpan dalam notebook atau dicatat ke log. State dibuang ketika percobaan berhenti, gagal atau terhubung. Timeout bootstrap dan tunggu gambar menjadi tiga menit untuk memberi waktu bergabung manual. Ini tidak menjamin auto-join maupun keberhasilan sesi CarPlay.
- 79 tes Flutter lulus; analyze bersih. Regresi baru memeriksa validasi payload native, kompatibilitas event lama, sandi tersembunyi sampai diminta, pembuangan setelah gagal dan percobaan baru, serta penggunaan landscape 800×360 pada teks 100/200%.
- Hard gate PASS untuk validasi payload, state dan reflow otomatis; sesi gambar/audio tetap belum terbukti dan harus diuji fisik.
- Purpose gate PASS: bantuan berisi tindakan nyata untuk tahap Wi-Fi yang macet, tanpa menambahkan informasi umum pada Beranda.
- Liveliness PASS: panel mengikuti status sesi dan tombol tampil/sembunyi tanpa animasi dekoratif atau polling.
- Craftsmanship PASS: domain, adapter, host Android, mesin receiver, UI dan pengujian memakai event yang sama; tidak menambahkan dependency.
- Release arm64 0.6.1/code 22 berhasil 2 menit 27 detik; 20 tes native lulus, signature terverifikasi dan install -r berhasil. Dua aset autentikasi dalam APK cocok dengan input terverifikasi. APK 21888065 byte, SHA-256 `aed06914b7cae6ae044e7e11c6db8f1d1cbe7efbb8276eb68d20e625101a0aa6`.
- Pemeriksaan Samsung: memilih iPhone dan menekan Hubungkan iPhone berhasil; autentikasi awal diterima. Panel Wi-Fi dapat dibuka dan tombol Tampilkan sandi ditekan. Tidak mengambil screenshot/dump label setelah sandi terlihat. Pemilik diminta memilih jaringan pada iPhone; hasil bergabung dan sesi gambar masih menunggu pengujian langsung.

### Keberhasilan gambar dan sentuh 0.6.2+23

- Pemilik melaporkan jaringan 0.6.1 tidak terlihat di iPhone. Pemeriksaan grup Samsung memperlihatkan group owner aktif pada 5180 MHz/kanal 36. Untuk membandingkan kompatibilitas, host membatasi auto-channel ke AUTO_2_4_GHZ. Log 0.6.2 mengonfirmasi 2412 MHz; identifikasi dan autentikasi diterima, runtime tunnel iAP2 siap dan frame video dirender. iPhone masuk otomatis tanpa bantuan sandi manual pada percobaan ini.
- UI menampilkan CarPlay terhubung dan screenshot memperlihatkan launcher CarPlay nyata, bukan gambar simulasi. Pemilik mengonfirmasi sentuhan berfungsi. Setelah beberapa menit, pemeriksaan UI masih menunjukkan tersambung. Tidak mengklaim seluruh perangkat/kanal 5 GHz gagal atau menganggap satu percobaan ini sebagai uji stabilitas jangka panjang.
- Saat terhubung, mobile_data=0 dan Active default network: none pada Android. Guard offline tetap berjalan. Ini pemeriksaan status OS, bukan audit paket WAN.
- Pemilik melaporkan audio tetap keluar dari iPhone. Log belum memperlihatkan setup format audio atau playback pada receiver. Pertanyaan pemilihan keluaran audio/AirPlay iPhone dan percobaan memulai musik dari CarPlay masih menunggu hasil. Jangan menyatakan audio, Siri/mikrofon, panggilan atau output T-Link telah lulus.
- 79 tes Flutter lulus dan analyze bersih pada perubahan UI/event sebelumnya. Perubahan kanal memakai konstanta core yang sudah ada; 20 tes native lulus dan release arm64 non-debuggable berhasil 2 menit 51 detik. Untuk build bring-up ini dipakai -Pshrink=false; optimasi R8/resources dinonaktifkan pada perintah build lokal, bukan konfigurasi proyek permanen. Signature terverifikasi dan install -r mempertahankan data.
- Kedua aset autentikasi dalam APK cocok dengan input terverifikasi. APK 26259083 byte; SHA-256 `72a49b1f6e144426eddd30d137da524e91eb7160f13258f88a9ede7028c3f3c7`. Versi terpasang 0.6.2/code 23. APK tetap untuk uji pribadi; tidak dipublikasikan. Band 2,4 GHz dipertahankan sebagai jalur yang sudah menghasilkan gambar pada pasangan perangkat ini; 5 GHz perlu pengujian tersendiri.

### Diagnosis audio 0.6.3+24 dan 0.6.4+25

- Pemilik menguji Spotify/Apple Music: pada 0.6.2 dan 0.6.3 suara tetap keluar dari iPhone, tanpa DashTConnect pada pilihan keluaran. Mengaktifkan tawaran buffered AAC pada 0.6.3 menaikkan audioFormats dari 9 menjadi 10, tetapi belum menghasilkan permintaan setup audio atau playback. Dua tes native memeriksa penawaran format buffered, negosiasi fitur dan penghormatan disableAudioOutput; 22 tes native lulus.
- Diagnostik menunjukkan alamat Bluetooth perangkat tidak tersedia lewat API app. Pada 0.6.4, build lokal menerima alamat Samsung dari ADB melalui environment DASHTCONNECT_BLUETOOTH_ADDRESS, tanpa mencetak atau menaruh nilainya di source. API perangkat tetap menjadi sumber pertama. Parser menolak alamat kosong, salah format, masked, zero dan broadcast; Wi-Fi deviceId juga menolak alamat placeholder. Ini hipotesis kecocokan identitas, bukan akar masalah audio yang sudah terbukti.
- Validasi Gradle menolak environment yang salah format. Sebanyak 23 tes native lulus tanpa kegagalan/error, assembleRelease berhasil 2 menit 14 detik, signature terverifikasi dan install -r berhasil. Build ini memakai -Pshrink=false seperti percobaan sebelumnya. Paket khusus Samsung ini bukan build untuk publikasi atau HP lain.
- Pada Samsung, log mengonfirmasi hardwareBluetoothAvailable=true dan jaringan lokal 2462 MHz. UI kembali menunjukkan CarPlay terhubung; /info menawarkan 10 format audio. Saat pemeriksaan awal belum ada setup/playback audio; hasil dengar 0.6.4 masih menunggu pemilik. Gambar yang berhasil tidak membuktikan audio, mikrofon/Siri, panggilan atau output T-Link.

### Masukan audio receiver 0.6.5+26

- Pemilik mengonfirmasi 0.6.4 masih memutar suara di iPhone dan tidak menawarkan DashTConnect sebagai keluaran. Penyamaan identitas Bluetooth belum menyelesaikan masalah.
- Laporan upstream https://github.com/shihabal3amri/DiPlay/issues/288 mencatat gejala serupa ketika receiver tidak menawarkan masukan mikrofon. Ini petunjuk untuk pengujian, bukan bukti akar masalah pada Samsung. Host sebelumnya memasang microphone=false pada penawaran dan mesin media.
- Host kini meminta RECORD_AUDIO bersama izin receiver, menjelaskan penggunaannya di halaman persiapan dan memblokir mulai bila izin belum tersedia, termasuk pemeriksaan di modul receiver. Penawaran masukan dan CarPlayMediaEngine diaktifkan bersamaan; AndroidMediaSink yang sudah ada menangani capture/uplink saat diminta iPhone. Tidak menambahkan rekaman ke file atau capture di luar sesi; stop/teardown tetap menutup uplink dan app berhenti saat paused.
- Tes penawaran memeriksa format masukan default, telephony dan speechRecognition, serta memastikan media tidak menawarkan masukan. Lima tes halaman receiver lulus, termasuk aksi izin, pemblokiran mulai dan reflow teks besar; flutter analyze bersih. Hasil build, permintaan izin fisik dan audio dicatat setelah pengujian perangkat.
- Sebanyak 24 tes native lulus tanpa kegagalan/error. Release arm64 berhasil 2 menit 13 detik; signature valid, dua assets autentikasi cocok dengan input dan install -r mempertahankan data. Halaman receiver di Samsung menampilkan penjelasan mikrofon dan tombol Berikan izin receiver; tombol ditekan untuk membuka dialog sistem. Menunggu pemilik memberikan izin sebelum menyambungkan dan menguji audio kembali.
- Pemilik memberikan izin mikrofon melalui dialog Android. Percobaan baru mengonfirmasi microphone=true, identifikasi/autentikasi diterima dan UI CarPlay terhubung. Untuk pertama kalinya pada rangkaian ini iPhone meminta stream audio type=100, audioType=telephony, codec=OPUS, rate=48000, channels=1; receiver mencatat audio playback started. Ini bukti negosiasi/pemutaran native mulai bekerja, bukan konfirmasi suara musik terdengar. Hasil Spotify/Apple Music masih menunggu pemilik; tidak memulai panggilan atau mengakses pesan untuk pengujian.
- Uji musik berikutnya menghasilkan type=102, audioType=media, codec=AAC_LC, rate=48000, channels=2 dan audio playback started. Pemilik menjawab “Sudah keluar dari Samsung”. Gambar, sentuhan dan musik pada pasangan perangkat ini berhasil; tidak menggeneralisasi ke HP lain atau menganggap Siri/panggilan/output T-Link sudah lulus. APK 26259083 byte, SHA-256 `e7c19902a41f1442ebaa0fb6b540b60256312f0cb712711df80cc85ac7ad42e8`.

### Layar penuh dan pintasan redup 0.6.6+27

- Screenshot pemilik menunjukkan toolbar, status/navigation bar Android dan video 16:9 menyisakan ruang pada display Samsung yang lebih lebar. Penawaran display, decoder dan fit SurfaceView kini memakai dimensi yang sama, mengikuti rasio display landscape dengan lebar video tetap 1280 dan tinggi genap. Untuk display 1600×720, video menjadi 1280×576, tanpa crop atau stretch. Mode cutout sementara dipulihkan saat view ditutup.
- Pada fase connected, toolbar aplikasi hilang dan immersiveSticky menyembunyikan bilah sistem; bilah pulih saat sesi berhenti/gagal atau halaman ditutup. Surface tetap berada dalam tree yang sama. Panel kiri bawah berisi redup/pulihkan dan tombol kontrol yang membuka tindakan berhenti; target minimal 48 dp, ikon putih pada panel gelap untuk dua tema. Status kecerahan sinkron dengan Pengaturan. Snackbar kegagalan berada di atas panel agar retry tetap terjangkau.
- Sebanyak 79 tes Flutter lulus. Regresi receiver diperluas untuk pemutaran layar penuh 800×360 dengan inset nonzero, immersive/restore, redup/pulihkan, kegagalan kecerahan dan berhenti tanpa membuat ulang surface; lima tes halaman receiver lulus setelah perluasan tersebut. Sebanyak 26 tes native lulus, termasuk rasio display portrait/landscape, 16:9, tinggi genap dan penolakan dimensi kosong. Analyze akhir bersih. Pemeriksaan perangkat dilakukan setelah APK akhir dipasang.
- Hard gate: aksi, kegagalan/retry, ukuran target, kontras panel dan pemulihan UI diperiksa otomatis. Purpose gate: ruang layar untuk sesi CarPlay dan pintasan kecerahan diminta pemilik; tidak menambah panel informasi. Liveliness: ENERGY 1 / RHYTHM 2 / MOTION 1 mengikuti DESIGN.md, tanpa animasi tambahan pada video. Craftsmanship: dimensi dipakai konsisten pada penawaran/decoder/surface, pengaturan kecerahan digunakan ulang, serta auth/offline/audio tidak diubah. Uji fisik dan hasilnya dicatat berikutnya.
- Release akhir berhasil 45 detik setelah perbaikan lint, signature valid, assets autentikasi cocok dan install -r berhasil. APK 26259083 byte, SHA-256 `b5589d5ad4ee701badab4d1569d0721f7775f843fa4b73e01b0d575f9acf4833`. Paket masih build uji pribadi dengan provisioning Samsung dan -Pshrink=false.
- Samsung tersambung kembali ke iPhone. Screenshot lokal carplay-fullscreen-066.png ditinjau: gambar CarPlay mengisi display 1600×720 tanpa toolbar atau strip status/navigation Android. Panel kiri bawah tetap di atas video. Tombol Redupkan layar HP berhasil berubah ke Pulihkan kecerahan HP; tombol pulihkan ditekan kembali sehingga sesi ditinggalkan pada kecerahan normal. Kontrol sesi dibuka, tindakan Hentikan receiver tersedia, lalu panel diciutkan kembali. Tidak menghentikan sesi fisik tambahan untuk pengujian; stop/restore diuji otomatis. Sentuhan dan musik pada layout baru serta T-Link masih memerlukan konfirmasi pemilik.

### Tombol sesi bulat 0.6.7+28

- Panel persegi diganti tombol bulat 56 dp seperti referensi pemilik. Idle tetap terlihat pada opacity 55%; saat disentuh menjadi 100% dan membuka kontrol bulat redup/berhenti. Tiap interaksi mengulang timer tiga detik; idle menutup kontrol tambahan dan mengembalikan opacity melalui fade 180 ms. Semantik, tooltip, kecerahan tersinkron dan fullscreen tetap memakai alur sebelumnya.
- ReceiverControls memiliki timer lokal yang dibatalkan saat dispose, tanpa polling atau rebuild berkala pada video. Pengurangan animasi meniadakan transisi. AccessibleNavigation mempertahankan pilihan tambahan agar dapat dibaca, tetapi tetap memudarkan opacity; fokus keyboard tradisional mempertahankan kontrol aktif. Pemeriksaan Samsung menunjukkan accessibility_enabled=1 dan touch_exploration_enabled=0, sehingga aksesibilitas global tidak dipakai untuk mematikan pemudaran sepenuhnya. Pengaturan aksesibilitas perangkat tidak diubah.
- Tujuh tes terkait lulus: aktivasi, pengulangan timer setelah sentuhan, idle yang tetap terlihat, buka ulang, aksi redup/berhenti, dispose saat timer aktif, navigasi aksesibel, penanganan kegagalan kecerahan dan surface yang tetap dipertahankan. Analyze akhir bersih. Build dan pemeriksaan visual perangkat dicatat setelah pemasangan.
- Release akhir berhasil 40 detik, signature valid dan install -r berhasil tanpa reset. Assets autentikasi cocok dengan input. APK 26259083 byte, SHA-256 `9fc8f0f336dd30dcb71e900f85ac0289d6cfda2f5821b20de72b513de719a41a`.
- CarPlay tersambung kembali di Samsung. Screenshot final active/idle diambil dengan screencap langsung setelah tap dan setelah 3,5 detik, tanpa dump UIAutomator di antaranya. Kedua gambar ditinjau: tombol bulat pekat saat aktif dan transparan saat idle, tetap terlihat di atas launcher CarPlay. Karena accessibleNavigation aktif di perangkat, tombol tambahan tetap tersedia saat idle; tombol utama ditekan kembali untuk meninggalkan satu tombol bulat. Sesi tidak dihentikan dan kecerahan tidak diubah pada pemeriksaan akhir.
- Hard gate PASS untuk aksi, timer/dispose, ukuran 56 dp dan kontras ikon idle: minimal 3,61:1 pada pengujian komposit di atas 256 latar grayscale. Purpose gate PASS: bentuk, opasitas dan waktu idle sesuai permintaan pemilik. Liveliness PASS: ENERGY 1 / RHYTHM 2 / MOTION 1, transisi singkat hanya setelah interaksi. Craftsmanship PASS: widget kontrol memiliki timer sendiri, tidak menambah dependency, serta jalur auth/audio/video tetap dipertahankan. Tampilan T-Link pada head unit belum diperiksa untuk perubahan ini.

### Penutupan menu idle 0.6.8+29

- Pemilik meminta menu benar-benar menutup setelah tiga detik dan tombol tersisa lebih transparan. Pengecualian accessibleNavigation/fokus keyboard yang mempertahankan menu dihapus; tiap sentuhan atau perubahan fokus tetap mengulang timer. Idle selalu menyisakan tombol utama dengan opacity 30%, aktif 100%, transisi 180 ms atau nol bila pengurangan animasi aktif.
- Tujuh tes terkait lulus dan analyze bersih. Regresi yang sebelumnya mempertahankan tombol tambahan pada accessibleNavigation=true kini memastikan redup/berhenti hilang dan Kontrol sesi tetap tersedia pada opacity 30%. Aksi, pengulangan timer dan dispose tetap lulus.
- Arah ENERGY 1 / RHYTHM 2 / MOTION 1 dan target 56 dp dipertahankan. Pengurangan kontras idle mengikuti permintaan eksplisit pemilik agar tidak mengganggu gambar; keadaan aktif tetap memakai panel gelap/ikon putih penuh. Tidak mengklaim kontras idle 0.6.7 berlaku pada opacity yang baru. Tidak ada perubahan mesin media atau dependency.
- Release berhasil satu menit, signature valid dan install -r berhasil. Dua assets autentikasi cocok dengan input. APK 26259083 byte, SHA-256 `4f0c128107fa457c51679b2c99a71993bc7b1b69bdaf43c3b2f1a3f139735b84`.
- CarPlay tersambung kembali di Samsung. Screenshot idle-close-active-068.png dan idle-close-idle-068.png diambil setelah membuka kontrol dan setelah 3,5 detik tanpa interaksi, lalu ditinjau. Menu redup/berhenti menutup otomatis, hanya tombol utama yang tersisa pada opacity lebih rendah di atas peta. Koneksi tetap berjalan; tidak mengubah kecerahan atau memulai navigasi untuk pengujian. Hasil visual ini diuji di Samsung, bukan head unit T-Link.

### Tombol yang dapat dipindah 0.6.9+30

- Pemilik meminta tombol dapat dipindahkan agar tidak menutupi Google Maps dan kembali setelah sepuluh detik. Tombol utama menerima pan gesture, menutup menu saat drag dimulai, membatasi anchor dalam viewport dengan inset 12 dp dan membuka menu ke arah dalam pada tepi kanan. Posisi sementara tidak disimpan ke data pengguna.
- Timer kembali sepuluh detik diulang tiap interaksi dan dimulai dari pelepasan drag; timer tidak berjalan selama drag. Kembali ke posisi kiri bawah memakai 220 ms, dilewati saat pengurangan animasi aktif. Idle tiga detik tetap menutup menu dan memudarkan tombol ke 30%. Kedua timer dibatalkan saat dispose. LayoutBuilder/Stack kontrol tidak menangkap sentuhan pada area kosong.
- Sepuluh tes terkait lulus, termasuk drag tanpa tap menu, clamp tepi, menu kanan membuka ke dalam tanpa memindahkan anchor, timer kembali yang diulang setelah klik, dispose dua timer, serta sentuhan yang diteruskan ke konten. Regresi fullscreen, redup dan stop tetap lulus. Analyze bersih sebelum build.
- Release berhasil 59 detik, signature valid dan install -r mempertahankan data. Assets autentikasi cocok dengan input. APK 26259083 byte, SHA-256 `39b0f9e26c1936acaa32017466d31994d221caeaf9239abd71d396e07329d07d`.
- Samsung kembali tersambung ke CarPlay. Tombol digeser dari kiri bawah ke tengah-kiri; tiga screenshot lokal ditinjau: setelah drag, sesudah idle 3,5 detik, dan setelah total lebih dari sepuluh detik. Tombol berpindah tanpa membuka menu, memudar di posisi baru, lalu kembali sendiri ke kiri bawah. CarPlay tetap menampilkan sesi yang sama dan kecerahan tidak diubah.
- Pemeriksaan dalam cakupan perubahan lulus: posisi dan arah menu tetap dalam layar, area kosong meneruskan input, aksi/failure/dispose tetap teruji. Motif bulat, target 56 dp dan opacity idle pilihan pemilik dipertahankan. Gerak 220 ms hanya untuk kembali ke posisi awal; tidak ada animasi berulang atau perubahan engine. Pemeriksaan fisik dilakukan pada Samsung, belum melalui head unit T-Link.

### Penjadwalan video dan cadangan musik 0.6.10+31

- Pemilik menguji langsung di Samsung: sesekali scroll tersendat dan musik putus, bukan hasil T-Link. Pada percobaan berikutnya pemilik menyatakan lebih lancar namun masih sedikit lag, sebelum perubahan kode apa pun pada tahap ini. Karena kondisi bervariasi, tidak menganggap perbaikan subjektif awal sebagai hasil optimasi.
- Baseline hardware decoder OMX.Exynos.avc.dec, 1280×576/30 fps; decode p50 sekitar 6–12 ms dan p90 8–21 ms pada sampel awal. Receive/decrypt bukan antrean decode yang panjang: contoh video processMaxUs=1816, decryptAvgUs=456, tetapi jeda receive dapat ratusan milidetik. Layar diam juga menghasilkan frame sedikit; rx fps rendah saat idle bukan bukti lag.
- Musik memakai type=102/AAC-LC 48 kHz stereo. Sampel audio menunjukkan maxGapMs sekitar 390–618, underrun bertambah dan rebuffer mencapai 14 pada snapshot; ada contoh receive kehilangan enam paket. Tidak ada decoder input drop/write error pada sampel tersebut. Log yang disimpan hanya statistik numerik, tanpa payload, sandi, nama lagu atau rute peta.
- Host memakai MediaAudioBuffer.MOST_STABLE_MILLIS (1000 ms, sebelumnya default 300 ms) untuk musik; buffer panggilan/prompt tidak diperbesar. SurfaceView mengaktifkan penjadwalan frame bawaan dengan delay awal 140 ms dan adaptasi bounded 30–200 ms. Dimensi, 30 fps, decoder hardware, band 2,4 GHz yang sudah berhasil, sentuhan dan guard offline tetap. Tidak menambahkan dependency atau menaikkan fps secara spekulatif.
- Kompromi: awal musik dapat lebih lambat dan pacing menambah keterlambatan gambar. Cadangan bukan pemulihan paket UDP yang hilang dan tidak menjamin bebas lag. Dua tes native memeriksa cadangan yang melampaui jeda 620 ms tanpa mengubah buffer voice, serta timestamp video yang tetap berjarak saat frame datang bergerombol dan batas delay adaptif.
- Sebanyak 28 tes native lulus tanpa kegagalan/error; release berhasil 1 menit 38 detik, signature valid dan install -r berhasil. Auth assets cocok dengan input. APK 26259083 byte, SHA-256 `2bcfb69bac99716c60d3226196745526c94cad85e4f7c5d38b0974c3ee904b60`. Paket tetap uji pribadi, provisioning Samsung dan -Pshrink=false.
- CarPlay tersambung kembali di Samsung. Pemilik diminta membandingkan musik dan scroll sekitar satu menit pada versi baru. Belum menyatakan perbaikan terukur atau bebas lag sebelum sampel dan konfirmasi hasil tersebut.
- Sampel setelah pemasangan: 12 jendela statistik musik dengan rentang timestamp 55,0 detik, underruns=0 dan rebuffers=0, walaupun maxGapMs mencapai 548. Kapasitas track 57600 frame pada 48 kHz (1200 ms) sesuai cadangan start 1000 ms ditambah headroom. Baseline sebelumnya mencapai rebuffer 14 pada snapshot. Kedua sampel berbeda kondisi/waktu dan bukan benchmark terkontrol atau jaminan jangka panjang.
- Pacing aktif dengan delay adaptif yang terlihat pada log. Satu jendela gerak menunjukkan rx=29,4 fps/shown=29,2 fps, decode p90=18 ms; jendela lain tetap memiliki jeda receive dan frame terlambat, delay naik hingga 200 ms. Tidak menyebut seluruh scroll bebas lag atau menganggap touch2frame pada layar diam sebagai pengukuran respons yang valid. Penilaian subjektif pemilik pada versi baru masih menunggu.

### Perbandingan radio 0.6.11+32

- Pemilik menyatakan 0.6.10 terasa masih sama. Sampel lanjutan berisi 48 jendela audio, satu underrun/rebuffer dan 148 paket audio hilang pada receive type=102. Pacing mencapai sekitar 167–200 ms pada beberapa jendela. Hasil ini tidak mendukung klaim bahwa buffer/pacing saja menyelesaikan gejala.
- Pacing tambahan dilepas untuk mengembalikan respons gambar langsung. Cadangan musik satu detik dipertahankan karena starvation berkurang pada sampel, tanpa mengklaim kondisi pengujian identik atau perbaikan subjektif sudah diterima.
- Uji berikut meminta AUTO_5_GHZ pada Wi-Fi Direct dengan autentikasi/identitas receiver yang sekarang sudah tersambung. Uji 5 GHz terdahulu pada tahap bootstrap awal pernah gagal, jadi kompatibilitas belum diasumsikan. Paket bekerja 0.6.10 disalin ke QA lokal untuk pemulihan; jika 5 GHz gagal, source akan dikembalikan ke jalur 2,4 GHz dan paket diperbarui. Tidak mengubah pengaturan radio sistem secara global, pairing iPhone atau akses internet Android.
- Pemilik kemudian menyatakan CarPlay tersambung sendiri. Log lokal mengonfirmasi frekuensi 5 GHz pada percobaan tersebut. Dampak terhadap lag musik/scroll belum dikonfirmasi; tidak menyatakan optimasi sudah menyelesaikan gejala.

### Landscape dan receiver 0.7.0+33

- Kontrol sesi menempel ke tepi horizontal terdekat setelah drag, bertransisi 220 ms dan tetap kembali ke kiri bawah setelah sepuluh detik idle. Tes mencakup docking kiri/kanan, batas layar, arah menu, idle tiga detik, reset timer dan penerusan sentuhan area kosong.
- Panel dua kolom memakai tinggi minimum yang sama berdasarkan layout isi, dengan tinggi tetap tidak dibatasi. Regresi khusus membuka/menutup ExpansionTile memeriksa tinggi kedua panel sama, tumbuh dan kembali ke tinggi semula tanpa overflow. Pengukuran intrinsik tidak dipakai karena ListTile/ExpansionTile dapat melaporkan tinggi berbeda dari hasil layout.
- Rail landscape dipadatkan, Panduan menempatkan aksi koneksi di kanan alur tutorial dan bantuan selebar konten di bawahnya. Persiapan receiver memakai pilihan iPhone berbentuk kartu radio; proses koneksi menempatkan status dan petunjuk di dua panel. Guard autentikasi, izin, offline, pemilihan perangkat dan kerahasiaan sandi tetap diuji.
- Seluruh 85 tes Flutter awal lulus setelah perbaikan layout. Setelah menambahkan regresi panel dinamis, 17 tes responsive lulus dan analyze bersih. Cakupan mencakup portrait, landscape pendek, terang/gelap, teks 100–200%, keyboard dan penyimpanan tema. Sebanyak 29 tes native lulus tanpa kegagalan/error.
- SSID menggunakan merek dari Build.MANUFACTURER, dengan awalan wajib Android `DIRECT-xy-`, sanitasi ASCII dan batas 32 byte. Nama generik bermerek tidak dianggap milik aplikasi; reclaim tetap memerlukan catatan nama jaringan persis atau namespace lama yang sah. Kanal AUTO_5_GHZ dan buffer musik satu detik dipertahankan.
- Build release berhasil 2 menit 35 detik; signature valid dan install -r berhasil. Samsung melaporkan versionName 0.7.0/versionCode 33. Kedua aset autentikasi di APK cocok dengan input lokal. Ukuran APK 25931403 byte, SHA-256 `a4593f54cad23a534c7909a5f3b836f32e64277694ad528dd96ecb7ebb5331fc`. Ini tetap paket uji pribadi dengan provisioning Bluetooth Samsung, penandatangan lokal dan -Pshrink=false.
- Render widget 800×360 dengan font aplikasi dan MaterialIcons ditinjau untuk Beranda, Panduan, Pengaturan, persiapan receiver serta proses menghubungkan. Panel sejajar, pilihan iPhone dan tombol terlihat dengan scroll yang tersedia, rail mengikuti tinggi tujuan. Data receiver pada render ini adalah fixture, bukan bukti sesi CarPlay tersambung. Pemeriksaan fisik docking dan SSID baru masih menunggu aplikasi dibuka oleh pemilik; tidak mengambil alih aplikasi lain yang sedang di depan dan tidak mengklaim hasil T-Link atau perbaikan lag.
- Setelah pemilik membuka aplikasi, screenshot fisik Samsung diperiksa untuk Beranda, Panduan, Pengaturan, kartu iPhone yang dipilih dan layar proses koneksi. Layout landscape tampil tanpa overflow yang terlihat; rail ringkas dan kedua panel proses sejajar. Jaringan bermerek Samsung benar-benar teramati pada grup Wi-Fi Direct, dengan frekuensi receiver 5200 MHz. Saat pencatatan ini sesi masih menunggu iPhone masuk Wi-Fi; docking fisik belum diuji dan hasil T-Link/performa belum diklaim.

### Uji visibilitas jaringan 0.7.1+34

- Pemilik menyatakan iPhone tidak melihat jaringan Samsung baru. Log 0.7.0 menunjukkan identification/authentication accepted dan konfigurasi Wi-Fi terkirim, tetapi belum ada sesi gambar. Grup 5200 MHz yang terbentuk di Samsung bukan bukti beacon terlihat di iPhone.
- Uji berikut mengganti preferensi band ke AUTO_2_4_GHZ. Nama merek, UI 0.7.0, buffer musik satu detik, output video langsung, identitas dan guard offline tetap. Tujuannya membandingkan visibilitas radio; penyebab belum dipastikan dan perbaikan koneksi/lag belum diklaim sebelum percobaan fisik.
- Build 0.7.1 berhasil 1 menit 36 detik, 29 tes native tetap lulus, signature valid dan install -r berhasil. Aset autentikasi cocok dengan input lokal. APK 25931403 byte, SHA-256 `6f9f17a469d345b39b689a7fab82ed5e3d1ad1b1faa958902af6718b197e22b7`.
- Sesi baru memakai 2462 MHz dan autentikasi diterima. CarPlay terlihat pada screenshot fisik Samsung; pemilik juga mengonfirmasi “CarPlay sudah tampil”. Hasil satu perbandingan ini belum menetapkan penyebab pasti kegagalan percobaan 5 GHz sebelumnya.
- Kontrol digeser ke tengah-kanan lalu ke tengah-kiri. Screenshot setelah pelepasan mengonfirmasi tombol menempel ke tepi horizontal masing-masing, tidak membuka menu atau mengubah halaman CarPlay. Idle 3,5 detik memudarkan tombol; screenshot lebih dari sepuluh detik mengonfirmasi kembali ke kiri bawah. Menu yang dibuka di sisi kiri menutup sendiri dan memudar sesudah 3,5 detik. Sesi CarPlay tetap tampil. Gerak transisi dibuktikan oleh tes widget dan perpindahan posisi fisik, tanpa mengklaim pengukuran frame pacing animasi.
- Pemeriksaan fisik dilakukan langsung di Samsung. Musik, scroll berkepanjangan, mikrofon dan proyeksi T-Link tidak diuji ulang pada 0.7.1; tidak menyatakan lag sudah hilang.

### Teks aplikasi 0.7.2+35

- Atas permintaan pemilik, hapus label eksperimen dan peringatan tahap uji dari Tentang aplikasi, bagian receiver, panduan serta pesan format catatan. Hapus juga kalimat umum yang meminta membuktikan kompatibilitas dan peringatan build/fitur yang tidak membantu langkah koneksi pada bantuan. Tidak menambahkan klaim semua perangkat atau seluruh kanal sudah lulus.
- Peringatan izin, autentikasi tidak tersedia pada runtime, Bluetooth mati, Android terhubung internet, kegagalan koneksi dan pengingat parkir dipertahankan. Keterangan Uji tampilan tetap menjelaskan fungsi penghitung gambar/sentuh; penghapusan label tidak mengubah semantik tes tersebut. Status hasil lama dan format penyimpanan catatan dipertahankan.
- Pencarian ulang pada presentation dan pesan codec tidak menemukan label eksperimen, tahap uji atau kalimat perlu diuji/dibuktikan. Sebanyak 37 tes halaman/panduan/receiver/responsive lulus setelah assertion copy lama diperbarui. Analyze bersih. Kode protokol, 2,4 GHz, media, izin, validasi dan aset autentikasi tidak diubah; notice/provenance sumber tetap dipertahankan.
- Build final berhasil 39 detik, signature valid dan install -r berhasil. Samsung menampilkan 0.7.2+35; halaman Tentang diperiksa lewat UIAutomator dan screenshot fisik tanpa kartu peringatan lama. Aset autentikasi di APK cocok dengan input lokal. APK 25931403 byte, SHA-256 `b3add1f65117be7044d81d4e0a5db8f6092b16e99e025a3a388efc9d0a3e41c1`. Sesi CarPlay/T-Link tidak diuji ulang setelah pembaruan teks ini.

### Tentang aplikasi 0.7.3+36

- Identitas memakai logo 48 dp, nama/versi lebih ringkas dan satu deskripsi. Diagram koneksi serta tiga ringkasan fitur berikon menggantikan paragraf panjang yang menyisakan ruang kosong. Memakai AppPanel, ConnectionRoute, IconTile dan AdaptiveColumns yang sudah ada, tanpa dependency atau aksi semu.
- Analyze bersih; 27 tes app/responsive lulus, termasuk halaman Tentang pada landscape pendek, terang/gelap dan teks hingga 200%. Render widget portrait/landscape juga ditinjau. Build final berhasil 1 menit 7 detik; teks fitur terbaru diverifikasi pada libapp.so sebelum penandatanganan. Signature valid, install -r berhasil dan aset autentikasi cocok dengan input lokal.
- Screenshot fisik Samsung portrait memperlihatkan identitas, alur dan ketiga fitur tanpa area kosong besar di bawahnya. Landscape menyusun panel alur/fitur sama tinggi dengan scroll untuk header. Tidak ditemukan overflow yang terlihat. APK 25931403 byte, SHA-256 `32c484fbb85d28b9638b6edf5c19f765fd861a59405f68292c70ec33875314b5`. Perubahan hanya halaman informasi; sesi CarPlay/T-Link tidak diuji ulang.



## 2026-10-27 — Receiver dengan internet Android aktif (0.7.4+37)

- Permintaan terbaru menggantikan syarat Android offline. `internetAvailable` tetap informasi, tetapi tidak lagi memblokir tombol, native start, persiapan Wi-Fi Direct, atau iAP2 StartSession. Callback penghenti sesi ketika jaringan INTERNET muncul dihapus.
- Listener RTSP dan mDNS tetap memakai alamat/interface grup P2P; aplikasi tidak memutus Wi-Fi, mematikan data seluler, atau mengganti default network. Autentikasi, izin, Bluetooth, pilihan perangkat dan validasi grup P2P tetap diperlukan.
- Panduan dan pesan pada halaman receiver diperbarui. Jalur pembuatan grup 2,4 GHz dan pemilihan kanal station yang sudah ada dipertahankan.
- PASS: `flutter analyze`, 86 tes Flutter, 29 tes JVM receiver. Regresi memeriksa bahwa internet aktif tidak memblokir canStart/start, sedangkan autentikasi/izin tetap memblokir bila belum siap.
- PASS: build APK debug arm64, kedua aset autentikasi cocok dengan file lokal, install -r pada Samsung SM-A047F, versi 0.7.4+37. Data research.json tetap sama setelah pembaruan.
- Perangkat: Wi-Fi berinternet tervalidasi sebelum dan sesudah pemasangan. Halaman persiapan tidak menampilkan blokir internet. Pengujian sampai video/audio belum selesai karena daftar perangkat Bluetooth tidak memuat iPhone yang dipasangkan. Pengguna diminta memasangkan kembali untuk pengujian fisik; tidak menganggap prasyarat lolos sebagai bukti sesi CarPlay aktif.
- Belum diuji: Wi-Fi STA + P2P sampai sesi video/audio bersama iPhone dan head unit T-Link. Dukungan bersamaan mengikuti firmware/hardware Android.


## 2026-10-27 — Persiapan dan koneksi otomatis (0.7.5+38)

- `prepareConnection` menyiapkan izin, Bluetooth lewat ACTION_REQUEST_ENABLE, Wi-Fi lewat panel sistem, serta membuka Settings Bluetooth jika pairing pertama diperlukan. Pembatalan tidak memicu loop permintaan. Dialog harus disetujui pengguna sesuai pembatasan Android.
- Dari Beranda → Mulai receiver, iPhone terakhir yang berhasil dipilih jika masih dipasangkan; jika tidak ada riwayat, hanya satu kandidat ponsel boleh dipilih otomatis. Banyak kandidat memerlukan pilihan pengguna. Perangkat non-phone tidak dipilih sembarang, dan tidak memakai RSSI untuk menebak iPhone terdekat.
- Riwayat ditulis hanya setelah runtime iAP2 + frame pertama memicu connected. Setup yang masih menunggu panel tidak memulai sesi ketika background/dispose. SurfaceView mengirim surface_lost/surface_ready agar start tidak mendahului kembalinya layar setelah Settings.
- PASS: 96 tes Flutter, termasuk pemilihan kandidat, Wi-Fi/internet, parser hasil setup, pembatalan tanpa loop, beberapa perangkat, penutupan halaman, background/resume, dan surface yang hilang/kembali. `flutter analyze`: tidak ada masalah. Build APK debug arm64 berhasil.
- PASS perangkat fisik: APK 0.7.5+38 dipasang ke Samsung SM-A047F, file autentikasi cocok dengan sumber lokal dan research.json tidak berubah. Saat Mulai receiver ditekan, Android menampilkan permintaan mengaktifkan Bluetooth. Setelah Bolehkan disetujui, iPhone terhubung otomatis dan grid CarPlay tampil tanpa menekan Hubungkan atau memilih perangkat secara manual.
- PASS jaringan fisik: bagian Current Networks dari dumpsys connectivity masih memuat Wi-Fi INTERNET + VALIDATED saat CarPlay berstatus terhubung. Private preference last_phone tersimpan dalam format alamat valid. Bukti screenshot lokal: `.local-tools/qa/auto-receiver-connected.png` (tidak dipublikasikan).
- Batas pengujian: panel Wi-Fi dari keadaan mati belum dicoba secara fisik agar koneksi Wi-Fi berinternet saat pengujian tetap utuh; pembatalan/readiness diuji otomatis. Audio, head unit T-Link dan kestabilan jangka panjang belum diuji ulang pada versi ini. Tidak ada janji semua perangkat mendukung Wi-Fi station + P2P bersamaan.


## 2026-10-27 — Respons kontrol receiver (0.7.6+39)

- Pengiriman sentuhan memakai worker langsung, menggantikan polling 16 ms dengan satu slot yang dapat menimpa tekan/lepas. Gerakan digabung saat tertahan; transisi pointer tetap berurutan. Batas 64 paket mereset gestur yang tertinggal agar tidak memainkan antrean input lama. Tidak ada operasi socket di thread UI.
- Penawaran video utama dan operating rate decoder dinaikkan dari 30 ke 60 fps pada resolusi yang sama. Buffer musik tidak dikurangi. WifiLock LOW_LATENCY diminta selama sesi (HIGH_PERF untuk API di bawah 29); WAKE_LOCK adalah permission normal. Lock dibersihkan bersama resource sesi, termasuk saat startup gagal.
- PASS: 33 tes JVM receiver, termasuk empat regresi untuk tap cepat, penggabungan gerakan, pergantian pointer, antrean tertahan dan shutdown. Build APK arm64 berhasil. APK 0.7.6+39 dipasang dengan install -r; aset autentikasi diverifikasi dan research.json tetap sama. Flutter tidak diubah selain nomor versi, sehingga suite Flutter tidak dijalankan ulang untuk perubahan ini.
- Sampel awal 0.7.5: swipe grid CarPlay memakai input swipe 400 ms, jeda 350 ms. Tiga jendela mencatat 17,4 / 25,6 / 10,6 fps tampil; touch2frame rata-rata 75 / 60 / 81 ms, decoder p90 13–14 ms, max arrival gap 297–334 ms. Peningkatan 60 fps dan dispatcher saja belum menunjukkan perbaikan berarti (21,4–25,6 fps pada jendela aktif, touch2frame 65–78 ms).
- PASS perangkat fisik dengan lock: dumpsys wifi memuat WifiLock DashTConnect:receiver type=4 selama sesi; CarPlay connected dan Wi-Fi INTERNET + VALIDATED bersamaan. Setelah keluar, lock hilang setelah cleanup sesi asinkron. Receiver dibuka kembali untuk pemakaian pengguna.
- Pengulangan 18 swipe setelah lock: empat jendela mencatat 32,4 / 54,7 / 54,1 / 36,6 fps tampil, touch2frame rata-rata 38 / 34 / 25 / 38 ms, decoder p90 9–11 ms, tanpa recovery decoder. Max gap masih 160–290 ms. Bukti lokal: .local-tools/qa/smooth-wifi-repeat.log; bukan aset publik.
- Batas: touch2frame mengukur kirim HID ke frame diterima berikutnya, bukan latensi sentuhan sampai piksel yang terbukti terkait. Jendela memuat jeda antar-swipe, bukan benchmark fps kontinu. Sampel sebelum/sesudah diambil pada waktu berbeda sehingga tidak mengisolasi perubahan kondisi radio. Audio, head unit T-Link, suhu/daya dan sesi panjang belum diuji ulang. Tidak menyatakan bebas lag atau 60 fps stabil.
