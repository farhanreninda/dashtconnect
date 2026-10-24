# PRD — DashTConnect

- **Versi:** 0.4.0
- **Tanggal:** 22 Oktober 2026
- **Status:** Pengembangan aplikasi pendamping; kelayakan receiver masih diuji
- **Repository:** https://github.com/farhanreninda/dashtconnect

## Keputusan tambahan pengguna

Pengguna memilih Flutter dan meminta UI modern yang mudah diakses, tema gelap, serta redup/mati layar HP agar pengujian proyeksi tidak memerlukan kecerahan penuh. Pilihan framework dalam PRD awal digantikan keputusan eksplisit ini.

Pengguna meminta tindakan koneksi menjadi fungsi utama, informasi teknis dipisahkan, dan tutorial bertahap pada pembukaan pertama yang dapat dibuka kembali. Versi 0.4.0+6 menambahkan Mulai receiver sambil mempertahankan Beranda, Panduan, Pengaturan, pengaturan Wi-Fi/Bluetooth dan uji layar. Inventaris, catatan pengujian dan laporan berada di Pengaturan.

Pengguna menegaskan aplikasi harus mandiri. DashTConnect ditargetkan menerima sesi iPhone sendiri lalu meneruskannya ke T-Link. Internet tetap dipakai di iPhone; Android tidak boleh mempunyai akses WAN selama sesi inti. Wi-Fi/Bluetooth lokal tetap boleh digunakan. Tombol, deteksi paket, teks dan pembuka receiver eksternal dikeluarkan; proyek pembanding hanya boleh menjadi referensi pengembangan.

Mesin receiver bawaan diintegrasikan sebagai library Android; seluruh tampilan tetap Flutter. Source protokol pihak ketiga memiliki lisensi, provenance dan folder tersendiri. Identitas autentikasi aksesori runtime belum tersedia, sehingga penerimaan CarPlay nyata belum diuji. Persiapan jaringan atau diterimanya perintah start tidak menjadi bukti sesi terhubung. Samsung A04s/SM-A047F memakai Android 14; foto HU dan inventaris ada di [inventaris](devices/toyota-raize-2022.md).

Pemilik meminta Clean Architecture, folder yang rapi dan pengeluaran file tidak terpakai. Versi aplikasi 0.2.1+2 memisahkan domain/data/presentation; schema catatan tetap 1. Probe iPhone/signing lama dikeluarkan dari repo. Rinciannya ada di [arsitektur](architecture.md).

Mode redup meminta kecerahan jendela 3%, menjaga konten gambar dan menahan layar aktif selama DashTConnect di depan. Keluar ke pengaturan Android atau aplikasi lain memulihkan kecerahan jendela ini; mode redup tidak mengendalikan jendela aplikasi lain. Kelanjutan proyeksi T-Link serta perubahan suhu harus diuji secara fisik. Fitur mematikan layar sepenuhnya ditunda sampai bukti menunjukkan sesi/display tetap berjalan. Tidak ada klaim mode redup pasti mengatasi panas.

## 1. Ringkasan

Arah lama yang mengasumsikan iPhone tersambung langsung ke T-Link bukan lagi target. DashTConnect sekarang meneliti alur **iPhone → HP Android sebagai receiver/relay → head unit Toyota Raize melalui T-Link atau jalur tampilan lokal yang terbukti kompatibel**.

Tujuan pengalaman akhir adalah Apple CarPlay nyata, koneksi yang mudah, dan sesi inti tetap berjalan tanpa akses internet/WAN pada Android. Ketiganya belum terbukti pada perangkat target. Aplikasi pendamping menyediakan tindakan yang dapat dijalankan sekarang, sedangkan eksperimen tetap menentukan kelayakan jalur inti.

## 2. Informasi perangkat

