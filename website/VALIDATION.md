# Validasi redesign landing page

24 Oktober 2026. Preview produksi: http://127.0.0.1:4321/dashtconnect/.

- PASS — Astro check: 0 error, 0 warning, 0 hint; build statis selesai. Vite memberi pemberitahuan path font publik dengan base path; font tersedia dan dimuat browser.
- PASS — 14 tes Chromium: 30 posisi screenshot tersedia lewat scroll tanpa tab/disclosure, kedua tema pada 320/390/768/1024/1440 px, tanpa overflow horizontal atau respons HTTP gagal.
- PASS — Semua 24 screenshot dapat diperbesar, Escape menutup dialog, dan fokus kembali ke gambar pemicu.
- PASS — Tema mengikuti perangkat saat belum ada pilihan, berpindah lewat tombol, tersimpan setelah reload, dan tetap berfungsi ketika akses penyimpanan diblokir.
- PASS — Keyboard, menu seluler, FAQ, anchor, canonical, error gambar beserta tautan pemulihan, dan konten tanpa JavaScript.
- PASS — Reduced motion menonaktifkan animasi dan smooth scroll. Animasi masuk singkat berjalan sekali; tidak ada konten yang disembunyikan sambil menunggu animasi.
- PASS — 42 checksum screenshot sumber cocok (24 sebelumnya + 17 terang + 1 CarPlay gelap). Duplikat kiriman tidak diulang. Isi screenshot tidak diedit.
- PASS — Redesign galeri horizontal mengurangi tinggi halaman desktop dari 10481 menjadi sekitar 6656 px sebelum penambahan screenshot terang pada viewport 1440 px. Tidak menghapus screenshot atau penjelasan fitur.
- PASS — Tinjauan visual halaman penuh terang/gelap pada desktop 1440 px dan HP 390 px, serta gambar hero dan pasangan portrait/landscape pada ukuran terbaca.
- PASS — Warna normal: ink/muted pada paper dan surface pada kedua tema; link biru gelap di tema terang, biru muda di tema gelap; tombol putih di biru #006bfd (4,64:1). Aksen besar dan teks biasa memenuhi AA.
- PASS — R-02/03/17/18: HTML semantik, tidak menambah klaim atau bukti pelanggan palsu, dependency runtime tetap Astro.
- PASS — R-23/24/26/27/28: navigasi dan kontrol bekerja, state loading/error tersedia, responsif dan keyboard diuji.
- PASS — R-25/32/33/34/35: kontras, focus, reduced motion, tampilan tanpa JavaScript, dan kondisi penyimpanan gagal ditangani.
- PASS — R-36/37/38: screenshot nyata, tautan proyek nyata, tidak membuat tombol unduhan APK tanpa rilis publik.
- PASS — R-01/04/06/07/08/09/10/12/13/14/19/22: palet dan font aplikasi, ikon relevan, tanpa gradien/glow/dekorasi status palsu atau animasi berulang.
- PASS — R-05/11/15/16/20/21/29/30/31: struktur mengikuti koneksi, sesi, galeri lengkap, panduan dan FAQ; radius/warna terbatas, kedua tema berfungsi.
- PASS — Craft C1–C5: identitas produk, screenshot aktual, urutan konten, aksesibilitas, dan bukti dari perangkat.
- PASS — Liveliness: ritme bagian bervariasi, skala judul terbaca, screenshot menjadi fokus, kontrol mempunyai feedback, gerakan singkat, tidak ada marquee, teks selalu tersedia.

Belum diperiksa di Safari atau browser fisik iPhone. Tidak menjalankan commit, push, atau deployment GitHub Pages. Screenshot peta/dashboard yang diminta pemilik menampilkan isi sesi asli; tidak melakukan penyamaran data di gambar.

- PASS — 17 sumber screenshot terang, ditambah pasangan hero CarPlay, dipakai dalam picture. Tes memeriksa perpindahan currentSrc terang/gelap, kembali ke terang, dan kecocokan file dialog zoom dengan tema. Build dan 14 tes Chromium lulus setelah perubahan.
- Batas sumber — 11 screenshot punya pasangan kedua tema. Enam foto terang baru hanya muncul di light; screenshot sesi/tutorial/detail yang belum punya pasangan tampil pada tema aslinya.

- PASS — Filter tema ketat: 23 foto terlihat pada light dan 19 pada dark, termasuk hero berbeda sesuai tema. Foto tanpa pasangan disembunyikan pada tema berlawanan. Tes memeriksa seluruh source picture yang terlihat saat light → dark → light, zoom, dan empat langkah tutorial tetap tersedia.
- PASS — Tinjauan visual halaman penuh desktop/HP kedua tema setelah filter, build berhasil dan 14 tes Chromium lulus. Tidak ada filter invert pada screenshot.
