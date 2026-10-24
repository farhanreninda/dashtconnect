# Arah tampilan

Brief pemilik: tampilan modern, semua fungsi mudah diakses, dark mode, dan akses redup layar ketika menguji proyeksi T-Link. Pemilik kemudian memilih biru pada gambar tombol Kirim Email sebagai dasar seluruh branding aplikasi.

Brief lanjutan: pemilik meminta fungsi lebih menonjol, informasi dipisahkan, serta tutorial saat pertama dibuka. Aplikasi harus mandiri; internet tetap di iPhone dan Android hanya memakai koneksi lokal.

Pembacaan desain: aplikasi receiver otomotif mandiri dengan tindakan koneksi utama, panel lembut dan hierarki tegas mengikuti ZIP Stitch dari pemilik. ENERGY 1 / RHYTHM 2 / MOTION 1. Terang dan gelap tetap tersedia karena diminta pemilik; pilihan yang tersimpan dipertahankan.

- Aksen utama `#006BFD` diambil dari piksel dominan tombol referensi pemilik. Tombol utama, logo dan latar launcher memakai biru ini. Teks/link memakai turunan biru yang memenuhi kontras pada tema terang/gelap; warna error tetap menyampaikan kegagalan. Permukaan netral mengikuti tema sistem, terang atau gelap.
- Space Grotesk untuk heading dan Inter untuk teks mengikuti referensi yang diberikan, dengan ukuran yang mendukung pembesaran teks. Font dibundel lokal agar tidak membutuhkan internet; source dan lisensi OFL disertakan di assets/fonts. Tidak menambah dependency styling.
- Ikon Material dipilih sesuai aksi: beranda, panduan, pengaturan, sentuhan, kecerahan dan laporan. Tombol penting memakai label, ikon toolbar memiliki tooltip/semantics.
- Navigasi 0.5 memakai dock berbingkai dengan tiga tujuan yang sama, label dan ikon sebaris bila ruang cukup. Indikator bidang biru muda dan bobot label membedakan tujuan aktif; focus outline 2 dp mendukung keyboard. Pada landscape mulai 600 dp atau tablet, komponen yang sama menjadi rail bergulir. Tab dibuat ketika pertama dibuka dan dipertahankan dalam IndexedStack; ticker tab tersembunyi dinonaktifkan. Panel menjadi dua kolom jika ruang konten minimal 600 dp dan teks tidak lebih dari 150%; selain itu panel bertumpuk.
- Panel 20 dp, input/tombol 14 dp dan ikon 12 dp membedakan kelompok, isian serta aksi. Action tile 16 dp, dock 22 dp, jarak antarkelompok 24 dp dan antaraksi 12 dp. Latar terang #F6F7F9 dan gelap #10141B memberi dasar netral untuk aksen biru; panel putih/slate tanpa blur, glow atau bayangan berulang. Heading 26 dp dan isi 14–16 dp memberi ruang lebih pada layar Samsung tanpa menekan keterbacaan.
- SafeArea, konten bergulir, label formulir terpisah yang dapat membungkus, scrollPadding untuk keyboard, serta target minimum 48 dp menjaga kontrol terjangkau di layar pendek. Laporan menempatkan dokumen dalam scroll dan tombol salin di luar scroll agar tidak terpotong.
- Uji layar memakai empat nada biru dengan nomor, penghitung dan outline kontras. Teks dan angka tetap menyampaikan informasi tanpa bergantung pada perbedaan warna.
- Tutorial empat langkah bergulir, bisa dilewati, dan dapat dibuka ulang dari Panduan. Penyelesaian baru dianggap tersimpan setelah penulisan berhasil. Persiapan jaringan tidak ditampilkan sebagai sesi CarPlay terhubung.
- Halaman receiver memakai satu tindakan Hubungkan iPhone setelah prasyarat terpenuhi. Persiapan dan error bergulir di atas surface yang dipertahankan; pergantian status tidak membuat ulang decoder. Sesi tersambung memakai layar penuh, rasio video mengikuti display landscape, tanpa meregangkan atau memotong gambar. Panel kecil di kiri bawah menyediakan pintasan redup/pulihkan serta kontrol berhenti yang dapat dibuka. Panel gelap dengan ikon putih menjaga kontras pada tema dan konten apa pun; target tekan minimal 48 dp. Status redup sinkron dengan Pengaturan → Layar. Pintasan hanya ada dalam sesi aktif, sesuai permintaan lanjutan pemilik; halaman uji tetap tanpa kontrol redup. Bilah sistem pulih saat sesi berhenti atau halaman ditutup.
- Logo baru diminta pemilik: simbol HP yang terhubung ke layar mobil, berwarna putih pada latar biru. Bentuknya dipakai pada toolbar, launcher dan layar awal; detail aset/generasi ada di docs/branding.md pada akar repo. Ikon launcher memakai inset untuk mempertahankan simbol di dalam mask Android.