| Komponen | Informasi | Status |
|---|---|---|
| Mobil | Toyota Raize 1.0T G 2022 | Dari pemilik |
| Head unit | Unit bawaan 9 inci, T-Link; Application 1.1.0005.4400, M-Toyota 0.0.2 | Dua versi terbaca pada foto pemilik; model, OS/MCU dan versi T-Link belum diketahui |
| Android | Samsung A04s / SM-A047F, Android 14 (API 34), Exynos 850 | Model/OS/chipset dibaca dari perangkat; kemampuan transport masih perlu diuji |
| iPhone | iPhone 11 64 GB | Dari pemilik |
| iOS | 27.0, build 24A437 | Dibaca via USB pada riset sebelumnya; belum diuji ke HU |
| PC | Windows, tanpa Mac | Dari pemilik |

Jangan mengubah informasi yang belum diuji menjadi klaim fakta teknis.

## 3. Masalah dan tujuan

Masalah utama:
1. Jalur iPhone → Android → T-Link belum dibuktikan.
2. Solusi harus menerima sesi langsung di DashTConnect dengan internet tetap hanya di iPhone.
3. Pengguna ingin internet tetap berasal dari iPhone, tanpa ketergantungan WAN Android.
4. Setup awal boleh dilakukan manual, tetapi penggunaan berikutnya harus otomatis dan mudah.

Tujuan:
- Membuktikan apakah Android dapat menerima sesi CarPlay nyata dari iPhone.
- Membuktikan apakah output Android dapat ditampilkan dan dikontrol melalui T-Link.
- Mengisolasi koneksi lokal dari internet agar Android tetap tanpa WAN.
- Membuktikan sesi inti berjalan saat akses internet Android dimatikan.
- Menguji input, audio, reconnect dan stabilitas secara terpisah.
- Mengambil keputusan go/revise/stop berdasarkan bukti perangkat nyata.

## 4. Definisi keberhasilan

**CarPlay nyata:** sesi CarPlay dari iPhone benar-benar aktif dan UI berasal dari sesi tersebut. Screen mirroring biasa atau UI tiruan bukan pemenuhan target utama.

**Android offline:** Android tidak memiliki akses internet/WAN selama sesi inti. Koneksi lokal USB, Bluetooth, Wi-Fi Direct atau LAN boleh digunakan bila terbukti bekerja. Wi-Fi aktif tidak otomatis berarti internet aktif. Identifikasi kebutuhan internet pada instalasi, autentikasi, pairing, runtime, DNS, update, telemetry dan recovery.

**Seamless:** setelah setup pertama, perangkat dikenali otomatis, tidak perlu mengulang pairing/konfigurasi berulang, status koneksi jelas, retry terbatas, dan recovery mudah.

## 5. Ruang lingkup

### Termasuk
- Inventaris perangkat dan dokumentasi firmware.
- Pengembangan receiver bawaan dan pengujian sesi tanpa internet Android.
- Uji kemampuan T-Link menampilkan aplikasi Android dan mengembalikan input.
- Uji browser lokal di head unit bila tersedia.
- Pemetaan koneksi lokal vs internet.
- PoC minimal setelah arsitektur dan lisensi cukup jelas.
- Uji audio, sentuh, reconnect, sleep/wake dan stabilitas.
- Tindakan persiapan Wi-Fi/Bluetooth dan uji T-Link, tanpa pembuka receiver eksternal.
- Panduan empat langkah pada pembukaan pertama, dapat dilewati dan diulang; informasi teknis tersimpan di menu terpisah.

### Tidak termasuk
- Mengklaim kompatibilitas tanpa pengujian.
- UI tiruan CarPlay.
- Mengubah target menjadi mirroring biasa tanpa keputusan pengguna.
- Menambahkan cloud/backend tanpa alasan dan persetujuan.
- Memodifikasi firmware atau melakukan jailbreak sebagai solusi default.
- Menyalin credential, kunci, protokol atau kode proprietary tanpa dasar legal.
- Mengasumsikan Flutter menyediakan receiver/protokol perangkat tanpa komponen native dan bukti.

## 6. Kandidat arsitektur

### A — Android receiver + T-Link mirroring
iPhone mengirim sesi CarPlay ke Android; T-Link menampilkan layar Android. Uji apakah T-Link dapat menampilkan aplikasi target, mempertahankan orientasi, audio, dan mengirim input sentuh kembali. Jangan asumsikan kemampuan ini.

