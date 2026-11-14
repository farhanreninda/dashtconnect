# Panduan dua mode

## Memilih mode

Buka DashTConnect ke Beranda, tekan Pilih mode koneksi, lalu pilih Apple CarPlay atau Android Auto. Label Terakhir dipakai menandai pilihan sebelumnya. Tombol pilihan berada pada isi Beranda, bukan kanan atas atau Pengaturan. Pemilihan dapat dibatalkan dengan tombol kembali. Setelah memilih, akses pilihan tetap tersedia di Beranda mode. Kembali dari beranda mode menuju Beranda umum. Selesaikan/keluar dari halaman receiver CarPlay sebelum mengganti mode.

Panduan dapat dibaca tanpa memilih mode koneksi. Buka tab Panduan atau akses cepat di Beranda; CarPlay langsung ditampilkan. Gunakan pilihan topik Apple CarPlay/Android Auto di atas isi panduan. Mengganti topik tidak mengubah lastMode, tidak memulai receiver dan tidak membaca kesiapan Android Auto. Uji tampilan T-Link di Beranda juga bisa dibuka langsung.

## Apple CarPlay: iPhone + Android + T-Link

1. Saat parkir, siapkan iPhone dan Android berdekatan. Biarkan Wi-Fi dan Bluetooth Android aktif; internet Android tidak perlu diputus.
2. Pilih Apple CarPlay. Panduan pertama dapat diselesaikan, dilewati, atau dibuka ulang dari tab Panduan.
3. Untuk pairing pertama, pasangkan iPhone melalui pengaturan Bluetooth Android. Setujui izin serta panel sistem yang diminta.
4. Mulai receiver. iPhone terakhir yang berhasil atau satu-satunya ponsel yang dipasangkan dipilih otomatis; jika beberapa kandidat tanpa riwayat, pilih iPhone.
5. Buka kunci iPhone dan setujui permintaan CarPlay. Tunggu runtime dan gambar pertama. Jika perlu, bantuan Wi-Fi menampilkan jaringan lokal dan sandi tersembunyi.
6. Sambungkan Android ke port data HU dan buka T-Link sesuai petunjuk HU. Uji gambar/sentuhan dari Panduan; sentuhan di HP saja tidak membuktikan input HU.
7. Gunakan kontrol mengambang untuk redup atau Hentikan receiver. Menu menutup setelah idle; tombol menepi saat dilepas dan kembali setelah 10 detik tanpa interaksi. Sesi dihentikan saat aplikasi background atau halaman ditutup.

Kegagalan: periksa pesan aktual, izin mikrofon/perangkat sekitar, Bluetooth, Wi-Fi lokal, dan permintaan pada iPhone. Coba ulang secara eksplisit; tidak ada retry tak terbatas. Internet iPhone tetap digunakan oleh aplikasi iPhone. Koneksi Wi-Fi station dan P2P bersamaan mengikuti hardware/firmware.

## Android Auto: satu Android + receiver internal + T-Link

Target pemilik tetap HU T-Link dengan satu HP Android. DashTConnect harus menerima protokol Android Auto pada HP yang sama sebelum gambarnya diteruskan oleh T-Link. Receiver internal itu belum tersedia pada build ini; belum ada sesi untuk dimulai, digunakan atau dihentikan.

1. Pilih Android Auto. Periksa ulang membaca apakah layanan pada HP tersedia dan aktif.
2. Pengaturan Android Auto membuka preferensi yang tersedia atau informasi aplikasi sistem. Layanan aktif bukan bukti receiver berjalan.
3. Dari Panduan, buka Uji tampilan T-Link saat parkir. Sambungkan Android ke port data HU, buka T-Link dan cocokkan gambar/penghitung sentuhan. Tes ini hanya memeriksa jalur T-Link, bukan sesi Android Auto.

Jika tes tidak tampil, periksa kabel, port dan izin aplikasi pendamping T-Link. Tidak perlu memasang receiver eksternal. Audit self-mode menemukan kebutuhan mesin protokol dan kemungkinan Head Unit Server developer pada versi Android Auto tertentu; otomatisasi tanpa konfigurasi tambahan belum terbukti. Lihat [audit dan pekerjaan tersisa](android-auto.md).

## Pengaturan dan diagnostik

Tema sistem/terang/gelap, redup, informasi perangkat dan Tentang tersedia pada kedua mode. Mode redup memengaruhi jendela DashTConnect. Model, versi Android, jaringan, suhu baterai serta daya berada di Informasi perangkat. CarPlay tidak meminta pengguna memasukkan IP, port atau ADB. Kemudahan persiapan Android Auto internal masih harus dibuktikan setelah mesin receiver terintegrasi.

[Audit Android Auto](android-auto.md) · [Detail receiver CarPlay](receiver.md) · [Arsitektur](architecture.md).
