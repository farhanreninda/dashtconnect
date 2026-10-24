# DashTConnect website

Landing page statis berbahasa Indonesia dengan Astro, TypeScript, dan CSS. Source website terpisah dari Flutter/Android. Screenshot asli dari pemilik proyek tersimpan di `src/assets/screenshots`; checksum dan sumbernya dicatat dalam `SOURCES.json`.

## Menjalankan lokal

Memerlukan Node.js 24 dan npm.

```sh
cd website
npm ci
npm run dev
```

Buka `http://localhost:4321/dashtconnect/`. Untuk memeriksa paket produksi:

```sh
npm run build
npx playwright install chromium
npm test
npm run preview
```

Build berada di `website/dist`. Tes browser menggunakan server preview pada port 4321 dan memeriksa aset dengan base path produksi, bukan hanya development server.

## GitHub Pages

Tujuan publikasi: **https://farhanreninda.my.id/dashtconnect/**.

1. Repository proyek harus tetap bernama `dashtconnect`.
2. Pertahankan custom domain `farhanreninda.my.id` pada user site `farhanreninda.github.io`. Project Pages mengikuti domain user site tersebut dengan path nama repository. Tidak perlu menambah DNS untuk `/dashtconnect/`.
3. Pada repo `dashtconnect`, buka **Settings → Pages → Build and deployment → Source → GitHub Actions**. Jangan mengisi Custom domain pada repo proyek ini dan jangan menambahkan `CNAME` pada website.
4. Setelah perubahan website ditinjau, commit/push folder `website` dan `.github/workflows/deploy-website.yml` ke `main`. Workflow membangun dan menguji website sebelum mengunggah hanya `website/dist` ke Pages.
5. Workflow juga dapat dijalankan dari **Actions → DashTConnect website → Run workflow** pada branch `main`. PR hanya membangun dan menguji; PR tidak melakukan deployment.

Workflow berjalan pada perubahan website atau file workflow. Perubahan Android tidak memicu deployment website. Folder build, cache, dependensi, hasil tes, serta `.local-tools` tidak menjadi artefak Pages. Build web tidak membaca aset autentikasi Android dan tidak menyertakan APK.

Konfigurasi `site` dan `base` ada di `astro.config.mjs`. Aset, font, canonical, Open Graph, sitemap, dan halaman 404 memakai path proyek yang sama. Rujukan: [Astro GitHub Pages](https://docs.astro.build/en/guides/deploy/github/) dan [domain user site serta project site](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/about-custom-domains-and-github-pages).

## Konten dan aset

- `src/pages/index.astro`: konten, galeri dan metadata halaman.
- `src/styles/global.css`: tampilan responsive, focus, serta reduced motion.
- `src/scripts/interactions.ts`: menu HP, tema web tersimpan, animasi masuk halus, dan dialog screenshot dengan loading/error state.
- `src/assets/screenshots/SOURCES.json`: asal dan SHA-256 screenshot yang dikirim pemilik. Screenshot asli dari kiriman pemilik ditampilkan, termasuk dashboard dan peta CarPlay; gambar duplikat tidak diulang.
- `public/fonts`: font aplikasi dalam WOFF2 beserta lisensi SIL OFL dan checksum. Konversi format mempertahankan seluruh glyph; tidak memakai font eksternal.

Astro menghasilkan salinan WebP dengan berbagai ukuran. File screenshot sumber tetap utuh. Screenshot tersedia dalam galeri tanpa tab atau tombol pembuka; hanya foto dengan tema yang cocok ditampilkan. Galeri fitur, detail sesi, dan tutorial digeser horizontal dengan scroll native/gestur, keyboard, atau tombol panah. Tidak ada autoplay. Portrait dan landscape dikelompokkan sesuai halaman aplikasi. Tombol tema memakai ikon saja dengan nama aksesibel. Gambar tetap dimuat secara lazy saat mendekati viewport agar halaman panjang tidak mengunduh seluruh aset sekaligus. Tema web mengikuti perangkat saat pertama dibuka; tombol tema menyimpan pilihan terang/gelap di localStorage. Label versi screenshot tetap 0.7.3 sesuai aplikasi yang ditampilkan; perbarui bersama screenshot ketika mengganti versi.

Tombol proyek mengarah ke repository GitHub yang sudah ada. Unduhan APK tidak ditawarkan karena belum ada rilis publik. Screenshot menunjukkan sesi di Samsung A04s dengan iPhone 11 dan tidak menjadi klaim bahwa setiap head unit mendukung jalur yang sama. Tidak menambahkan klaim Siri, panggilan, penghematan suhu, bebas lag, atau sertifikasi Apple.

Publikasi website belum dijalankan dari workspace. Jangan commit seluruh workspace hanya untuk menerbitkan landing page: source Android dan aset lokal memiliki cakupan/lisensi yang terpisah; pilih file website serta workflow secara eksplisit.

Screenshot tema terang berada di `src/assets/screenshots/light` (17 file kiriman asli). Pasangan gambar dipilih mengikuti tema web lewat elemen picture, dan dialog zoom memakai versi yang sama. Ada 30 posisi gambar: pasangan terang/gelap dan tambahan yang ditampilkan sesuai tema sumber. Screenshot tanpa pasangan hanya muncul di tema aslinya. CarPlay terang hanya di light, sedangkan hero dark memakai foto Google Maps gelap asli kiriman pemilik. Foto tutorial tersedia di dark; empat penjelasan langkah tetap muncul pada kedua tema. Tidak membalik warna atau membuat ulang foto.
