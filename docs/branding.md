# Identitas biru DashTConnect

Versi 0.2.2+3, 22 Oktober 2026. Pemilik memilih biru pada tombol Kirim Email dalam gambar referensi. Piksel dominan tombol tersebut adalah #006BFD; ini menggantikan aksen hijau tahap awal.

## Warna aplikasi

- Tombol utama memakai #006BFD dengan teks putih.
- Tema terang dan gelap memakai turunan biru untuk teks, tautan, navigasi dan container agar kontras tetap terbaca. Rasio teks utama minimal 4.5:1 diuji, termasuk label tombol dan target sentuh.
- Empat target uji memakai #00347D, #0048AB, #005BD7 dan #006BFD, dengan angka, penghitung dan outline kontras.
- Warna error tetap menyatakan kegagalan. Status eksperimen tidak hanya dibedakan berdasarkan warna.

## Logo

Simbol putih menggambarkan HP yang terhubung ke layar mobil. Latar biru mengikat logo dengan tindakan utama aplikasi. Logo dibuat melalui tool imagegen bawaan, tanpa menggunakan logo Apple, Toyota atau Flutter.

Master PNG terpilih ada di [aset branding](../apps/dashtconnect/assets/branding/dashtconnect-logo.png), dengan [prompt generasi](../apps/dashtconnect/assets/branding/generation-prompt.txt). Percobaan versi transparan tidak dipakai karena hasil mask tidak rapi; master berlatar biru dipertahankan. PNG tidak diubah atau di-resize setelah generasi.

UI memakai master tersebut dengan cache decode kecil untuk toolbar. Salinan identik di drawable-nodpi diperlukan oleh resource Android. Ikon legacy merujuk bitmap; ikon adaptive memakai latar #006BFD dan foreground dengan inset 12%. Simbol setelah inset berukuran sekitar 54.7 x 31.5 dp dalam viewport 108 dp, berada dalam area aman mask. Tampilan logo Android mengikuti mask launcher. Splash Android 12+ memiliki varian tema terang/gelap agar latar dan ikon memakai identitas baru.

Ikon Flutter lama dan override splash lama dikeluarkan ke .local-tools/previous-branding, yang diabaikan Git. Tidak ditambahkan dependency runtime untuk menampilkan logo. Nama paket, lokasi penyimpanan dan schema JSON tetap sama.

## Pemeriksaan desain

- Hard Gate PASS: tidak ada klaim kompatibilitas baru, data fiktif, link mati atau kontrol palsu. Seluruh 20 tes lulus setelah logo ditambahkan; asset loading, navigasi, fokus keyboard serta viewport 320 x 640 pada skala teks 2 tetap berjalan.
- Purpose Gate PASS: biru mengikuti referensi eksplisit pemilik; simbol menyatakan hubungan dua perangkat; nomor pada empat target menjaga fungsi uji tanpa ketergantungan pada perbedaan warna.
- Liveliness PASS: ENERGY 1 / RHYTHM 2 / MOTION 1 dari DESIGN.md dipertahankan. Logo menjadi motif yang berulang pada launcher, toolbar dan splash; aksen utama tetap satu keluarga biru.
- Craftsmanship PASS: domain/data/presentation tidak berubah batasnya, kontrol tetap memiliki handler nyata, tema terang/gelap memenuhi tes kontras, dan gambar toolbar tidak menambah fokus interaktif yang tidak diperlukan.

Build bersih APK 0.2.2+3 berhasil, signature valid dan upgrade pada Samsung berhasil tanpa mengubah catatan lama. Tema terang/gelap serta halaman uji biru diperiksa melalui screenshot aplikasi pada perangkat. Preferensi gelap dipulihkan setelah pemeriksaan. Lihat [hasil validasi](validation-flutter.md).

Belum ada klaim bahwa perubahan branding memperbaiki koneksi T-Link, sesi CarPlay atau suhu perangkat.
