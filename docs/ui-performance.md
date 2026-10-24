# UI dan performa 0.5.0+10

## Pembaruan navigasi 0.5.5+15

Efek opacity yang mencakup seluruh isi tab dihapus. Pergantian tab langsung menampilkan konten; indikator navigasi tetap bergerak singkat. IndexedStack, lazy tab, TickerMode dan retensi posisi tetap dipakai. Tidak menambah cache atau layer render tanpa hasil pengukuran yang menunjukkan kebutuhan.

APK sebelumnya pada Samsung berstatus DEBUGGABLE. Build release disiapkan untuk pengujian penggunaan normal agar pengamatan kelancaran tidak memakai overhead build pengembangan. Perubahan ini tidak menyatakan angka FPS atau mempercepat animasi perpindahan aplikasi milik sistem Android.

Brief: redesign seluruh presentasi, Beranda berfokus pada receiver, informasi teknis masuk Pengaturan, navigasi lebih khas, dan interaksi ringan. Logo serta biru merek dipertahankan. Tema terang/gelap, mode redup terpusat, catatan lokal dan receiver native tetap tersedia.

## Hasil audit dan perubahan

| Temuan implementasi sebelumnya | Perubahan | Bukti / batas |
| --- | --- | --- |
| Beranda memanggil info perangkat saat dibuat dan setiap resume, lalu merender model, jaringan dan suhu. | Seluruh pembacaan dipindahkan ke halaman Informasi perangkat yang sudah ada. Beranda hanya memuat aksi receiver, persiapan dan uji tampilan. | Tes menghitung nol pembacaan saat startup, tab berpindah dan resume; satu pembacaan ketika informasi perangkat dibuka. Retry tetap tersedia. |
| Pergantian tab mengganti subtree aktif. PageStorage hanya mempertahankan sebagian state. | IndexedStack membuat tab saat pertama dibuka dan mempertahankan element tab yang sudah dikunjungi. Ticker tab tersembunyi dimatikan. | Tes membandingkan identitas element sebelum/sesudah berpindah tab. Maksimal tiga halaman ringan dipertahankan; decoder receiver tetap berada di route tersendiri. |
| Dua ThemeData beserta ColorScheme dibuat pada setiap notifikasi controller catatan. | Tema terang dan gelap dibuat sekali per ResearchApp. | Tes memeriksa instance tema tetap sama setelah pilihan tema disimpan. |
| Splash memuat logo 1254 px tanpa target decode dan intro 600 ms. | Decode mengikuti lebar tampil 128 dp, dibatasi 128–512 px. Intro dipersingkat menjadi 320 ms. | Ini batas ukuran decode dan durasi animasi, bukan hasil pengukuran total waktu startup atau PSS. Aset asli tetap dipakai. |
| Navbar/rail standar dan hierarki warna dominan biru pada permukaan. | Dock berbingkai dengan indikator aktif, fokus 2 dp, ikon koneksi, serta versi rail dari komponen yang sama. Permukaan netral putih/slate dan satu aksen biru. | Label dan target sentuh tetap tersedia, keyboard serta reduce motion diuji. Lebar rail diperbaiki dari screenshot Samsung agar Pengaturan tidak terpecah pada ukuran teks normal. |
| Informasi Android berupa daftar panjang. | Kategori Perangkat, Konektivitas, Daya dan Detail teknis. Tentang aplikasi juga dapat diperluas. | Data berasal dari gateway yang sama. Tes memastikan field native tambahan tetap dapat dibuka, bukan dibuang. |
| Pergerakan antarhalaman memakai konfigurasi Material umum. | Route Material tetap dipakai, dengan durasi 200 ms masuk / 160 ms kembali; fade tab 150 ms dan indikator 160 ms. | Reduce motion meniadakan animasi baru. Tidak ada animasi logo/status yang berulang atau menyatakan koneksi berhasil. |

