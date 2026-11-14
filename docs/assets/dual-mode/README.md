# Screenshot UI dua mode 0.8.0+40

Alur awal dan navbar terbaru 0.8.1 tersedia pada [galeri Beranda](../home-navigation/README.md). File di bawah merupakan rekaman 0.8.0, bukan tampilan navbar terkini.

Diambil langsung dari Samsung SM-A047F, Android 14, pada 30 Oktober 2026. Tidak dibuat ulang atau diubah proporsinya. Manifest file, ukuran asli dan checksum: [SOURCES.json](SOURCES.json).

- `01`, `04`, `08`, `09`: pemilihan mode, portrait/landscape, terang/gelap.
- `02`, `05`, `06`: pemeriksaan kesiapan serta panduan Android Auto. **Bukan bukti sesi Android Auto**; receiver internal belum tersedia.
- `07`, `12`, `13`: Pengaturan, Tentang dan informasi perangkat yang dibaca langsung.
- `10`, `11`, `14`, `15`: Beranda, persiapan receiver dan Panduan CarPlay.

Nomor `03` tidak dipakai: screenshot konsep pendamping HU Android Auto native telah dihapus setelah target dikoreksi menjadi receiver internal pada satu HP menuju T-Link. Semua file yang tersisa mengikuti target tersebut. Screenshot galeri website versi 0.7.3 tetap merupakan arsip terpisah.

Screenshot berisi area yang terlihat pada layar; konten panjang dapat digulir. Sesi CarPlay nyata diuji terpisah, bukti runtime tersimpan lokal agar gambar aplikasi iPhone pribadi tidak ikut dipublikasikan. Lihat [validasi](../../validation-flutter.md).
