# Receiver Android

Modul library `:receiver` berisi protokol dan media Android. Modul ini tidak memiliki Activity, Compose, UI aplikasi pembanding, pencarian paket, atau ketergantungan pada APK receiver lain.

```text
receiver/
  src/main/kotlin/io/github/farhanreninda/dashtconnect/receiver/
    LocalCarPlayReceiver.kt   # Siklus sesi Bluetooth, Wi-Fi lokal, media, sentuh
    ReceiverIdentity.kt      # Identitas lokal, pairing, pemeriksaan jaringan
    ReceiverResources.kt     # Pelepasan resource saat gagal/batal
  src/main/AndroidManifest.xml
  src/test/kotlin/            # Tes lifecycle, batas input, crypto dan codec
  third_party/carplay_core/   # Source protokol berlisensi terpisah
```

Flutter tetap mengelola tampilan di `lib/presentation`. Host di `android/app` hanya memasang channel dan SurfaceView untuk decoder Android. `:receiver` tidak mengimpor Flutter. Kontrak dan alur lengkap ada di [dokumentasi receiver](../../../../docs/receiver.md).

Autentikasi aksesori tidak disertakan. Build tetap dapat dibuat tanpa identitas; tombol koneksi dinonaktifkan dengan penjelasan. Jangan mengganti identitas dengan sertifikat self-signed fixture tes, karena lulus tes tanda tangan tidak membuktikan iPhone mempercayainya.

Source protokol memakai GPL-3.0. Baca [provenance](third_party/carplay_core/README.md) dan [pemberitahuan lisensi repo](../../../../THIRD_PARTY_NOTICES.md) sebelum mendistribusikan APK gabungan.
