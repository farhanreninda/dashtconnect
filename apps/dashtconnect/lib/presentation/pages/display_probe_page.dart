import 'package:flutter/material.dart';

import '../widgets/app_layout.dart';

class DisplayProbe extends StatefulWidget {
  const DisplayProbe({super.key});

  @override
  State<DisplayProbe> createState() => _DisplayProbeState();
}

class _DisplayProbeState extends State<DisplayProbe> {
  final _touches = List<int>.filled(4, 0);
  final _colors = const [
    Color(0xFF00347D),
    Color(0xFF0048AB),
    Color(0xFF005BD7),
    Color(0xFF006BFD),
  ];

  @override
  Widget build(BuildContext context) => AppContent(
    key: const Key('display-list'),
    maxWidth: 960,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (MediaQuery.sizeOf(context).height < 480)
          Text(
            'Sentuh target dari layar mobil melalui T-Link.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          const PageIntro(
            'Periksa layar mobil',
            'Tampilkan halaman ini melalui T-Link, lalu tekan target dari layar mobil.',
          ),
        const SizedBox(height: 20),
        AppPanel(
          padding: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tes sentuhan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Semantics(
                liveRegion: true,
                child: Text(
                  '${_touches.where((count) => count > 0).length} dari 4 target disentuh',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
                  final columns = constraints.maxWidth >= 700 && scale < 1.5
                      ? 4
                      : constraints.maxWidth >= 400 || scale < 1.5
                      ? 2
                      : 1;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(
                      4,
                      (index) => SizedBox(
                        width:
                            (constraints.maxWidth - (columns - 1) * 12) /
                            columns,
                        child: Semantics(
                          liveRegion: true,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _colors[index],
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => setState(() => _touches[index]++),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _touches[index] > 0
                                      ? Icons.check_circle_outline
                                      : Icons.touch_app_outlined,
                                  size: 24,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Target ${index + 1}\n${_touches[index]} sentuhan',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() => _touches.fillRange(0, 4, 0)),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Ulangi penghitung'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cara memeriksa',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Pastikan empat warna dan tulisan terlihat jelas di layar mobil.',
              ),
              const SizedBox(height: 16),
              const Text(
                '2. Sentuh setiap target dari head unit. Cocokkan angkanya dengan HP.',
              ),
              const SizedBox(height: 16),
              const Text('3. Tekan Ulangi penghitung untuk memulai lagi.'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              const AppNotice.warning(
                'Sentuhan dari HP juga menambah angka. Penghitung tidak menentukan kelulusan tes.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const AppNotice.warning(
          'Tes ini memeriksa gambar dan sentuhan T-Link, bukan koneksi CarPlay.',
        ),
      ],
    ),
  );
}