### B — Android relay + browser HU
Alternatif relay lokal dapat mengirim output melalui browser di layar mobil; ini hanya opsi cadangan bila jalur T-Link tidak dapat digunakan. Opsi ini hanya valid jika head unit punya browser yang dapat dibuka, mengakses endpoint lokal Android tanpa internet, dan mengembalikan input. Jika browser tidak tersedia atau T-Link memblokirnya, tandai gagal.

### C — Jalur lokal alternatif
Evaluasi USB, Wi-Fi Direct, Bluetooth-assisted pairing atau LAN hanya berdasarkan dokumentasi dan pengujian. USB file transfer/ADB/USB tethering tidak otomatis berarti transport CarPlay didukung.

**Aturan:** Flutter dipilih pengguna untuk aplikasi Android dan alat eksperimen. Pilihan ini tidak menetapkan mesin protokol. Integrasi USB, Wi-Fi, audio, layar dan input menunggu bukti serta audit lisensi. Implementasi proyek pembanding harus dinilai untuk perangkat target; nama atau pola UI tidak membuktikan kompatibilitas.

## 7. Kebutuhan fungsional

| ID | Prioritas | Kebutuhan | Kriteria penerimaan |
|---|---|---|---|
| FR-01 | P0 | Inventaris perangkat | Model/versi Android, HU/firmware, T-Link, iOS, kabel dan port tercatat. |
| FR-02 | P0 | iPhone → Android | Sesi CarPlay nyata terbukti diterima atau blocker terdokumentasi. |
| FR-03 | P0 | Android → HU | Output tampil melalui jalur yang teruji dan dapat diulang. |
| FR-04 | P0 | Offline Android | Sesi inti berjalan tanpa WAN Android; kondisi jaringan dicatat. |
| FR-05 | P0 | Audit internet | Semua ketergantungan online dipetakan berdasarkan tahap dan fungsi. |
| FR-06 | P0 | Input balik | Sentuhan HU mengontrol sesi bila didukung; batasan dicatat. |
| FR-07 | P1 | Audio | Musik, navigasi, Siri, panggilan dan mikrofon diuji masing-masing. |
| FR-08 | P1 | Pairing/reconnect | Setup tidak perlu diulang setiap kali. |
| FR-09 | P1 | Diagnosis | Status link jelas; log lokal, tanpa unggah otomatis. |
| FR-10 | P1 | Recovery | Putus kabel, Wi-Fi, background dan sleep/wake ditangani. |
| FR-11 | P2 | Pilihan koneksi | Hanya metode yang sudah dibuktikan ditawarkan. |
| FR-12 | P2 | Startup otomatis | Hanya bila diizinkan OS/perangkat dan terbukti stabil. |
| FR-13 | P1 | Tema dan akses | Tema sistem/terang/gelap tersimpan; navigasi terlihat; layar sempit dan teks besar diuji. |
| FR-14 | P1 | Redup layar HP | Kecerahan jendela turun tanpa overlay hitam, dapat dipulihkan, tidak mengubah kecerahan sistem. Kelanjutan proyeksi dan suhu diukur terpisah. |
| FR-15 | P2 | Layar sepenuhnya mati | Jangan tawarkan sebagai fungsi yang bekerja sebelum kelanjutan sesi dan output HU terbukti pada perangkat target. |
| FR-16 | P1 | Beranda tindakan | Beranda menyediakan Siapkan koneksi dan Uji tampilan. Wi-Fi/Bluetooth tersedia dari Panduan. Detail riset tidak memenuhi halaman ini. |
| FR-17 | P1 | Tutorial awal | Empat langkah muncul pada pembukaan pertama, dapat dilewati dan dibuka kembali dari Panduan. Selesai/lewati tersimpan; gagal simpan menampilkan retry tanpa menghapus data lama. |
| FR-18 | P1 | Informasi terpisah | Pengaturan mengumpulkan tema, redup, informasi perangkat, buku eksperimen dan laporan. Uji sentuh tersedia pada halaman layar penuh. |
| FR-19 | P0 | Aplikasi mandiri | Receiver harus menjadi bagian DashTConnect. Aplikasi tidak mencari atau membuka receiver lain; referensi teknis tidak menjadi ketergantungan runtime. |

