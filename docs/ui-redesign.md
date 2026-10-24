# Redesign UI DashTConnect 0.4.1+7

Brief pemilik meminta redesign visual seluruh aplikasi dan perbaikan landscape tanpa mengubah fitur, protokol, data maupun framework. Referensi berasal dari tujuh screenshot dan DESIGN.md dalam ZIP Stitch. HTML tidak dijalankan; angka/status serta integrasi aplikasi lain pada contoh tidak menjadi spesifikasi fungsi.

## Arah visual

Permukaan terang bernuansa biru, panel putih, alternatif gelap navy, serta aksen #006BFD mempertahankan identitas pemilik. Space Grotesk untuk heading dan Inter untuk isi mengikuti referensi; kedua font dibundel lokal dengan lisensi OFL dan checksum sumber sehingga tidak memakai internet ketika aplikasi dibuka. Tidak ada dependency Flutter baru.

Tema memusatkan warna, tipografi, bentuk tombol/input, navigasi, dialog dan bottom sheet. Komponen bersama menyediakan panel, area gulir, kolom adaptif, baris aksi dan pemberitahuan. Panel 24 dp, tombol 18 dp, input 14 dp serta ikon 15 dp membedakan peran komponen. Biru dipakai untuk tindakan dan pilihan aktif. Tidak ditambahkan statistik, foto, fitur atau status koneksi fiktif.

## Halaman yang diubah

| Halaman | Perubahan presentasi |
| --- | --- |
| Beranda | Receiver menjadi aksi utama. Tutorial, uji layar dan ringkasan Android dipisahkan dari panel koneksi. Tombol utama terlihat sebelum scroll pada landscape normal Samsung. |
| Panduan | Tutorial, tindakan Wi-Fi/Bluetooth dan bantuan dikelompokkan sesuai alur. |
| Tutorial 1–4 | Progres langkah aktual, panel instruksi, kontrol lanjut/sebelumnya dan penyelesaian tetap tersedia; konten dapat digulir pada landscape pendek. |
| Pengaturan | Tampilan dan kontrol redup bersebelahan dengan informasi/catatan di ruang lebar; penjelasan aplikasi ditempatkan setelah tindakan. Tema tersimpan tetap dipertahankan. |
| Informasi perangkat | Pembacaan Android dan formulir inventaris dipisahkan menjadi panel. Label panjang membungkus di luar input. |
| Buku catatan/editor | Daftar percobaan menjadi baris aksi; panduan dan formulir dipisahkan. Validasi bukti, error simpan dan dialog perubahan belum disimpan dipertahankan. |
| Laporan lokal | Dokumen berada pada area gulir; tombol salin tetap di luar area tersebut agar terjangkau pada layar pendek. |
| Uji tampilan | Empat target dan penghitung tetap aktif. Pada landscape lebar, target berada pada satu baris; reset dan redup tetap dapat digunakan. |
| Receiver | Persiapan dan pilihan iPhone berdampingan jika cukup lebar. Overlay status tidak mengganti SurfaceView, sehingga perubahan status tidak membuang renderer. |
| Baca awal/error | Panel loading dan retry juga dapat digulir agar pesan tidak menutupi kontrol pada layar pendek. |

## Landscape dan aksesibilitas

Navigasi berpindah ke rail pada landscape mulai 600 dp atau tablet lebar. Rail memiliki area gulir sendiri ketika ruang vertikal kecil. Kolom dibagi berdasarkan **ruang konten setelah rail**: minimal 600 dp dan skala teks maksimal 150%; selain itu panel bertumpuk. Ambang awal 700 dp dikoreksi setelah inspeksi Samsung menunjukkan ruang tersisa sekitar 645 dp. Ilustrasi alur pada panel utama dikeluarkan agar tidak mendorong tombol koneksi ke bawah.

Semua area panjang dapat digulir. Label formulir membungkus, input memakai scroll padding, dan isi controller tetap bertahan saat rotasi. Tombol memakai target minimum 48 dp. Baris aksi mendukung Tab/Enter dengan outline fokus 2 dp. Error menyertakan teks; indikator progres memiliki label. Kontras teks, permukaan, outline input, warna error dan target uji diperiksa melalui luminansi pada kedua tema.

