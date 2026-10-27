import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_version.dart';
import '../../domain/entities/notebook.dart';
import '../../domain/repositories/device_gateway.dart';
import '../../domain/repositories/receiver_gateway.dart';
import 'device_page.dart';
import 'appearance_page.dart';
import 'display_probe_page.dart';
import 'about_page.dart';
import 'setup_guide_page.dart';
import 'receiver_page.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_navigation.dart';
import '../widgets/app_page_route.dart';

class ResearchHome extends StatefulWidget {
  const ResearchHome({
    super.key,
    required this.notebook,
    required this.bridge,
    required this.receiver,
    required this.save,
  });
  final Notebook notebook;
  final DeviceGateway bridge;
  final ReceiverGateway receiver;
  final Future<void> Function(Notebook) save;

  @override
  State<ResearchHome> createState() => _ResearchHomeState();
}

class _ResearchHomeState extends State<ResearchHome> {
  int _page = 0;
  final _visited = <int>{0};
  bool _dimmed = false, _dimBusy = false;

  void _selectPage(int index) {
    if (_page == index) return;
    setState(() {
      _page = index;
      _visited.add(index);
    });
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openSettings(String section) => widget.bridge.openSettings(
    section == 'wifi' ? DeviceSettings.wifi : DeviceSettings.bluetooth,
  );

  Future<void> _settingsAction(String section) async {
    try {
      await _openSettings(section);
    } catch (_) {
      _message('Pengaturan belum bisa dibuka. Coba lagi.');
    }
  }

  Future<void> _dim() async {
    if (_dimBusy) return;
    setState(() => _dimBusy = true);
    try {
      await widget.bridge.setDimmed(!_dimmed);
      if (mounted) setState(() => _dimmed = !_dimmed);
    } catch (_) {
      _message('Kecerahan belum berubah. Coba lagi saat aplikasi aktif.');
    } finally {
      if (mounted) setState(() => _dimBusy = false);
    }
  }

  Future<void> _openAppearance() => Navigator.of(context).push<void>(
    AppPageRoute(
      builder: (_) => AppearancePage(
        initialTheme: widget.notebook.theme,
        onChanged: (theme) =>
            widget.save(widget.notebook.copyWith(theme: theme)),
      ),
    ),
  );

  Future<void> _openDisplay() => Navigator.of(context).push<void>(
    AppPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Uji tampilan')),
        body: const SafeArea(child: DisplayProbe()),
      ),
    ),
  );

  Future<void> _replayGuide() => Navigator.of(context).push<void>(
    AppPageRoute(
      builder: (context) => SetupGuidePage(
        onComplete: () async => Navigator.pop(context),
        onTestDisplay: _openDisplay,
        onOpenSettings: _openSettings,
      ),
    ),
  );

  Future<void> _openReceiver() => Navigator.of(context).push<void>(
    AppPageRoute(
      builder: (_) => ReceiverPage(
        autoConnect: true,
        receiver: widget.receiver,
        device: widget.bridge,
        initiallyDimmed: _dimmed,
        onDimmedChanged: (value) {
          if (mounted) setState(() => _dimmed = value);
        },
      ),
    ),
  );

  Future<void> _openDevice() => Navigator.of(context).push<void>(
    AppPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Informasi perangkat')),
        body: SafeArea(child: DevicePage(bridge: widget.bridge)),
      ),
    ),
  );

  Future<void> _openAbout() =>
      Navigator.of(context)
          .push<void>(AppPageRoute(builder: (_) => const AboutPage()));

  @override
  void dispose() {
    unawaited(widget.bridge.setDimmed(false).catchError((Object _) {}));
    super.dispose();
  }

  Widget _heading(String text) => Semantics(
    header: true,
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );

  Widget _help(
    String key,
    IconData icon,
    String title,
    List<String> steps, {
    String? warning,
  }) => AppPanel(
    padding: 0,
    child: ExpansionTile(
      key: PageStorageKey(key),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      children: [
        for (var index = 0; index < steps.length; index++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[index],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        if (warning != null) ...[
          const SizedBox(height: 8),
          AppNotice.warning(warning),
        ],
      ],
    ),
  );

  Widget _home() => AppContent(
    key: const PageStorageKey('home'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageIntro(
          'Koneksi ke layar mobil',
          'Kelola koneksi iPhone dan layar mobil dari satu tempat.',
        ),
        const SizedBox(height: 24),
        AdaptiveColumns(
          first: AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading('Receiver iPhone'),
                const SizedBox(height: 8),
                const Text(
                  'Bluetooth menemukan iPhone, Wi-Fi lokal membawa gambar dan audio.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _openReceiver,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Mulai receiver'),
                ),
              ],
            ),
          ),
          second: AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading('Jalur ke head unit'),
                const SizedBox(height: 12),
                const ConnectionRoute(),
                const SizedBox(height: 8),
                Text(
                  'Langkah koneksi dan pengecekan T-Link ada di Panduan.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const AppNotice.warning('Lakukan pengaturan saat mobil terparkir.'),
      ],
    ),
  );

  Widget _guide() => AppContent(
    key: const PageStorageKey('guide'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageIntro(
          'Mulai dari sini',
          'Ikuti alur koneksi, lalu periksa tampilan di layar mobil.',
        ),
        const SizedBox(height: 24),
        AdaptiveColumns(
          first: AppPanel(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading('Alur koneksi'),
                const SizedBox(height: 16),
                const ConnectionRoute(),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _replayGuide,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Buka tutorial'),
                ),
              ],
            ),
          ),
          second: AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading('Koneksi dan tampilan'),
                const SizedBox(height: 12),
                AppActionTile(
                  icon: Icons.wifi,
                  title: 'Buka Wi-Fi',
                  subtitle: 'Wi-Fi lokal.',
                  onTap: () => _settingsAction('wifi'),
                ),
                const SizedBox(height: 12),
                AppActionTile(
                  icon: Icons.bluetooth,
                  title: 'Buka Bluetooth',
                  subtitle: 'Pasangkan iPhone.',
                  onTap: () => _settingsAction('bluetooth'),
                ),
                const SizedBox(height: 12),
                AppActionTile(
                  icon: Icons.touch_app_outlined,
                  title: 'Uji tampilan',
                  subtitle: 'Gambar & sentuhan.',
                  onTap: _openDisplay,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heading('Bantuan koneksi'),
            const SizedBox(height: 12),
            _help(
              'guide-tlink-help',
              Icons.directions_car_outlined,
              'Belum tampil di head unit?',
              const [
                'Gunakan kabel data pada port USB head unit.',
                'Buka T-Link dan izinkan akses di Android.',
                'Jalankan Uji tampilan dari Panduan.',
              ],
              warning: 'Jika gambar belum terlihat, periksa kabel dan kompatibilitas T-Link.',
            ),
            const SizedBox(height: 12),
            _help(
              'guide-receiver-help',
              Icons.phone_iphone,
              'iPhone belum tersambung?',
              const [
                'Pasangkan iPhone melalui Bluetooth Android.',
                'Buka Mulai receiver, izinkan perangkat sekitar, lalu pilih iPhone.',
                'Setujui permintaan CarPlay di iPhone.',
              ],
            ),
            const SizedBox(height: 12),
            _help(
              'guide-dim-help',
              Icons.brightness_low_outlined,
              'Layar redup dan jaringan lokal',
              const [
                'Aktifkan Mode redup di Pengaturan.',
                'Wi-Fi berinternet atau data seluler Android boleh tetap aktif; biarkan Wi-Fi dan Bluetooth menyala.',
                'Internet tetap digunakan di iPhone.',
              ],
            ),
          ],
        ),
      ],
    ),
  );

  Widget _settings() => AppContent(
    key: const PageStorageKey('settings'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageIntro(
          'Pengaturan aplikasi',
          'Atur tampilan aplikasi dan lihat detail perangkat.',
        ),
        const SizedBox(height: 24),
        AdaptiveColumns(
          first: AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading('Layar'),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const IconTile(Icons.palette_outlined),
                      title: const Text('Tampilan'),
                      subtitle: Text(switch (widget.notebook.theme) {
                        'dark' => 'Gelap',
                        'light' => 'Terang',
                        _ => 'Sesuai perangkat',
                      }),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openAppearance,
                    ),
                    const Divider(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      secondary: const IconTile(Icons.brightness_low_outlined),
                      value: _dimmed,
                      title: const Text('Mode redup'),
                      subtitle: const Text('Kurangi kecerahan layar HP.'),
                      onChanged: _dimBusy ? null : (_) => _dim(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mode redup berlaku selama DashTConnect terbuka.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          second: AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading('Informasi'),
                const SizedBox(height: 12),
                Column(
                  children: [
                    ListTile(
                      minTileHeight: 72,
                      contentPadding: EdgeInsets.zero,
                      leading: const IconTile(Icons.devices_outlined),
                      title: const Text('Informasi perangkat'),
                      subtitle: const Text('Model dan sistem Android'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openDevice,
                    ),
                    const Divider(height: 16),
                    ListTile(
                      minTileHeight: 72,
                      contentPadding: EdgeInsets.zero,
                      leading: const IconTile(Icons.info_outline),
                      title: const Text('Tentang DashTConnect'),
                      subtitle: Text('Versi $appVersion'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openAbout,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.notebook.tutorialCompleted) {
      return SetupGuidePage(
        firstRun: true,
        onComplete: () =>
            widget.save(widget.notebook.copyWith(tutorialCompleted: true)),
        onTestDisplay: _openDisplay,
        onOpenSettings: _openSettings,
      );
    }
    final size = MediaQuery.sizeOf(context);
    final rail =
        size.width >= 840 || (size.width >= 600 && size.width > size.height);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/branding/dashtconnect-logo.png',
                width: 34,
                height: 34,
                cacheWidth: 128,
                cacheHeight: 128,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text('DashTConnect', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (rail)
              AppNavigation(
                rail: true,
                selectedIndex: _page,
                onSelected: _selectPage,
              ),
            Expanded(
              child: IndexedStack(
                index: _page,
                children: [
                  for (var index = 0; index < 3; index++)
                    TickerMode(
                      enabled: index == _page,
                      child: !_visited.contains(index)
                          ? const SizedBox.shrink()
                          : switch (index) {
                              0 => _home(),
                              1 => _guide(),
                              _ => _settings(),
                            },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: rail
          ? null
          : AppNavigation(selectedIndex: _page, onSelected: _selectPage),
    );
  }
}