Referensi visual yang diperiksa: tujuh screen.png dan DESIGN.md dalam stitch_blue_app_ui_redesign.zip. HTML dalam arsip tidak dijalankan. Arah visual diterapkan pada UI yang sudah ada. Status contoh, foto mobil pembanding, 60 FPS, 12 ms, versi protokol, sensor otomatis, akun/notifikasi serta pembuka receiver eksternal tidak disalin karena tidak mempunyai data atau aksi pada aplikasi ini. Mesin protokol, kontrak, data, validasi dan identitas aksesori tidak diubah untuk redesign.

Kontrol sesi 0.6.7 mengikuti permintaan tombol seperti AssistiveTouch: satu tombol bulat 56 dp di kiri bawah dengan simbol cincin putih, idle pada opacity 55% agar tetap terlihat. Sentuhan menaikkan opacity ke 100% dan membuka tombol bulat redup/berhenti. Setelah tiga detik tanpa interaksi, tombol tambahan menutup dan tombol utama memudar selama 180 ms. Tidak ada animasi berulang atau blur pada video. Pengurangan animasi meniadakan fade. Navigasi aksesibel mempertahankan pilihan tambahan agar tetap dapat dibaca, tetapi opacity tetap turun; fokus keyboard mempertahankan kontrol aktif. Timer dimiliki widget kontrol, dibatalkan saat dispose dan tidak mengubah sesi media.

Revisi 0.6.8 sesuai koreksi pemilik: idle selalu menutup pilihan tambahan setelah tiga detik, termasuk saat layanan aksesibilitas aktif. Opacity idle menjadi 30% agar lebih sedikit menutupi video; saat disentuh atau mendapat fokus, kontrol kembali 100% dan timer dimulai ulang. Ini menggantikan pengecualian idle 0.6.7 di atas. Tooltip, target 56 dp dan pengurangan animasi tetap tersedia. Opacity idle yang lebih rendah merupakan pilihan eksplisit pemilik; kontras penuh dipulihkan saat kontrol aktif.

Revisi 0.6.9: tombol utama dapat diseret. Gerakan menutup menu dan tetap dibatasi inset 12 dp di dalam area aman; menu membuka ke kiri bila ruang di kanan tidak cukup sehingga tombol utama tidak melompat ketika menu dibuka. Setelah sepuluh detik tanpa interaksi pada kontrol, tombol kembali ke kiri bawah dengan transisi 220 ms; tidak memakai transisi saat diseret atau ketika pengurangan animasi aktif. Selama drag, timer dibatalkan dan baru dimulai lagi saat dilepas. Perilaku idle tiga detik tetap berjalan terpisah. Area overlay di luar tombol meneruskan sentuhan ke CarPlay.

Splash 0.4.2+8 mengikuti permintaan pemilik: latar putih murni saat terang dan hitam murni saat gelap, biru dibatasi pada logo yang sudah ada. Animasi logo memakai fade dan skala 92–100% selama 600 ms untuk memperhalus pembukaan, tanpa gerakan berulang atau dependency baru. Pengaturan pengurangan animasi melewati intro. Pembacaan catatan berjalan bersamaan; kegagalan tetap menampilkan pemulihan data. Splash Android paling awal mengikuti tema sistem, lalu splash Flutter mengikuti pilihan tema aplikasi yang tersimpan setelah catatan dibaca.

Brief 0.5: Beranda berfokus pada receiver dan dua pintasan persiapan/pengujian. Seluruh pembacaan info Android ada di Informasi perangkat melalui Pengaturan; model/versi terlihat langsung, konektivitas, daya dan detail teknis dapat diperluas. Tentang aplikasi juga dapat diperluas. Komponen bersama menerapkan arah ini ke tutorial, probe, receiver, formulir, catatan, laporan, dialog dan bottom sheet. Tidak menambah status atau fungsi koneksi.

Animasi 0.5: splash dipersingkat menjadi 320 ms, indikator navigasi 160 ms, fade tab 150 ms, transisi halaman Material 200 ms masuk/160 ms kembali. Tidak ada loop. Reduce motion meniadakan animasi baru. Tema dibangun sekali per ResearchApp, bukan setiap perubahan catatan. Decode logo splash mengikuti ukuran tampil sampai batas 512 px; aset asli dan identitas merek tetap dipertahankan.

