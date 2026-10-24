# DashTConnect

DashTConnect dikembangkan sebagai aplikasi Android mandiri untuk menerima sesi iPhone dan meneruskannya ke layar mobil melalui T-Link. Targetnya, internet tetap digunakan di iPhone dan Android hanya memakai koneksi lokal tanpa akses internet.

## Beranda

Tombol Mulai receiver membuka persiapan sambungan langsung ke iPhone. Aplikasi memeriksa izin perangkat sekitar, Bluetooth, daftar iPhone yang sudah dipasangkan, jaringan Android dan kesiapan autentikasi aksesori. Beranda berfokus pada koneksi iPhone; tutorial dan pengecekan T-Link tersedia di tab Panduan.

## Receiver iPhone

Mesin receiver eksperimental berada di dalam DashTConnect. Bluetooth menyiapkan sesi dan Wi-Fi lokal membawa gambar serta audio dari iPhone. Status terhubung memerlukan sesi runtime dan gambar yang benar-benar dirender. Pengguna dapat menghentikan receiver; sesi juga dihentikan saat aplikasi masuk ke background atau jaringan berkemampuan internet terdeteksi di Android.

Saat tersambung, CarPlay memakai layar penuh dengan rasio yang mengikuti layar Android. Pintasan di kiri bawah menyediakan redup/pulihkan kecerahan dan kontrol untuk menghentikan sesi. Tombol dapat digeser agar tidak menutupi kontrol CarPlay, lalu kembali ke posisi awal setelah sepuluh detik tanpa interaksi.

Bantuan Wi-Fi pada layar koneksi menampilkan nama jaringan sementara dan menyediakan tombol untuk melihat sandi jika iPhone belum bergabung otomatis. Sandi tidak disimpan dan dihapus dari tampilan setelah percobaan berakhir.

## Panduan awal

Empat langkah membantu mengenali alur koneksi, menyiapkan Android, memeriksa tampilan T-Link dan menyiapkan Android tanpa internet. Panduan muncul saat pertama kali dibuka, dapat dilewati dan bisa diulang melalui menu Panduan. Tombol Wi-Fi dan Bluetooth membuka pengaturan Android langsung dari menu ini.

## Uji tampilan dan sentuhan

Halaman uji layar penuh menyediakan empat target berwarna dengan penghitung sentuhan. Pengguna dapat membandingkan gambar HP dan head unit, menekan target melalui layar mobil lalu mengulang penghitung untuk percobaan berikutnya.

## Pengaturan dan informasi

Pengaturan mengumpulkan pilihan tampilan, mode redup, informasi perangkat dan Tentang DashTConnect. Informasi perangkat dibaca langsung dari Android yang digunakan, mencakup model, versi sistem, jaringan aktif, suhu baterai dan sambungan daya. Halaman ini hanya menampilkan informasi, tanpa formulir isian iPhone atau head unit.

## Tema terang dan gelap

Tampilan menggunakan warna utama biru, panel terang/slate dan tipografi yang konsisten. Halaman Tampilan menyediakan pilihan Sesuai perangkat, Terang dan Gelap yang tersimpan saat aplikasi dibuka kembali. Navigasi Beranda, Panduan dan Pengaturan berpindah ke sisi layar pada landscape. Halaman tetap dapat digulir dan mendukung pembesaran teks.

## Mode redup

Menurunkan kecerahan jendela DashTConnect menjadi 3% dan menjaga layar tetap menyala selama aplikasi berada di depan. Kecerahan dapat dipulihkan melalui kontrol yang tersedia. Kelanjutan gambar T-Link dan pengaruhnya terhadap suhu masih memerlukan pengujian.

## Tentang DashTConnect

Halaman Tentang menampilkan identitas aplikasi, versi terpasang, tujuan pengembangan dan status receiver secara ringkas.

## Kemampuan saat ini

Gambar, sentuhan dan suara musik CarPlay telah berhasil diuji dari iPhone 11 ke Samsung A04s melalui Wi-Fi lokal 2,4 GHz. Android memakai koneksi lokal dengan data seluler mati; internet tetap dari iPhone. Build uji pribadi memakai autentikasi eksperimen. Receiver memerlukan izin mikrofon agar iPhone mengenali jalur audio dengan lengkap. Siri, panggilan, output T-Link, kestabilan jangka panjang, layar sepenuhnya mati dan pengaruhnya terhadap panas masih memerlukan pengujian perangkat.