## Pemeriksaan

- Analisis Flutter bersih dan format Dart tanpa perubahan.
- 50 tes Flutter lulus. Sepuluh tes responsif baru mencakup semua rute, landscape 800×360 dan 640×320, terang/gelap, teks 100%/200%, rotasi sambil mengisi, area keyboard, simpan inventaris/catatan, laporan, target sentuh, tutorial, dialog perubahan, dan aktivasi keyboard.
- Tes responsif memuat font yang benar-benar dibundel. Ada pemeriksaan khusus agar tombol receiver terlihat sebelum scroll pada landscape normal, bukan hanya dapat ditemukan setelah digulir.
- Tes receiver tetap memeriksa pemisahan event antar-view, prasyarat autentikasi/jaringan, serta surface yang tidak dibuat ulang ketika status berubah. Status connected pada fixture bukan bukti sesi iPhone nyata.
- APK debug dibangun dan dipasang dengan upgrade, tanpa uninstall/reset. Byte catatan privat dibandingkan sebelum dan sesudah pemasangan.
- Tinjauan Samsung mencakup terang/gelap, portrait/landscape, navigasi samping, informasi perangkat, editor, laporan, tutorial, target uji, reset dan redup/pulihkan. Formulir fisik hanya difokuskan tanpa menyimpan data uji; penyimpanan dan area keyboard diuji otomatis dengan fake repository.
- Paket akhir dibangun ulang selama 27 detik dari output APK baru dan tanda tangannya valid. Setelah pengujian UI, tema gelap serta pengaturan rotasi semula dipulihkan. Hash inventaris/catatan sebelum dan sesudah identik; log proses sendiri tidak memiliki marker E/flutter atau FATAL EXCEPTION.

APK debug akhir: `apps/dashtconnect/build/app/outputs/flutter-apk/app-debug.apk`, 157761576 byte. SHA-256:

```text
E2DFA125AB8F1264CF7E67967EC81681164445D67D0F6570087909D78DF96F9F
```

Screenshot QA berada dalam `.local-tools/qa`, yang diabaikan Git. Halaman akhir gelap landscape, terang portrait, receiver, probe, tutorial, editor dan laporan telah ditinjau. Alur koneksi tiga perangkat dipadatkan menjadi satu baris ketika lebar cukup; teks 200% tetap bertumpuk dan bergulir.

Kode native, channel, model, codec penyimpanan, aturan hasil, izin dan mesin receiver tidak diubah untuk redesign. Metadata paket/skema tetap sama, dengan versi aplikasi dinaikkan untuk build UI ini.

## Gate desain

- Hard gate PASS: UI memakai data aktual atau menjelaskan keadaan belum siap; tidak menyalin status/angka contoh. Tes reflow, zoom, navigasi dan tindakan aktif lulus.
- Purpose gate PASS: warna/font berasal dari brief; panel membedakan kelompok dan tombol utama mendapat prioritas. Tidak memakai foto pengisi, gradient/glow atau statistik dekoratif.
- Liveliness PASS: ENERGY 1 / RHYTHM 2 / MOTION 1. Susunan disesuaikan kebutuhan halaman; biru dan logo mengikat identitas seluruh UI.
- Craftsmanship PASS: scope presentasi dipertahankan, kontras diperiksa secara numerik, fokus keyboard dan perubahan belum tersimpan diuji. Screenshot fisik diperiksa dan batas kolom diperbaiki dari bukti perangkat.

## Batas pekerjaan

Redesign tidak menambahkan autentikasi aksesori atau menyatakan CarPlay berhasil. Koneksi iPhone nyata, video/audio T-Link, input HU, kondisi tanpa WAN selama sesi, layar sepenuhnya mati dan pengaruh terhadap panas masih memerlukan pengujian terpisah. Mikrofon/reconnect otomatis tetap belum tersedia. Tidak dilakukan commit/push.