0.5.1: pemilik meminta pilihan tema menjadi menu tersendiri dengan kata yang lebih sederhana. Pengaturan → Layar → Tampilan membuka halaman penuh berisi Sesuai perangkat, Terang, dan Gelap. Pilihan tersimpan saat ditekan; perubahan yang gagal tidak mengubah penanda pilihan dan bisa dicoba lagi. Mode redup tetap satu tempat di Pengaturan → Layar. Teks Pengaturan dan penjelasan redup dipersingkat tanpa mengubah fungsi.

0.5.2: pemilik menyederhanakan menu informasi. Pengaturan hanya menyediakan Informasi perangkat yang dibaca dari Android dan Tentang DashTConnect. Catatan, laporan dan formulir inventaris manual dikeluarkan dari UI. Data lama tidak dihapus. Tentang menjadi halaman tersendiri dengan logo, versi, tujuan aplikasi dan status receiver; bukan lagi paragraf panjang dalam accordion. Keduanya bergulir serta mendukung tema terang/gelap dan pembesaran teks.

0.5.3: Informasi perangkat memakai ringkasan model/versi di bagian atas, kartu Koneksi dan Baterai dan daya, serta detail teknis yang dapat diperluas. Pengelompokan ini menggantikan satu accordion besar. Nilai tetap berasal dari API Android lewat gateway yang sama. Waktu baca terakhir tampil terpisah dari nilai perangkat, dan tombol Perbarui membaca ulang tanpa polling atau menyimpan snapshot ke inventaris.
# Perapian informasi perangkat 0.5.4

Detail teknis memakai padding horizontal 20 pada header dan isi agar nilai panjang tetap membungkus dengan rapi. Waktu pembacaan terakhir dan tombol Perbarui disatukan dalam satu kartu; tombol memenuhi lebar kartu dan waktu dapat membungkus saat ukuran teks diperbesar. Bagian identitas, koneksi dan baterai tetap memakai tampilan sebelumnya.

# Splash dan Beranda 0.5.6

Logo splash Flutter berukuran tetap 128 dp, tanpa animasi skala atau perubahan opacity pada logo. Nama aplikasi muncul dengan fade singkat di bawahnya; pada tinggi konten kurang dari 280 dp nama disembunyikan agar tidak terpotong. Splash Android 12+ memakai drawable khusus dengan inset, terpisah dari ikon launcher, untuk menyamakan ukuran logo saat handoff. Latar tetap hitam/putih sesuai tema.

Beranda menggunakan judul “Koneksi ke layar mobil”, penjelasan singkat tindakan receiver, serta satu pintasan Uji tampilan. Tutorial tetap di tab Panduan. Pengingat parkir menjadi satu baris sekunder, tanpa kartu berikon P. Status dan validasi autentikasi receiver tidak diubah.

# Splash dan pengecekan T-Link 0.5.7

Frame Flutter pertama menunggu cache gambar logo selesai disiapkan; splash native tetap menutupi proses decode. Ukuran tetap 128 dp dan fade nama yang singkat dipertahankan, tanpa zoom.

Beranda hanya menampilkan koneksi iPhone. Uji tampilan dipindah ke Panduan → Pengecekan T-Link; tutorial pembukaan pertama tetap dapat membuka tes tersebut. Area tes memiliki empat warna, indikator sentuhan dan ringkasan target yang ditekan, dengan reset selebar kartu. Jumlah target tidak menyatakan tes head unit lulus karena sentuhan HP juga dihitung. Petunjuk ditempatkan setelah area tes. Pada landscape pendek, intro diringkas dan grid memakai empat kolom bila tersedia ruang, agar semua target terlihat tanpa menggulir pada teks normal. Font besar tetap dapat menggulir.

# Antarmuka padat dan splash garis 0.5.8

Splash menggunakan simbol HP dan layar berupa garis biru dengan latar transparan. Android memakai AnimatedVectorDrawable 240 ms, Flutter menggambar bentuk yang sama tanpa bitmap lalu menampilkan nama dengan fade 180 ms. Tidak ada tile biru, zoom, atau penundaan untuk decode gambar; ikon launcher dan header tetap memakai aset sebelumnya.

Beranda menempatkan aksi receiver dan diagram alur koneksi dalam dua panel adaptif. Kalimat “pilih iPhone…” di bawah tombol dihapus. Bantuan koneksi menjadi panel per topik dengan langkah bernomor, bukan paragraf panjang. Bagian Layar memakai dua kontrol rapat dengan keterangan redup sebagai subtitle sakelar. Informasi perangkat dan Tentang memakai satu kelompok ListTile dengan metrik seragam.