## 8. Kebutuhan nonfungsional

- Offline-first: tidak ada request WAN wajib selama sesi inti.
- Reliability: status kegagalan jelas, retry tidak tanpa batas.
- Latency: ukur baseline sebelum menetapkan target.
- Privacy: tidak ada upload log otomatis; samarkan identifier sensitif.
- Security: endpoint lokal tidak terekspos ke jaringan eksternal.
- Battery/thermal: ukur panas dan konsumsi daya saat sesi panjang.
- Compatibility: klaim hanya untuk kombinasi perangkat yang diuji.
- Safety: pengujian head unit hanya ketika kendaraan parkir aman.

## 9. Eksperimen wajib

Setiap eksperimen mencatat: ID, tanggal, versi aplikasi, perangkat, konfigurasi, langkah, bukti, hasil yang mendukung hipotesis, hasil yang menyangkal, dan tindakan berikutnya. Jangan mengarang hasil; gunakan status `BELUM DIUJI`, `BERHASIL`, `GAGAL`, atau `BELUM KONKLUSIF`.

### EXP-01 — Inventaris perangkat
- **Pertanyaan:** perangkat dan batas teknis apa yang tersedia?
- **Prasyarat:** akses ke Android, iPhone dan HU.
- **Langkah:** catat model/versi OS Android, chipset, arsitektur, port/USB mode, Wi-Fi Direct, model/firmware HU, versi T-Link, browser yang tersedia dan versi iOS.
- **Bukti:** foto halaman About/firmware dengan serial/IMEI disamarkan, versi dan model kabel/port.
- **Mendukung:** informasi cukup untuk memilih transport kandidat.
- **Menyangkal:** APK tidak bisa diinstal atau tidak ada jalur output/input yang dapat diuji.
- **Berikutnya:** lengkapi data sebelum implementasi receiver; alat pencatatan dan probe Flutter boleh dipakai untuk pengumpulan bukti.

### EXP-02 — Android tanpa internet
- **Pertanyaan:** bisakah sesi berjalan dengan internet hanya di iPhone?
- **Prasyarat:** receiver bawaan dan link lokal telah bekerja sebagai baseline; catat versi build.
- **Langkah:** baseline online; matikan mobile data; putuskan Wi-Fi Android dari jaringan internet; pastikan tidak ada tethering WAN iPhone ke Android; uji ulang dan catat apakah gagal saat install, aktivasi, pairing, start session, runtime atau recovery.
- **Bukti:** video layar, pesan error, status jaringan, timestamp dan log yang tersedia. Jangan simpan password/token.
- **Mendukung offline:** sesi inti berjalan konsisten tanpa WAN Android.
- **Menyangkal:** kegagalan berulang dengan bukti dependensi layanan online wajib atau hasil tidak dapat diisolasi.
- **Berikutnya:** identifikasi dependensi; jangan bypass autentikasi atau menebak endpoint.

### EXP-03 — Validasi T-Link mirroring
- **Pertanyaan:** apakah T-Link menampilkan aplikasi Android dan mengirim input balik?
- **Prasyarat:** HU berfungsi normal, mobil parkir.
- **Langkah:** coba aplikasi Android biasa; uji perpindahan aplikasi, orientasi, sentuh HU, audio, dan layar Android mati.
- **Bukti:** video dari HU dan Android.
- **Mendukung:** output aplikasi dan input balik berfungsi.
- **Menyangkal:** hanya aplikasi tertentu yang didukung, tampilan tidak muncul, atau input tidak kembali.
- **Berikutnya:** evaluasi opsi browser atau stop opsi ini.

