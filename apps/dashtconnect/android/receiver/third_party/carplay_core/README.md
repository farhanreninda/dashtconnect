# Sumber receiver pihak ketiga

Sumber: [DiPlay / xcertplay](https://github.com/shihabal3amri/DiPlay/tree/143f4674b60b564a16baae5110b3b90fb7277631), commit `143f4674b60b564a16baae5110b3b90fb7277631`. Diambil dari `shared/src/main/java`, bukan aplikasi, launcher atau layar pengaturannya. Source ini dikompilasi sebagai bagian library DashTConnect sendiri.

Komponen xcertplay berlisensi GPL-3.0. `LICENSE` mempertahankan teks upstream. Codec Java Concentus berlisensi BSD; notice-nya juga dipaketkan dalam assets lisensi. Kredit shilapi, kontributor DiPlay, LIVI, Showcase, Logan Stromberg dan kontributor Opus tetap dipertahankan.

`SOURCE_MANIFEST.sha256` berisi hash **sumber upstream sebelum modifikasi**, dengan path relatif terhadap folder ini. `UPSTREAM_COMMIT` menetapkan revisi sumber. Patch lokal saat ini:

- `PairingStore.kt`: sinkronisasi save/get/clear agar sesi RTSP paralel tidak mengakses HashMap bersamaan. Format data dan kontrak publik tetap.
- `WifiP2pGroupManager.kt` dan `P2pNetworkName.kt`: nama jaringan mengikuti merek perangkat, misalnya `DIRECT-Ab-SAMSUNG CARPLAY`. Awalan dan panjang memenuhi batas Android; kepemilikan jaringan tetap diperiksa terhadap nama persis yang dicatat.

Sebagian helper USB, vehicle/telecom dan encoder mikrofon masih merupakan dependensi kelas media upstream; keberadaannya tidak berarti seluruh fitur tersebut diaktifkan. Orkestrator DashTConnect memulai wireless receiver dan menawarkan input mikrofon dengan izin Android untuk sesi CarPlay. Tidak disalin UI AGPL, aset ikon Apple/BYD, native SpeexDSP, server web, cloud auth, private key aksesori atau kunci penandatangan APK.

Tes kriptografi/MFi/media di `src/test/kotlin/com/shilapi/xcertplay` berasal dari revisi upstream yang sama. Tes MFi membuat identitas sintetis sementara; bukan kredensial runtime.