Padding konten/kartu serta jarak kolom dikurangi. Intro halaman dan judul tutorial lebih kecil pada landscape pendek; diagram alur memakai ikon 36 dp dan deskripsi 12 sp jika horizontal. Logo/nama pada Tentang menjadi satu baris adaptif. Pilihan tema menjadi tiga kolom jika tersedia lebar 600 dp dan skala teks di bawah 150%; selain itu tetap vertikal. Ukuran sentuh minimum, scroll, pembesaran teks, retensi tab, error dan penyimpanan tema dipertahankan.

# Kartu Panduan seragam 0.5.9

Buka Wi-Fi, Buka Bluetooth dan Uji tampilan memakai ukuran minimum 112 dp yang mengikuti skala teks. Deskripsi diringkas dan ikon dekoratif disembunyikan di atas skala 125% untuk memberi ruang baca. Tinggi tidak dibatasi maksimum agar konten tetap dapat berkembang; kesetaraan tiga kartu diuji pada teks 100%, 150% dan 200%, portrait 320×640 serta landscape 800×360. Warna, lebar, radius dan aksi tetap memakai komponen bersama.

# Kartu ringkas dan pilihan tema 0.5.10

Kartu Panduan menjadi 80 dp pada ukuran teks normal, dengan padding 12 dp dan ikon 40 dp. Di atas 125%, minimum mengikuti 104 dp dikali skala teks agar label yang membungkus tetap terbaca dan ketiga kartu tetap sama tinggi. Tidak ada tinggi maksimum atau pemotongan teks.

Peringatan parkir, batasan receiver, konektivitas dan pengujian memakai AppNotice.warning: ikon segitiga berlabel aksesibilitas, latar amber serta garis tepi. Pesan gagal tetap memakai kartu merah dengan ikon error. Informasi biasa tetap memakai gaya informatif.

Layar memakai judul di luar kelompok kontrol, ikon palet dan kecerahan, serta keterangan redup singkat. Halaman Tampilan menampilkan tiga pilihan dalam kartu tersendiri dengan pratinjau terang, gelap dan gabungan; garis biru dan radio menandai pilihan aktif. Pratinjau dekoratif disembunyikan pada teks di atas 150% untuk memberi ruang baca. Radio tetap mendukung keyboard, penyimpanan asinkron, pencegahan pilihan ganda saat menyimpan, serta retry jika gagal. Landscape memakai tiga kolom pada lebar cukup dan teks normal.

# Landscape dan receiver 0.7.0

Panel berpasangan mengukur tinggi isi lalu memakai tinggi minimum yang sama, tanpa membatasi pertumbuhan teks atau bantuan yang dibuka. Pada lebar di bawah 600 dp atau teks di atas 150%, panel disusun vertikal. Navigasi landscape memakai rail 96 dp yang mengikuti tinggi tiga tujuan, dengan scroll dan lebar tambahan untuk teks besar.

Panduan menempatkan diagram dan tutorial di kiri, tiga aksi koneksi di kanan, serta bantuan selebar konten di bawahnya. Persiapan receiver memakai kartu radio untuk iPhone yang dipasangkan, tombol koneksi utama, dan tindakan Wi-Fi/Bluetooth. Saat menghubungkan, panel status menampilkan nama iPhone dan indikator proses; panel sebelahnya berisi langkah di iPhone dan bantuan jaringan dengan sandi tersembunyi.

Kontrol sesi menempel ke tepi kiri atau kanan terdekat setelah drag dilepas, dengan transisi 220 ms. Idle tiga detik menutup menu dan memudarkan tombol; idle sepuluh detik tetap mengembalikannya ke kiri bawah. Pengurangan animasi dihormati.

# Teks aplikasi 0.7.2

Label eksperimen, peringatan tahap uji dan permintaan membuktikan kompatibilitas dihapus dari Tentang aplikasi, receiver, panduan dan bantuan koneksi. Pesan kegagalan aktual, kebutuhan izin, aturan koneksi lokal dan pengingat parkir tetap tersedia. Perubahan copy tidak mengubah hasil pengujian yang dicatat atau ketentuan distribusi dalam notice sumber.

# Tentang aplikasi 0.7.3

Identitas aplikasi memakai logo 48 dp, nama, versi dan satu deskripsi singkat. Dua panel berikut menampilkan diagram alur koneksi serta tiga ringkasan fitur berikon dengan pemisah: receiver, panduan/uji tampilan, dan mode redup. Panel bertumpuk pada portrait dan berdampingan sama tinggi jika ruang landscape mencukupi. Isi tidak dibuat memenuhi tinggi layar secara paksa; teks besar tetap membungkus dan dapat digulir. Baris fitur bersifat informatif tanpa chevron atau tombol semu.