### EXP-04 — Browser lokal cadangan
- **Pertanyaan:** apakah browser HU dapat menampilkan relay lokal?
- **Prasyarat:** browser dapat dibuka di HU.
- **Langkah:** akses halaman lokal sederhana yang disediakan Android melalui LAN lokal tanpa internet; uji video dan input sebelum menguji sesi CarPlay.
- **Bukti:** URL lokal, konfigurasi jaringan, video tampilan/input.
- **Mendukung:** browser mengakses endpoint lokal dan input kembali.
- **Menyangkal:** browser tidak tersedia, jaringan terisolasi, atau input tidak mungkin.
- **Berikutnya:** utamakan T-Link; jangan memaksakan browser lokal bila prasyarat gagal.

### EXP-05 — Audit jaringan
- **Pertanyaan:** apakah link inti tetap berjalan tanpa WAN Android?
- **Prasyarat:** jalur kandidat sudah bekerja dasar.
- **Langkah:** petakan setiap interface dan tujuan koneksi; matikan WAN Android; ulangi pairing, sesi dan reconnect; catat kebutuhan DNS/cloud.
- **Bukti:** diagram link dan log yang tidak berisi kredensial.
- **Mendukung:** seluruh komunikasi inti bersifat lokal.
- **Menyangkal:** layanan cloud wajib pada runtime atau transport tidak dapat dipisahkan dari WAN.
- **Berikutnya:** hilangkan ketergantungan hanya bila sah dan realistis; selain itu ajukan keputusan scope.

### EXP-06 — Input/audio/recovery
- **Pertanyaan:** apakah solusi praktis digunakan?
- **Prasyarat:** gambar CarPlay sudah tampil.
- **Langkah:** uji sentuh, tombol HU/kemudi bila ada, Siri, mikrofon, musik, navigasi, panggilan, kabel putus, background dan reconnect satu per satu.
- **Bukti:** matriks per fitur dan langkah reproduksi.
- **Mendukung:** fungsi prioritas bekerja stabil.
- **Menyangkal:** fungsi wajib tidak dapat diteruskan atau setup ulang terlalu rumit.
- **Berikutnya:** catat batasan atau stop jika kebutuhan wajib gagal.

### EXP-07 — PoC minimal
- **Pertanyaan:** komponen minimal apa yang diperlukan untuk receiver bawaan DashTConnect?
- **Prasyarat:** jalur teknis dan lisensi sudah dipahami.
- **Langkah:** buat hanya komponen yang diperlukan seperti status, start/stop, pemeriksaan lokal, log dan recovery. Jangan menulis ulang protokol tanpa dasar.
- **Bukti:** source, build reproducible, instruksi dan log.
- **Mendukung:** PoC memberi nilai terukur.
- **Menyangkal:** protokol inti tidak tersedia atau hanya menduplikasi proyek lain.
- **Berikutnya:** uji stabilitas atau dokumentasikan blocker.

### EXP-08 — Stabilitas
- **Pertanyaan:** apakah sesi cukup stabil untuk pemakaian harian?
- **Prasyarat:** PoC berjalan.
- **Langkah:** uji sesi panjang, sleep/wake, restart Android/HU dan reconnect, hanya saat parkir.
- **Bukti:** durasi, disconnect, crash, waktu reconnect dan suhu bila tersedia.
- **Mendukung:** stabil sesuai target yang ditetapkan setelah baseline.
- **Menyangkal:** crash, panas berlebih atau recovery gagal.
- **Berikutnya:** perbaiki penyebab terukur atau batasi klaim.

## 10. Tahapan kerja

1. **A — Reset arah/inventaris:** update README/PRD dan catat perangkat.
2. **B — Baseline:** uji gambar/input T-Link dan persiapan jaringan lokal; pengujian sesi iPhone menunggu receiver bawaan.
3. **C — Feasibility transport:** uji mirroring, browser lokal, USB/Wi-Fi Direct dan input.
4. **D — Keputusan arsitektur:** pilih berdasarkan bukti dan lisensi.
5. **E — PoC minimal:** implementasi setelah jalur inti ditemukan.
6. **F — Offline/recovery:** buktikan tanpa WAN Android dan ukur reconnect.
7. **G — Stabilitas:** dokumentasikan hasil nyata dan batasan.

## 11. Go / revise / stop

