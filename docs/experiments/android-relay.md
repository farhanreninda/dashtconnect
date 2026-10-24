# Eksperimen Android relay

Tanggal persiapan: 22 Oktober 2026. Pertanyaan, prasyarat, langkah, bukti pendukung/penyangkal dan tindakan berikutnya untuk EXP-01 sampai EXP-08 ada di [PRD](../PRD.md) dan ditampilkan dalam aplikasi Flutter. Hasil fisik dicatat pengguna dalam buku eksperimen aplikasi; tidak otomatis dianggap lulus.

| ID | Status awal | Bukti yang tersedia / kekurangan | Berikutnya |
| --- | --- | --- | --- |
| EXP-01 | BELUM KONKLUSIF | ADB mengonfirmasi SM-A047F, API 34, Exynos 850. Foto HU: Application 1.1.0005.4400 dan M-Toyota 0.0.2. iPhone: iOS 27.0/build 24A437 dari riset USB lama. Model HU, versi T-Link dan kabel belum lengkap; lihat [inventaris](../devices/toyota-raize-2022.md). | Simpan inventaris pada HP pemilik dan lengkapi bagian yang belum diketahui. |
| EXP-02 | BELUM DIUJI | Pengguna melaporkan percobaan lama membutuhkan internet; versi/tahap/log belum ada. | Uji receiver bawaan setelah tersedia; catat baseline dan titik kegagalan saat WAN Android diputus. |
| EXP-03 | BELUM DIUJI | Probe empat target tersedia; belum ada bukti tampil atau input balik dari HU. | Saat parkir, tampilkan probe di T-Link lalu tekan dari HU. Ulangi dengan mode redup. |
| EXP-04 | BELUM DIUJI | Browser HU belum diverifikasi. App Flutter tidak menyediakan relay server. | Periksa browser dan akses endpoint lokal yang disediakan terpisah. |
| EXP-05 | BELUM DIUJI | App membaca validasi jaringan OS tanpa request WAN. Itu bukan bukti sesi receiver offline. | Petakan setiap link dan putuskan WAN secara eksplisit. |
| EXP-06 | BELUM DIUJI | Receiver/audio/input CarPlay belum tersedia. | Uji setelah sesi CarPlay nyata tampil. |
| EXP-07 | BELUM KONKLUSIF | Flutter dipilih untuk UI/diagnostik. Mesin receiver dan asal identitas aksesori belum dipilih. | Putuskan integrasi setelah bukti dan audit. |
| EXP-08 | BELUM DIUJI | Belum ada uji durasi/thermal pada HU. | Bandingkan suhu baterai dan daya pada terang/redup dengan beban setara. |

## Percobaan redup (bagian EXP-03/08)

- Pertanyaan: apakah menurunkan kecerahan jendela HP mempertahankan output/input T-Link dan mengubah konsumsi/thermal?
- Prasyarat: gambar/input probe sudah bekerja, kondisi parkir aman, pengisian dan jaringan dicatat.
- Langkah: ukur baseline; aktifkan Pengaturan → Layar → Mode redup; buka Uji tampilan, cocokkan gambar HU dan tekan target; pulihkan layar dari sakelar yang sama di Pengaturan; uji tombol daya secara terpisah jika aman dan catat apakah proyeksi berhenti.
- Bukti: video HP/HU tanpa data pribadi, konfigurasi, durasi dan suhu baterai sebelum/sesudah pada kondisi setara.
- Mendukung: gambar dan input tetap ada; perubahan daya/suhu diukur dan dapat diulang.
- Menyangkal: proyeksi berhenti, input terputus, atau suhu tidak berubah dalam kontrol yang sama.
- Berikutnya: batasi klaim berdasarkan hasil. Kecerahan rendah dan layar sepenuhnya mati merupakan kondisi berbeda.
