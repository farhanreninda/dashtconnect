import 'package:flutter/material.dart';

import '../widgets/app_layout.dart';

class SetupGuidePage extends StatefulWidget {
  const SetupGuidePage({
    required this.onComplete,
    required this.onTestDisplay,
    required this.onOpenSettings,
    this.firstRun = false,
    super.key,
  });

  final Future<void> Function() onComplete;
  final VoidCallback onTestDisplay;
  final Future<void> Function(String section) onOpenSettings;
  final bool firstRun;

  @override
  State<SetupGuidePage> createState() => _SetupGuidePageState();
}

class _SetupGuidePageState extends State<SetupGuidePage> {
  final _scrollController = ScrollController();
  var _step = 0;
  var _working = false;
  String? _error;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() {
      _step = step;
      _error = null;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Future<void> _run(Future<void> Function() action, String error) async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _complete() => _run(
    widget.onComplete,
    'Panduan belum tersimpan. Coba lagi melalui tombol yang sama.',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titles = [
      'Kenali alur koneksi',
      'Siapkan Android',
      'Hubungkan ke T-Link',
      'Hubungkan tanpa memutus Wi-Fi',
    ];
    return PopScope(
      canPop: !_working,
      child: Scaffold(
        appBar: AppBar(title: const Text('Panduan')),
        body: SafeArea(
          top: false,
          child: AppContent(
            controller: _scrollController,
            child: AdaptiveColumns(
              first: AppPanel(
                tinted: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        'Langkah ${_step + 1} dari 4',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (var i = 0; i < 4; i++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: i == 3 ? 0 : 6),
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: i <= _step
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      header: true,
                      child: Text(
                        titles[_step],
                        style: MediaQuery.sizeOf(context).height < 480
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const AppNotice.warning(
                      'Ikuti panduan saat mobil terparkir. Anda bisa membukanya kembali kapan saja.',
                    ),
                  ],
                ),
              ),
              second: AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._content(theme),
                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      AppNotice(_error!, error: true),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('guide-next'),
                      onPressed: _working
                          ? null
                          : _step == 3
                          ? _complete
                          : () => _goTo(_step + 1),
                      child: Text(
                        _working
                            ? 'Memproses…'
                            : _step == 3
                            ? 'Selesai'
                            : 'Lanjut',
                      ),
                    ),
                    if (_step > 0) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _working ? null : () => _goTo(_step - 1),
                        child: const Text('Sebelumnya'),
                      ),
                    ],
                    if (widget.firstRun) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _working ? null : _complete,
                        child: const Text('Nanti saja'),
                      ),
                      Text(
                        'Panduan dapat dibuka lagi dari menu Panduan.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(ThemeData theme) => switch (_step) {
    0 => [
      const Text(
        'DashTConnect menyiapkan jalur iPhone ke Android, lalu ke layar mobil.',
      ),
      const SizedBox(height: 20),
      const ConnectionRoute(),
      const SizedBox(height: 12),
      const Text(
        'Mulai dengan menguji tampilan Android di T-Link saat mobil parkir.',
      ),
    ],
    1 => [
      const Text(
        'Buka pengaturan untuk menyiapkan Wi-Fi dan Bluetooth Android. '
        'Kembali ke aplikasi setelah selesai.',
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: _working
            ? null
            : () => _run(
                () => widget.onOpenSettings('wifi'),
                'Pengaturan Wi-Fi tidak bisa dibuka. Coba lagi.',
              ),
        icon: const Icon(Icons.wifi),
        label: const Text('Buka Wi-Fi'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _working
            ? null
            : () => _run(
                () => widget.onOpenSettings('bluetooth'),
                'Pengaturan Bluetooth tidak bisa dibuka. Coba lagi.',
              ),
        icon: const Icon(Icons.bluetooth),
        label: const Text('Buka Bluetooth'),
      ),
      const SizedBox(height: 20),
      const Text('Pasangkan iPhone melalui pengaturan Bluetooth Android.'),
      const SizedBox(height: 12),
      const AppNotice.warning(
        'Wi-Fi atau Bluetooth aktif saja belum berarti iPhone terhubung.',
      ),
    ],
    2 => [
      const Text(
        'Saat parkir, sambungkan Android ke port USB head unit dengan kabel data. '
        'Buka T-Link di head unit dan ikuti petunjuknya.',
      ),
      const SizedBox(height: 20),
      FilledButton.tonalIcon(
        onPressed: _working ? null : widget.onTestDisplay,
        icon: const Icon(Icons.touch_app_outlined),
        label: const Text('Buka uji layar'),
      ),
      const SizedBox(height: 20),
      const Text(
        'Periksa gambar dan tekan target dari layar mobil. '
        'Jika belum tampil, periksa kabel dan petunjuk T-Link.',
      ),
    ],
    _ => [
      const Text(
        'Target koneksi: iPhone ke DashTConnect, lalu ke layar mobil melalui T-Link. '
        'Internet tetap digunakan di iPhone.',
      ),
      const SizedBox(height: 20),
      const AppNotice(
        'Wi-Fi berinternet dan data seluler Android boleh tetap aktif. '
        'Biarkan Wi-Fi dan Bluetooth menyala; aplikasi menyiapkan koneksi lokal ke iPhone. '
        'Dukungan Wi-Fi bersamaan mengikuti kemampuan perangkat.',
      ),
      const SizedBox(height: 20),
      Text('Fungsi yang tersedia', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      const Text(
        'Dari Beranda, buka Mulai receiver, izinkan perangkat sekitar, pilih iPhone, lalu Hubungkan iPhone. '
        'Setujui permintaan CarPlay di iPhone.',
      ),
    ],
  };
}
