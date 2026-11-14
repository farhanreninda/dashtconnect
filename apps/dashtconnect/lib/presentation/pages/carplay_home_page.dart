import 'package:flutter/material.dart';

import '../widgets/app_layout.dart';

class CarPlayHomePage extends StatelessWidget {
  const CarPlayHomePage({
    super.key,
    required this.onStart,
    required this.onGuide,
    required this.onChooseMode,
  });
  final VoidCallback onStart, onGuide, onChooseMode;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final compact = MediaQuery.sizeOf(context).height < 480;
    return AppContent(
      key: const PageStorageKey('home'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageIntro(
            'iPhone Anda. Head unit Anda.',
            'Terima CarPlay di Android dan teruskan melalui T-Link.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('choose-connection-mode'),
            onPressed: onChooseMode,
            icon: const Icon(Icons.devices_outlined),
            label: const Text('Pilih mode koneksi'),
          ),
          SizedBox(height: compact ? 16 : 24),
          AdaptiveColumns(
            first: AppPanel(
              tinted: true,
              padding: compact ? 16 : 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!compact) ...[
                    const Icon(Icons.phone_iphone, size: 42),
                    const SizedBox(height: 20),
                  ],
                  Text('Receiver iPhone', style: text.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    compact
                        ? 'Siapkan iPhone di dekat Android. Izin dan sambungan diperiksa saat mulai.'
                        : 'Siapkan iPhone di dekat Android. Aplikasi menyiapkan izin dan mencoba perangkat yang sudah dipasangkan.',
                  ),
                  SizedBox(height: compact ? 16 : 24),
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Mulai receiver'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status diperiksa saat receiver dibuka.',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            second: AppPanel(
              padding: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Jalur ke head unit', style: text.titleLarge),
                  const SizedBox(height: 16),
                  const ConnectionRoute(),
                  const SizedBox(height: 16),
                  const Text(
                    'Bluetooth menyiapkan sambungan. Wi-Fi lokal membawa gambar, suara, dan kontrol sentuh.',
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onGuide,
                    icon: const Icon(Icons.route_outlined),
                    label: const Text('Lihat panduan CarPlay'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Lakukan pengaturan saat mobil terparkir. Wi-Fi internet Android boleh tetap aktif.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
