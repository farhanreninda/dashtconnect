import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_version.dart';
import '../../domain/entities/connection_mode.dart';
import '../../domain/repositories/android_auto_gateway.dart';
import 'android_auto_page.dart';
import 'android_auto_guide_page.dart';
import 'carplay_home_page.dart';
import '../widgets/app_brand.dart';
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
    required this.mode,
    required this.androidAuto,
    required this.onChangeMode,
    required this.onBackToHome,
  });
  final Notebook notebook;
  final DeviceGateway bridge;
  final ReceiverGateway receiver;
  final Future<void> Function(Notebook) save;
  final ConnectionMode? mode;
  final AndroidAutoGateway androidAuto;
  final VoidCallback onChangeMode;
  final VoidCallback onBackToHome;

  @override
  State<ResearchHome> createState() => _ResearchHomeState();
}

class _ResearchHomeState extends State<ResearchHome>
    with SingleTickerProviderStateMixin {
  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final _opacity = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
  int _page = 0;
  late ConnectionMode _guideMode = widget.mode ?? ConnectionMode.carPlay;
  final _visited = <int>{0};
  bool _dimmed = false, _dimBusy = false;

  void _selectPage(int index) {
    if (_page == index) return;
    setState(() {
      _page = index;
      _visited.add(index);
    });
    if (!MediaQuery.disableAnimationsOf(context)) _fade.forward(from: 0);
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
    _opacity.dispose();
    _fade.dispose();
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

  Widget _home() => widget.mode == null
      ? _overview()
      : widget.mode == ConnectionMode.carPlay
      ? CarPlayHomePage(
          onStart: _openReceiver,
          onGuide: () => _selectPage(1),
          onChooseMode: widget.onChangeMode,
        )
      : AndroidAutoPage(
          gateway: widget.androidAuto,
          active: _page == 0,
          onGuide: () => _selectPage(1),
          onChooseMode: widget.onChangeMode,
        );

  Widget _overview() => AppContent(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageIntro(
          'Koneksi ke head unit',
          'Siapkan sambungan, periksa layar, dan kelola tampilan dari satu tempat.',
        ),
        const SizedBox(height: 20),
        AdaptiveColumns(
          first: AppPanel(
            tinted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heading('Mulai koneksi'),
                const SizedBox(height: 8),
                const Text(
                  'Pilih Apple CarPlay atau Android Auto. Keduanya menggunakan jalur ke HU T-Link.',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('choose-connection-mode'),
                  onPressed: widget.onChangeMode,
                  icon: const Icon(Icons.devices_outlined),
                  label: const Text('Pilih mode koneksi'),
                ),
              ],
            ),
          ),
          second: AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heading('Alur Apple CarPlay'),
                const SizedBox(height: 16),
                const ConnectionRoute(),
                const Divider(height: 24),
                Text(
                  'Android Auto satu HP: gambar dan sentuhan lewat head unit server, tanpa suara.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _heading('Akses cepat'),
        const SizedBox(height: 12),
        AdaptiveColumns(
          first: AppActionTile(
            icon: Icons.route_outlined,
            title: 'Panduan koneksi',
            subtitle: 'Langkah CarPlay, Android Auto, dan T-Link.',
            onTap: () => _selectPage(1),
          ),
          second: AppActionTile(
            icon: Icons.touch_app_outlined,
            title: 'Uji tampilan T-Link',
            subtitle: 'Periksa gambar dan sentuhan head unit.',
            onTap: _openDisplay,
          ),
        ),
        const SizedBox(height: 20),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _heading('Saat CarPlay tersambung'),
              const SizedBox(height: 8),
              for (final feature in const [
                (
                  Icons.speaker_outlined,
                  'Gambar, suara, dan sentuhan',
                  'Terima tampilan dan audio CarPlay dari iPhone.',
                ),
                (
                  Icons.open_with_rounded,
                  'Kontrol mengambang',
                  'Geser tombol agar tidak menutupi aplikasi.',
                ),
                (
                  Icons.brightness_low_outlined,
                  'Mode redup',
                  'Atur kecerahan HP dari Pengaturan atau kontrol sesi.',
                ),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    feature.$1,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(feature.$2),
                  subtitle: Text(feature.$3),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _guide() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final mode in ConnectionMode.values)
              ChoiceChip(
                label: Text(mode.label),
                selected: _guideMode == mode,
                onSelected: (_) => setState(() => _guideMode = mode),
              ),
          ],
        ),
      ),
      Expanded(
        child: KeyedSubtree(key: ValueKey(_guideMode), child: _guideContent()),
      ),
    ],
  );

  Widget _guideContent() => _guideMode == ConnectionMode.androidAuto
      ? AndroidAutoGuidePage(onTestDisplay: _openDisplay)
      : AppContent(
          key: const PageStorageKey('guide'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageIntro(
                'Panduan Apple CarPlay',
                'Siapkan iPhone, Android, dan tampilan T-Link.',
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
    if (widget.mode == ConnectionMode.carPlay &&
        !widget.notebook.tutorialCompleted) {
      return SetupGuidePage(
        onChangeMode: widget.onChangeMode,
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
    return PopScope(
      canPop: widget.mode == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onBackToHome();
      },
      child: Scaffold(
        appBar: AppBar(
          title: AppBrand(
            key: ValueKey(widget.mode),
            subtitle: widget.mode?.label,
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
                child: FadeTransition(
                  opacity: _opacity,
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
              ),
            ],
          ),
        ),
        bottomNavigationBar: rail
            ? null
            : AppNavigation(selectedIndex: _page, onSelected: _selectPage),
      ),
    );
  }
}
