# Pemberitahuan komponen pihak ketiga

`LICENSE` di akar repo tetap mencakup kode asli DashTConnect di bawah MIT. Kode receiver tambahan memiliki lisensi tersendiri. APK yang menggabungkan receiver GPL bukan paket yang seluruhnya berlisensi MIT.

| Komponen | Sumber | Lisensi |
| --- | --- | --- |
| xcertplay dan perubahan receiver DiPlay | [Revisi sumber yang dipakai](https://github.com/shihabal3amri/DiPlay/tree/143f4674b60b564a16baae5110b3b90fb7277631) | GPL-3.0, teks di `apps/dashtconnect/android/receiver/third_party/carplay_core/LICENSE` |
| Concentus / Opus Java | Source dalam komponen upstream, beserta README dan header asli | BSD, teks dipaketkan sebagai `licenses/carplay-core-Opus.txt` |
| Bouncy Castle 1.79 | [Bouncy Castle](https://www.bouncycastle.org/) | Bouncy Castle license |
| JmDNS 3.6.3 | [JmDNS](https://github.com/jmdns/jmdns) | Apache-2.0 |
| SLF4J, dependensi JmDNS | [SLF4J](https://www.slf4j.org/) | MIT |
| Kotlin / AndroidX | Artefak Gradle yang dicatat dalam modul Android | Apache-2.0 |
| Flutter / Dart | SDK dan engine Flutter | Lisensi dalam distribusi SDK serta notice Flutter |
| Space Grotesk / Inter | [Google Fonts](https://github.com/google/fonts), provenance/checksum dalam `assets/fonts/SOURCES.json` | SIL OFL 1.1, teks lisensi dalam assets font APK |

Source, perubahan, konfigurasi build dan notice receiver dipertahankan dalam repo. Distribusi APK gabungan harus memenuhi ketentuan GPL-3.0 yang berlaku, termasuk penyediaan corresponding source dan notice yang sesuai. File lisensi sumber protokol juga dipaketkan dalam assets APK. Perubahan lokal belum dipublikasikan; jangan menganggap adanya file ini sebagai bukti kewajiban distribusi sudah selesai.

UI/website upstream AGPL dan ikon Apple/BYD tidak dimasukkan. Source repo tidak menyertakan data autentikasi. Build uji pribadi 0.6.0 menyertakan identitas eksperimen dari assets release publik [DiPlay 0.2.21](https://github.com/shihabal3amri/DiPlay/releases/tag/v0.2.21), yang oleh upstream dinyatakan berasal dari firmware Carlinkit publik. SHA-256 APK sumber: `916c0708beb1022d4ea9678ff6a46dfb6d234f707837a2cbd80d615e8e2bb2e3`. Aset disimpan lokal di luar Git, tanpa memasang atau membuka aplikasi sumber.

Identitas aksesori bukan bagian source terbuka tersebut dan tidak otomatis mendapat lisensi ulang. Penerimaan oleh iPhone, kompatibilitas versi iOS, dan kelayakan distribusi umum belum dipastikan. Kunci yang dibundel dapat diekstrak dari APK; jangan memakai APK uji pribadi ini sebagai paket publikasi. Tidak ada afiliasi atau sertifikasi Apple/Toyota/BYD yang diklaim.