Pembacaan/penulisan file sebelumnya sudah asynchronous dan dibatasi 1 MiB. Codec, validasi, penulisan atomik dan pengelolaan koneksi tidak diubah tanpa bukti bottleneck. Tidak menambahkan dependency, isolate, timer, framework state management atau data simulasi untuk optimasi ini.

## Cakupan visual

Tema, tipografi, button, field, surface, action tile, dialog dan bottom sheet bersama diperbarui. Perubahan ini berlaku untuk Beranda, Panduan, Pengaturan, tutorial, informasi perangkat, probe T-Link, receiver, formulir eksperimen, catatan, laporan, loading, error dan disabled state. Tata letak tetap mendukung portrait, landscape pendek, keyboard dan teks hingga 200%. Kontrol redup tetap satu tempat: Pengaturan → Layar.

## Validasi dan batas pengukuran

Log pemeriksaan dan screenshot berada di `.local-tools/qa/refinement-*`, diabaikan Git. Tes mencakup seluruh rute pada dua tema, font nyata, landscape, rotasi form, keyboard, state catatan, retry, laporan, surface receiver dan retensi tab.

Peningkatan yang dibuktikan berupa berkurangnya pekerjaan dan pemuatan ulang dalam implementasi. Belum ada benchmark FPS, CPU/GPU, konsumsi baterai atau memori proses pada build release. Build debug dan observasi perangkat tidak dipakai untuk mengklaim 60 FPS, persentase penghematan baterai atau waktu koneksi.

CarPlay/T-Link nyata tetap membutuhkan pengujian iPhone dan head unit. Identitas aksesori tidak ditambahkan, protokol dan izin native tidak diubah, serta tidak ada commit/push.

## Hasil pemeriksaan

- 62 tes Flutter lulus. Analisis kode bersih dan sumber Dart diformat. Tes baru meliputi kategori data native, lazy tab/retensi element, cache tema, keyboard navigasi, reduce motion dan label rail satu baris dengan font Inter sebenarnya.
- Dua tema serta seluruh rute pada landscape 800×360 dan teks 100–200% diperiksa melalui tes widget. Form, dialog, laporan, tutorial, error/retry dan state native receiver tetap masuk cakupan regresi.
- Samsung A04s Android 14: Beranda, navigasi, detail perangkat asli, Pengaturan, Panduan dan persiapan receiver diperiksa secara fisik; screenshot terang portrait dan gelap landscape ditinjau. Tema dan rotasi awal dipulihkan. Tidak dibuat inventaris atau hasil eksperimen palsu pada perangkat.
- Build debug akhir berhasil dalam 31 detik. APK 0.5.0+10 terpasang sebagai upgrade dengan byte catatan privat identik; signature valid. Ukuran 157770476 byte, SHA-256 `8B17F66302D8142AFB53E6A73FB3642F26F3737582CAEBD6C1A5EDF45F8FC8A7`.

## Gate desain

- Hard gate PASS: kontras tema diuji secara numerik; reflow, keyboard, state error dan tindakan nyata melewati tes. Tidak ada statistik, menu kosong atau klaim koneksi simulasi.
- Purpose gate PASS: dock membedakan navigasi dari konten, kategori mengurangi kepadatan info, animasi singkat menghubungkan perubahan halaman. Tidak memakai blur, glow atau dekorasi yang terus bergerak.
- Liveliness PASS: ENERGY 1 / RHYTHM 2 / MOTION 1. Aksen biru dan logo tetap menjadi identitas; Beranda berfokus pada satu aksi, halaman informasi memberi hirarki berbeda sesuai data.
- Craftsmanship PASS: caller, tes, tema bersama dan dokumentasi diperbarui. Inspeksi Samsung menghasilkan perbaikan lebar rail dan dock; penyimpanan dan protokol dipertahankan. Klaim performa dibatasi pada perubahan yang benar-benar diverifikasi.
