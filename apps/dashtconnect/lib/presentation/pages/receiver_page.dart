import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/receiver_state.dart';
import '../../domain/repositories/device_gateway.dart';
import '../../domain/repositories/receiver_gateway.dart';
import '../widgets/app_layout.dart';
import '../widgets/receiver_controls.dart';

class ReceiverPage extends StatefulWidget {
  const ReceiverPage({
    super.key,
    required this.receiver,
    required this.device,
    this.initiallyDimmed = false,
    this.onDimmedChanged,
    this.autoConnect = false,
  });
  final ReceiverGateway receiver;
  final DeviceGateway device;
  final bool initiallyDimmed;
  final ValueChanged<bool>? onDimmedChanged;
  final bool autoConnect;

  @override
  State<ReceiverPage> createState() => _ReceiverPageState();
}

class _ReceiverPageState extends State<ReceiverPage>
    with WidgetsBindingObserver {
  StreamSubscription<ReceiverEvent>? _subscription;
  ReceiverPreparation? _preparation;
  ReceiverPhase _phase = ReceiverPhase.stopped;
  String? _phoneId, _error;
  String _message = '';
  ReceiverWifi? _localWifi;
  bool _showWifiPassword = false;
  int? _viewId;
  bool _reading = false, _surfaceReady = false, _orientationReady = false;
  late bool _dimmed;
  bool _dimBusy = false;
  bool _autoAttempted = false, _setupBusy = false, _automaticPending = false;
  bool get _running =>
      _phase == ReceiverPhase.connecting || _phase == ReceiverPhase.connected;

  @override
  void initState() {
    super.initState();
    _dimmed = widget.initiallyDimmed;
    WidgetsBinding.instance.addObserver(this);
    _subscription = widget.receiver.events.listen(
      _event,
      onError: (Object _) {
        if (!mounted) return;
        _stop();
        setState(
          () => _error =
              'Status receiver terputus. Periksa ulang sebelum mencoba lagi.',
        );
      },
    );
    _prepareSurface();
    _refresh();
  }

  Future<void> _prepareSurface() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      if (mounted) setState(() => _orientationReady = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Orientasi layar belum dapat disiapkan. Buka kembali receiver.',
        );
      }
    }
  }

  void _event(ReceiverEvent event) {
    if (!mounted || event.viewId != _viewId) return;
    if (event.phase == ReceiverPhase.surfaceReady) {
      setState(() => _surfaceReady = true);
      _maybeAutoConnect();
      _resumeAutomaticStart();
      return;
    }
    if (event.phase == ReceiverPhase.surfaceLost) {
      setState(() => _surfaceReady = false);
      return;
    }
    setState(() {
      _phase = event.phase;
      _message = event.message;
      _error = event.phase == ReceiverPhase.error ? event.message : null;
      if (event.phase == ReceiverPhase.connecting) {
        _localWifi = event.wifi ?? _localWifi;
      } else {
        _localWifi = null;
        _showWifiPassword = false;
      }
    });
    _updateSystemUi();
  }

  void _updateSystemUi() {
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        _phase == ReceiverPhase.connected
            ? SystemUiMode.immersiveSticky
            : SystemUiMode.edgeToEdge,
      ),
    );
  }

  Future<void> _toggleDim() async {
    if (_dimBusy) return;
    setState(() => _dimBusy = true);
    try {
      final next = !_dimmed;
      await widget.device.setDimmed(next);
      widget.onDimmedChanged?.call(next);
      if (mounted) setState(() => _dimmed = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(12, 0, 12, 76),
            content: Text('Kecerahan belum dapat diubah. Coba lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _dimBusy = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _updateSystemUi();
      _resumeAutomaticStart();
    }
    if (state == AppLifecycleState.paused) _stop();
  }

  Future<void> _refresh({bool requestPermissions = false}) async {
    if (_reading || _running) return;
    setState(() {
      _reading = true;
      _error = null;
      _localWifi = null;
      _showWifiPassword = false;
    });
    try {
      final value = await (requestPermissions
          ? widget.receiver.requestPermissions()
          : widget.receiver.preparation());
      if (!mounted) return;
      setState(() {
        _preparation = value;
        if (!value.phones.any((phone) => phone.id == _phoneId)) _phoneId = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Persiapan receiver belum terbaca. Coba periksa ulang.',
        );
      }
    } finally {
      if (mounted) setState(() => _reading = false);
      _maybeAutoConnect();
    }
  }

  void _maybeAutoConnect() {
    if (!mounted ||
        !widget.autoConnect ||
        _autoAttempted ||
        _reading ||
        !_surfaceReady ||
        _preparation?.authenticationAvailable != true) {
      return;
    }
    _autoAttempted = true;
    unawaited(_connectAutomatically());
  }

  Future<void> _connectAutomatically() async {
    if (_reading || _setupBusy || _running) return;
    setState(() {
      _setupBusy = true;
      _reading = true;
      _error = null;
    });
    try {
      final value = await widget.receiver.prepareConnection();
      if (!mounted) return;
      final phone = value.phones.any((phone) => phone.id == _phoneId)
          ? _phoneId
          : value.automaticPhoneId;
      setState(() {
        _preparation = value;
        _phoneId = phone;
        _automaticPending = value.canStart && phone != null;
        _error = !value.canStart
            ? 'Persiapan belum lengkap. Setujui izin serta aktifkan Bluetooth dan Wi-Fi untuk melanjutkan.'
            : value.phones.isEmpty
            ? 'Pasangkan iPhone melalui Bluetooth terlebih dahulu. Setelah dipasangkan, coba hubungkan kembali.'
            : phone == null
            ? 'Ada beberapa perangkat. Pilih iPhone yang ingin dihubungkan.'
            : null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _automaticPending = false;
          _error = error is PlatformException
              ? error.message
              : 'Persiapan otomatis belum berhasil. Coba lagi.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _setupBusy = false;
          _reading = false;
        });
        _resumeAutomaticStart();
      }
    }
  }

  void _resumeAutomaticStart() {
    if (!mounted || _setupBusy || !_automaticPending || !_surfaceReady) return;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return;
    _automaticPending = false;
    unawaited(_start());
  }

  Future<void> _start() async {
    final id = _viewId;
    final phone = _phoneId;
    if (id == null ||
        phone == null ||
        _running ||
        _preparation?.canStart != true) {
      return;
    }
    setState(() {
      _phase = ReceiverPhase.connecting;
      _message = 'Menyiapkan koneksi lokal…';
      _error = null;
      _localWifi = null;
      _showWifiPassword = false;
    });
    try {
      await widget.receiver.start(viewId: id, phoneId: phone);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = ReceiverPhase.error;
        _error = error is PlatformException
            ? error.message
            : 'Receiver belum bisa dimulai. Periksa ulang.';
      });
    }
  }

  Future<void> _stop() async {
    final id = _viewId;
    if (id == null) return;
    try {
      await widget.receiver.stop(id);
      if (mounted) {
        setState(() {
          _phase = ReceiverPhase.stopped;
          _message = 'Receiver dihentikan';
          _localWifi = null;
          _showWifiPassword = false;
        });
        _updateSystemUi();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Receiver belum dapat dihentikan. Tutup halaman ini.',
        );
      }
    }
  }

  Future<void> _settings(DeviceSettings section) async {
    try {
      await widget.device.openSettings(section);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Pengaturan belum dapat dibuka. Coba lagi.');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    if (_viewId case final int id) {
      unawaited(widget.receiver.stop(id).catchError((Object _) {}));
    }
    unawaited(
      SystemChrome.setPreferredOrientations([]).catchError((Object _) {}),
    );
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  Widget _surface() {
    if (defaultTargetPlatform != TargetPlatform.android ||
        kIsWeb ||
        !_orientationReady) {
      return const SizedBox.expand();
    }
    return PlatformViewLink(
      viewType: 'dashtconnect/receiver_surface',
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        gestureRecognizers: {
          Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
        },
      ),
      onCreatePlatformView: (params) {
        _viewId = params.id;
        final controller = PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: 'dashtconnect/receiver_surface',
          layoutDirection: TextDirection.ltr,
          onFocus: () => params.onFocusChanged(true),
        );
        controller.addOnPlatformViewCreatedListener(
          params.onPlatformViewCreated,
        );
        controller.create();
        return controller;
      },
    );
  }

  Widget _preparationView() {
    final ready = _preparation;
    if (_running) {
      final phoneName =
          ready?.phones
              .where((phone) => phone.id == _phoneId)
              .map((phone) => phone.name)
              .firstOrNull ??
          'iPhone';
      return AppContent(
        child: AdaptiveColumns(
          first: AppPanel(
            tinted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Menghubungkan iPhone',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2.5),
                          Icon(Icons.phone_iphone_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            phoneName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Text('Bluetooth dan Wi-Fi lokal'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _message,
                    semanticsLabel: 'Status koneksi: $_message',
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _stop,
                  icon: const Icon(Icons.close),
                  label: const Text('Batalkan koneksi'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  AppNotice(_error!, error: true),
                ],
              ],
            ),
          ),
          second: AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lock_open_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Di iPhone',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Biarkan iPhone terbuka dan berada dekat Android. Jika muncul permintaan CarPlay, setujui untuk melanjutkan.',
                ),
                const SizedBox(height: 8),
                Text(
                  'Internet tetap menggunakan koneksi iPhone.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (_localWifi case final wifi?) ...[
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('iPhone belum masuk Wi-Fi?'),
                    children: [
                      const Text(
                        'Di iPhone, buka Pengaturan → Wi-Fi lalu pilih jaringan berikut. Jaringan ini hanya untuk koneksi lokal.',
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        wifi.ssid,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_showWifiPassword) SelectableText(wifi.passphrase),
                      TextButton.icon(
                        onPressed: () => setState(
                          () => _showWifiPassword = !_showWifiPassword,
                        ),
                        icon: Icon(
                          _showWifiPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        label: Text(
                          _showWifiPassword
                              ? 'Sembunyikan sandi'
                              : 'Tampilkan sandi',
                        ),
                      ),
                      const Text(
                        'Setelah tersambung, kembali ke sini. Internet iPhone tetap melalui data seluler.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return AppContent(
      child: AdaptiveColumns(
        first: AppPanel(
          tinted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageIntro(
                'Koneksi lokal, langsung dari iPhone',
                'Android menerima gambar dan suara CarPlay. Internet tetap menggunakan koneksi iPhone.',
              ),
              const SizedBox(height: 16),
              const ConnectionRoute(),
              const SizedBox(height: 12),
              const AppNotice(
                'Biarkan Wi-Fi dan Bluetooth aktif. Wi-Fi berinternet atau data seluler Android tidak perlu diputus sebelum menghubungkan iPhone.',
              ),
              const SizedBox(height: 12),
              if (_reading) ...[
                const LinearProgressIndicator(
                  semanticsLabel: 'Memeriksa kesiapan receiver',
                ),
                const SizedBox(height: 16),
              ],
              if (ready != null) ...[
                if (!ready.authenticationAvailable) ...[
                  const AppNotice.warning(
                    'Receiver belum siap pada build ini. Autentikasi aksesori belum disiapkan.',
                  ),
                  const SizedBox(height: 12),
                ],
                if (!ready.bluetoothEnabled)
                  const AppNotice.warning(
                    'Bluetooth belum aktif atau izinnya belum diberikan.',
                  ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                AppNotice(_error!, error: true),
              ],
            ],
          ),
        ),
        second: AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih iPhone',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'iPhone terakhir atau satu-satunya ponsel yang dipasangkan dapat dihubungkan otomatis. Jika ada beberapa, pilih perangkat di bawah.',
              ),
              const SizedBox(height: 12),
              if (ready != null) ...[
                if (ready.missingPermissions.isNotEmpty) ...[
                  const Text(
                    'Receiver memerlukan akses perangkat sekitar dan mikrofon '
                    'untuk audio CarPlay. Mikrofon digunakan saat iPhone '
                    'meminta masukan suara dalam sesi aktif.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _reading
                        ? null
                        : () => _refresh(requestPermissions: true),
                    child: const Text('Berikan izin receiver'),
                  ),
                  const SizedBox(height: 16),
                ],
                RadioGroup<String>(
                  groupValue: _phoneId,
                  onChanged: (id) {
                    if (!_reading) setState(() => _phoneId = id);
                  },
                  child: Column(
                    children: [
                      for (final phone in ready.phones) ...[
                        RadioListTile<String>(
                          value: phone.id,
                          enabled: !_reading,
                          title: Text(phone.name),
                          subtitle: const Text('Perangkat dipasangkan'),
                          secondary:
                              MediaQuery.textScalerOf(context).scale(16) <= 24
                              ? const IconTile(Icons.phone_iphone)
                              : null,
                          controlAffinity: ListTileControlAffinity.trailing,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          selected: _phoneId == phone.id,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _phoneId == phone.id
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
                if (ready.phones.isEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Belum ada iPhone. Pasangkan melalui pengaturan Bluetooth Android, lalu periksa ulang.',
                  ),
                ],
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed:
                    !_reading &&
                        _surfaceReady &&
                        ready?.authenticationAvailable == true
                    ? ready?.canStart == true && _phoneId != null
                          ? _start
                          : _connectAutomatically
                    : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Hubungkan iPhone'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _reading
                        ? null
                        : () => _settings(DeviceSettings.bluetooth),
                    child: const Text('Buka Bluetooth'),
                  ),
                  OutlinedButton(
                    onPressed: _reading
                        ? null
                        : () => _settings(DeviceSettings.wifi),
                    child: const Text('Buka Wi-Fi'),
                  ),
                  TextButton(
                    onPressed: _reading ? null : _refresh,
                    child: const Text('Periksa ulang'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _phase == ReceiverPhase.connected
        ? null
        : AppBar(
            title: Text(
              _phase == ReceiverPhase.connected
                  ? 'CarPlay terhubung'
                  : 'Receiver iPhone',
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (_running)
                IconButton(
                  tooltip: 'Hentikan receiver',
                  onPressed: _stop,
                  icon: const Icon(Icons.stop_circle_outlined),
                ),
            ],
          ),
    body: SafeArea(
      top: false,
      bottom: _phase != ReceiverPhase.connected,
      left: _phase != ReceiverPhase.connected,
      right: _phase != ReceiverPhase.connected,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: Colors.black, child: _surface()),
          ),
          if (_phase != ReceiverPhase.connected)
            Positioned.fill(
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: _preparationView(),
              ),
            ),
          if (_phase == ReceiverPhase.connected)
            Positioned.fill(
              child: SafeArea(
                top: false,
                child: Semantics(
                  label: 'CarPlay terhubung',
                  child: ReceiverControls(
                    dimmed: _dimmed,
                    busy: _dimBusy,
                    onToggleDim: _toggleDim,
                    onStop: _stop,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
