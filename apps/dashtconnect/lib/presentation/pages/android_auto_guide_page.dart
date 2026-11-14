import 'package:flutter/material.dart';

import '../widgets/app_layout.dart';

class AndroidAutoGuidePage extends StatelessWidget {
  const AndroidAutoGuidePage({super.key, required this.onTestDisplay});
  final VoidCallback onTestDisplay;
  @override
  Widget build(BuildContext context) => AppContent(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageIntro(
          'Panduan Android Auto',
          'Satu HP Android dan HU T-Link, dengan receiver di dalam DashTConnect.',
        ),
        const SizedBox(height: 24),
        AdaptiveColumns(
          first: _section(context, 'Persiapan sekali', const [
            'Buka Android Auto di HP, ketuk versi aplikasi berkali-kali sampai Setelan developer aktif.',
            'Build DashTConnect harus membawa sertifikat head unit. Tanpa itu halaman Android Auto menampilkan Identitas head unit belum dipasang.',
            'Uji gambar dan input T-Link saat parkir menggunakan halaman uji tampilan di bawah.',
          ]),
          second: _section(context, 'Setiap kali menyambung', const [
            'Di Android Auto, buka menu Setelan developer lalu pilih Start head unit server.',
            'Di DashTConnect: Beranda → Pilih mode koneksi → Android Auto → Buka layar Android Auto.',
            'Sambungkan HP ke HU lewat T-Link. Layar Android Auto yang tampil di HP diteruskan ke HU, dan sentuhan dari HU kembali ke layar ini.',
          ]),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onTestDisplay,
          icon: const Icon(Icons.touch_app_outlined),
          label: const Text('Uji tampilan T-Link'),
        ),
        const SizedBox(height: 20),
        _section(context, 'Batas sesi dan troubleshooting', const [
          'Status Android Auto sedang tampil baru muncul setelah frame video pertama terdekode. Kabel terpasang saja tidak membuktikan apa pun.',
          'Head unit server belum berjalan berarti langkah Start head unit server belum dilakukan, atau Android Auto menghentikannya. Jalankan lagi lalu buka ulang layar Android Auto.',
          'Tombol kembali atau Hentikan sesi menutup sesi. Suara Android Auto belum diteruskan ke receiver pada tahap ini.',
        ]),
      ],
    ),
  );
  Widget _section(BuildContext context, String title, List<String> steps) =>
      AppPanel(
        padding: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final step in steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(step),
              ),
          ],
        ),
      );
}
