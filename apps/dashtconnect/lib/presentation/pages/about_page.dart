import 'package:flutter/material.dart';

import '../../core/app_version.dart';
import '../widgets/app_layout.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Widget _feature(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 36, height: 36, child: IconTile(icon)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tentang aplikasi')),
    body: SafeArea(
      child: AppContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/branding/dashtconnect-logo.png',
                          width: 48,
                          height: 48,
                          cacheWidth: 144,
                          excludeFromSemantics: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DashTConnect',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Versi $appVersion',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Receiver CarPlay di Android untuk menghubungkan iPhone ke layar mobil melalui T-Link.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdaptiveColumns(
              first: AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Alur koneksi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    const ConnectionRoute(),
                    const SizedBox(height: 12),
                    Text(
                      'Internet tetap di iPhone. Android menggunakan koneksi lokal.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              second: AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Fitur aplikasi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    _feature(
                      context,
                      Icons.phone_iphone_outlined,
                      'Receiver CarPlay',
                      'Gambar, audio, dan kontrol sentuh CarPlay.',
                    ),
                    const Divider(height: 1),
                    _feature(
                      context,
                      Icons.route_outlined,
                      'Panduan & uji tampilan',
                      'Langkah koneksi dan pengecekan layar T-Link.',
                    ),
                    const Divider(height: 1),
                    _feature(
                      context,
                      Icons.brightness_low_outlined,
                      'Mode redup',
                      'Atur kecerahan layar HP saat terhubung.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
