# DashTConnect

DashTConnect memiliki dua mode koneksi dengan kebutuhan perangkat yang berbeda.

## Apple CarPlay

Receiver CarPlay bawaan menerima gambar, audio, dan kontrol sentuh dari iPhone melalui Bluetooth serta Wi-Fi lokal. Android meneruskan tampilan ke head unit melalui T-Link. Mode ini memerlukan iPhone, Android, dan HU T-Link; protokol receiver existing dipertahankan.

Mulai receiver menyiapkan izin dan panel sistem bila Bluetooth/Wi-Fi belum aktif, lalu mencoba iPhone terakhir yang berhasil tersambung atau satu-satunya ponsel yang dipasangkan. Jika pilihan belum jelas, pengguna memilih perangkat. Pairing awal dan persetujuan sistem tetap dilakukan pengguna. Wi-Fi internet Android boleh tetap aktif.

CarPlay memakai layar penuh dengan kontrol mengambang yang dapat digeser ke tepi. Kontrol kembali setelah sepuluh detik tanpa interaksi. Mode redup serta uji gambar/sentuhan T-Link tetap tersedia. Status terhubung memerlukan runtime iAP2 dan frame yang benar-benar dirender.

## Android Auto

Targetnya satu HP Android yang menjalankan sumber Android Auto dan receiver di dalam DashTConnect, lalu meneruskan tampilan ke HU melalui T-Link. Tidak memakai HP kedua atau aplikasi receiver eksternal. HU tetap T-Link, sama seperti jalur CarPlay.

Receiver Android Auto internal **belum terintegrasi** pada versi 0.8.2+42. Yang tersedia adalah pemilihan mode, pemeriksaan layanan Android Auto, akses pengaturan, dan panduan sesuai status tersebut. Belum ada sesi Android Auto yang bisa dimulai. USB atau layanan aktif tidak ditampilkan sebagai koneksi berhasil.

Audit self-mode menemukan pendekatan receiver lokal, tetapi penerimaan video/audio/input dan kompatibilitas dengan versi Android Auto pada HP masih memerlukan integrasi serta pengujian. T-Link hanya meneruskan tampilan/input; bukan pengganti mesin protokol Android Auto.

## Pilihan mode dan panduan

Setelah splash, aplikasi membuka Beranda dengan diagram CarPlay, akses cepat ke panduan/uji T-Link, serta ringkasan kontrol mengambang dan mode redup. Pilih mode koneksi membuka Apple CarPlay atau Android Auto; pilihan terakhir ditandai. Tidak ada pintasan pilihan mode ganda di Pengaturan atau tombol kanan atas. Tab Panduan langsung menampilkan isi CarPlay dan dapat berganti ke topik Android Auto tanpa memilih atau memulai transport.

## Tampilan dan informasi

Tema sistem, terang, dan gelap tetap tersimpan. Navigasi Beranda, Panduan, dan Pengaturan memakai indikator aktif serta rail pada landscape. Layout mengikuti ruang konten dan pembesaran teks. Animasi logo sekali saat memasuki halaman menghormati pengurangan animasi.

Pengaturan memuat preferensi tampilan, mode redup, informasi perangkat, dan Tentang aplikasi. Informasi model, Android, jaringan, suhu baterai, dan daya dibaca dari perangkat; informasi teknis tidak memenuhi beranda. Versi aplikasi saat ini 0.8.2+42.

## Rujukan fitur

[Panduan dua mode](docs/dual-mode.md) · [Audit Android Auto](docs/android-auto.md) · [Receiver CarPlay](docs/receiver.md) · [Arsitektur](docs/architecture.md) · [Validasi](docs/validation-flutter.md).

Pengujian CarPlay terdahulu membuktikan gambar, sentuhan, dan musik pada pasangan perangkat pemilik. Itu tidak menjamin semua HU, sesi panjang, Siri, panggilan, suhu/daya, atau kompatibilitas Android Auto. Status dan bukti setiap versi dicatat terpisah dalam dokumentasi validasi.
