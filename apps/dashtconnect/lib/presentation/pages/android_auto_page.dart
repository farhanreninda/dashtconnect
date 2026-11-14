import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/android_auto_state.dart';
import '../../domain/repositories/android_auto_gateway.dart';
import '../widgets/app_layout.dart';

class AndroidAutoPage extends StatefulWidget {
  const AndroidAutoPage({
    super.key,
    required this.gateway,
    required this.onGuide,
    this.active = true,
    this.onChooseMode,
  });
  final AndroidAutoGateway gateway;
  final VoidCallback onGuide;
  final bool active;
  final VoidCallback? onChooseMode;
  @override
  State<AndroidAutoPage> createState() => _AndroidAutoPageState();
}

class _AndroidAutoPageState extends State<AndroidAutoPage>
    with WidgetsBindingObserver {
  StreamSubscription<AndroidAutoState>? _subscription;
  AndroidAutoState? _state;
  String? _error, _actionError;
  bool _reading = false, _opening = false, _launching = false;
  int _generation = 0, _eventRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) _listen();
  }

  void _listen() {
    _subscription = widget.gateway.events.listen(
      (value) {
        if (!mounted || !widget.active) return;
        _eventRevision++;
        setState(() {
          _state = value;
          _error = null;
        });
      },
      onError: (Object _) {
        _eventRevision++;
        if (mounted && widget.active) {
          setState(() {
            _state = null;
            _error = 'Persiapan Android Auto belum dapat dibaca.';
          });
        }
      },
    );
    _refresh();
  }

  @override
  void didUpdateWidget(AndroidAutoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    _generation++;
    _reading = false;
    if (widget.active) {
      _listen();
    } else {
      _subscription?.cancel();
      _subscription = null;
      _state = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.active) _refresh();
  }

  Future<void> _refresh() async {
    if (_reading || !widget.active) return;
    final generation = _generation, revision = _eventRevision;
    setState(() {
      _reading = true;
      _error = null;
    });
    try {
      final value = await widget.gateway.refresh();
      if (mounted && generation == _generation && _eventRevision == revision) {
        setState(() => _state = value);
      }
    } catch (_) {
      if (mounted && generation == _generation && _eventRevision == revision) {
        setState(() {
          _state = null;
          _error = 'Persiapan Android Auto belum dapat dibaca.';
        });
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _reading = false);
      }
    }
  }

  Future<void> _settings() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _actionError = null;
    });
    try {
      await widget.gateway.openSettings();
    } catch (_) {
      if (mounted) {
        setState(
          () => _actionError =
              'Pengaturan Android Auto belum dapat dibuka. Coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _session({required bool start}) async {
    if (_launching) return;
    setState(() {
      _launching = true;
      _actionError = null;
    });
    try {
      await (start ? widget.gateway.start() : widget.gateway.stop());
    } catch (_) {
      if (mounted) {
        setState(
          () => _actionError = start
              ? 'Layar Android Auto belum dapat dibuka. Coba lagi.'
              : 'Sesi Android Auto belum dapat dihentikan. Coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String get _title {
    if (_error != null) return 'Persiapan belum terbaca';
    final state = _state;
    if (state == null) return 'Memeriksa perangkat';
    switch (state.session) {
      case AndroidAutoSession.connecting:
        return 'Menghubungkan ke Android Auto';
      case AndroidAutoSession.waitingVideo:
        return 'Terhubung, menunggu gambar';
      case AndroidAutoSession.projecting:
        return 'Android Auto sedang tampil';
      case AndroidAutoSession.failed:
        return 'Sesi Android Auto gagal';
      case AndroidAutoSession.idle:
      case AndroidAutoSession.ended:
        break;
    }
    return switch (state.phase) {
      AndroidAutoPhase.unavailable => 'Layanan Android Auto belum tersedia',
      AndroidAutoPhase.disabled => 'Android Auto dinonaktifkan',
      AndroidAutoPhase.identityMissing => 'Identitas head unit belum dipasang',
      AndroidAutoPhase.ready => 'Siap menjalankan Android Auto',
    };
  }

  String get _nextStep => switch (_state?.phase) {
    AndroidAutoPhase.unavailable =>
      'Pasang atau aktifkan Android Auto di HP ini, lalu periksa ulang.',
    AndroidAutoPhase.disabled =>
      'Aktifkan Android Auto dari pengaturan aplikasi, lalu periksa ulang.',
    AndroidAutoPhase.identityMissing => 'Build ini tidak membawa sertifikat head unit. Isi dashtconnect.androidAutoIdentityDir di local.properties, lalu build ulang APK.',
    AndroidAutoPhase.ready => 'Di Android Auto, buka Setelan developer dan pilih Start head unit server. Setelah itu buka layar Android Auto dari sini, lalu tampilkan HP lewat T-Link.',
    null => 'Status Android Auto sedang dibaca.',
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppContent(
      key: const PageStorageKey('android-auto-home'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageIntro(
            'Satu Android. Tetap lewat T-Link.',
            'Target self-mode: sumber dan receiver pada HP yang sama.',
          ),
          if (widget.onChooseMode != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('choose-connection-mode'),
              onPressed: widget.onChooseMode,
              icon: const Icon(Icons.devices_outlined),
              label: const Text('Pilih mode koneksi'),
            ),
          ],
          const SizedBox(height: 24),
          AdaptiveColumns(
            first: AppPanel(
              tinted: true,
              padding: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(_title, style: text.titleLarge),
                  ),
                  if (_state?.sessionDetail.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    AppNotice(
                      _state!.sessionDetail,
                      error: _state!.session == AndroidAutoSession.failed,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(_nextStep),
                  const SizedBox(height: 20),
                  if (_state?.session.active == true)
                    FilledButton.icon(
                      onPressed: _launching
                          ? null
                          : () => _session(start: false),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Hentikan sesi'),
                    )
                  else if (_state?.phase == AndroidAutoPhase.ready)
                    FilledButton.icon(
                      onPressed: _launching
                          ? null
                          : () => _session(start: true),
                      icon: const Icon(Icons.directions_car_outlined),
                      label: const Text('Buka layar Android Auto'),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _reading ? null : _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Periksa ulang'),
                  ),
                  if (_reading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(),
                    ),
                  TextButton(
                    onPressed: _opening ? null : _settings,
                    child: const Text('Pengaturan Android Auto'),
                  ),
                ],
              ),
            ),
            second: AppPanel(
              padding: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Jalur koneksi', style: text.titleLarge),
                  const SizedBox(height: 12),
                  const Text(
                    'Android Auto di HP ini → receiver internal DashTConnect → tampilan T-Link pada HU.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'HU tetap T-Link. Tidak memerlukan HP kedua atau aplikasi receiver eksternal. T-Link hanya meneruskan gambar dan input, bukan menggantikan protokol Android Auto.',
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: widget.onGuide,
                    icon: const Icon(Icons.route_outlined),
                    label: const Text('Lihat panduan Android Auto'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tahap ini meneruskan gambar dan sentuhan. Suara Android Auto belum diteruskan ke receiver. Mode Apple CarPlay tetap memakai receiver existing.',
            style: text.bodySmall,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            AppNotice(_error!, error: true),
          ],
          if (_actionError != null) ...[
            const SizedBox(height: 12),
            AppNotice(_actionError!, error: true),
          ],
          if (_state?.usbAccessory == true ||
              _state?.usbHostDevice == true) ...[
            const SizedBox(height: 12),
            const AppNotice(
              'Perangkat USB terdeteksi. Ini bukan bukti receiver Android Auto atau koneksi T-Link berhasil.',
            ),
          ],
        ],
      ),
    );
  }
}