**GO** jika sesi CarPlay nyata diterima Android, ditampilkan di HU melalui jalur yang reproducible, berjalan tanpa WAN Android, dan kebutuhan input/audio utama cukup stabil.

**REVISE** jika CarPlay bisa diterima Android tetapi jalur T-Link belum cocok dan ada opsi tampilan lain yang masih sesuai perangkat; atau ada dependensi yang belum dipahami.

**STOP / minta keputusan pengguna** jika tidak ada jalur yang sah untuk menerima CarPlay, T-Link tidak dapat menampilkan output, internet Android wajib selama sesi inti, atau satu-satunya solusi adalah mirroring biasa/UI tiruan. Jangan diam-diam mengganti target.

## 12. Risiko

| Risiko | Mitigasi |
|---|---|
| T-Link tidak menampilkan aplikasi atau relay | Uji paling awal sebelum coding. |
| Android phone tidak dapat menjadi receiver sesuai kebutuhan | Verifikasi implementasi dan hasil nyata proyek pembanding. |
| Receiver memerlukan internet Android pada runtime | Isolasi tahap dan dokumentasikan kebutuhan persis. |
| LAN dan WAN tercampur saat pengujian | Catat interface dan matikan WAN secara eksplisit. |
| Input/audio tidak bisa diteruskan | Uji setiap kanal secara terpisah. |
| Beda firmware/OS mengubah hasil | Klaim hanya untuk kombinasi yang diuji. |
| Lisensi proyek pembanding membatasi penggunaan | Periksa lisensi sebelum menyalin/memodifikasi. |

## 13. Pertanyaan terbuka

1. Perangkat awal: Samsung A04s / SM-A047F, Android 14. Kemampuan transport receiver masih perlu diuji.
2. Model head unit dan versi T-Link? Application 1.1.0005.4400 dan M-Toyota 0.0.2 sudah tercatat.
3. T-Link melakukan mirroring penuh atau hanya mendukung aplikasi/protokol tertentu?
4. Apakah browser dapat dibuka di HU di luar aplikasi T-Link?
5. Komponen receiver bawaan mana yang masih memerlukan WAN, dan apa bukti/log-nya?
6. Android tidak boleh memiliki akses WAN selama sesi; internet tetap di iPhone. **Ditetapkan pengguna.**
7. Apakah sentuhan dari HU wajib kembali ke CarPlay? **Asumsi: ya.**
8. Apakah USB wajib, atau koneksi lokal wireless boleh digunakan bila stabil?
9. Apakah browser lokal di HU bisa diterima jika terbukti kompatibel?

## 14. Sumber dan batas klaim

Diakses/diperiksa 22 Oktober 2026:
- [Repository DashTConnect](https://github.com/farhanreninda/dashtconnect): implementasi lokal dan perubahan belum otomatis dipublikasikan; status repo jarak jauh berbeda dari isi workspace.
- [Apple CarPlay docs](https://developer.apple.com/documentation/carplay) dan [entitlements](https://developer.apple.com/documentation/carplay/requesting-carplay-entitlements): dokumentasi CarPlay untuk aplikasi iOS dan kategori/entitlement terkait; bukan bukti bahwa Android dapat menjadi receiver CarPlay generik melalui API publik Apple.
- Referensi implementasi receiver dan batas source build dicatat di [audit sumber](feasibility.md).

## 15. Keputusan saat ini

**Bangun DashTConnect sebagai aplikasi mandiri dengan receiver bawaan dan Android tanpa internet.** Jalur yang dituju adalah iPhone → DashTConnect di Android → T-Link. Internet dipakai oleh iPhone; tidak ada tethering WAN ke Android. Persiapan Wi-Fi/Bluetooth, tutorial, uji gambar/input dan catatan lokal tersedia. Protokol receiver/media telah diintegrasikan, tetapi identitas aksesori dan uji sesi nyata masih diperlukan; mikrofon serta reconnect otomatis belum tersedia. Source protokol terpilih dikompilasi dalam APK dengan atribusi/lisensinya; tidak ada aplikasi receiver lain yang wajib dipasang atau dibuka.
