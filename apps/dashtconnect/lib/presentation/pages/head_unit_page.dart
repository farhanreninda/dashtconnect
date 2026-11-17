import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/receiver_state.dart';
import '../../domain/repositories/receiver_gateway.dart';
import '../widgets/app_layout.dart';

/// Step 1 of 2: show DashTConnect on the head unit over USB before CarPlay starts.
class HeadUnitPage extends StatefulWidget {
  const HeadUnitPage({
    super.key,
    required this.receiver,
    required this.onContinue,
    this.pollInterval = const Duration(seconds: 2),
  });
  final ReceiverGateway receiver;
  final VoidCallback onContinue;
  final Duration pollInterval;

  @override
  State<HeadUnitPage> createState() => _HeadUnitPageState();
}

class _HeadUnitPageState extends State<HeadUnitPage>
    with WidgetsBindingObserver {
  HeadUnitStatus? _status;
  String? _error;
  bool _reading = false, _connecting = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _poll = Timer.periodic(widget.pollInterval, (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_reading || _connecting) return;
    _reading = true;
    try {
      final value = await widget.receiver.headUnitStatus();
      if (mounted) setState(() => _status = value);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Status head unit belum terbaca. Cabut lalu colok ulang kabel.',
        );
      }
    } finally {
      _reading = false;
    }
  }

  Future<void> _connect() async {
    if (_connecting) return;
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      final value = await widget.receiver.connectHeadUnit();
      if (mounted) setState(() => _status = value);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is PlatformException
              ? error.message
              : 'Head unit belum bisa dihubungkan. Coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _shareLog() async {
    final shared = await widget.receiver.shareDiagnostics().catchError(
      (Object _) => false,
    );
    if (!shared && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada log diagnostik untuk dibagikan.'),
        ),
      );
    }
  }

  (IconData, String, String) _describe(HeadUnitLink link) => switch (link) {
    HeadUnitLink.absent => (
      Icons.usb_off,
      'Head unit belum terdeteksi',
      'Colok HP ke port USB head unit dengan kabel data, lalu buka menu T-Link di layar mobil.',
    ),
    HeadUnitLink.detected => (
      Icons.usb,
      'Head unit terdeteksi',
      'Tekan Tampilkan di head unit, izinkan akses USB, lalu pilih Seluruh layar saat diminta.',
    ),
    HeadUnitLink.waiting => (
      Icons.cast,
      'Mengirim layar ke head unit',
      'Jika layar mobil masih menunggu lebih dari 10 detik, cabut lalu colok ulang kabel.',
    ),
    HeadUnitLink.streaming => (
      Icons.cast_connected,
      'Tampil di head unit',
      'Layar HP sudah muncul di mobil. Lanjutkan untuk menghubungkan iPhone.',
    ),
  };

  Widget _statusPanel(BuildContext context) {
    final theme = Theme.of(context);
    final status = _status;
    final link = status?.link;
    final (icon, title, description) = link == null
        ? (Icons.usb, 'Memeriksa head unit', 'Membaca sambungan USB HP.')
        : _describe(link);
    return AppPanel(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Langkah 1 dari 2',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          const PageIntro(
            'Hubungkan head unit',
            'DashTConnect tampil di layar mobil lewat kabel USB, tanpa aplikasi T-Link.',
          ),
          const SizedBox(height: 20),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                IconTile(icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (link == null || link == HeadUnitLink.waiting || _connecting) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(semanticsLabel: 'Menunggu head unit'),
          ],
          if (status?.problem case final problem?
              when link != HeadUnitLink.streaming) ...[
            const SizedBox(height: 16),
            AppNotice.warning(problem),
          ],
          if (_error case final error?) ...[
            const SizedBox(height: 16),
            AppNotice(error, error: true),
          ],
          const SizedBox(height: 20),
          if (link == HeadUnitLink.streaming)
            FilledButton.icon(
              onPressed: widget.onContinue,
              icon: const Icon(Icons.phone_iphone),
              label: const Text('Lanjut hubungkan iPhone'),
            )
          else
            FilledButton.icon(
              onPressed: link == HeadUnitLink.detected && !_connecting
                  ? _connect
                  : null,
              icon: const Icon(Icons.cast),
              label: const Text('Tampilkan di head unit'),
            ),
          if (link != HeadUnitLink.streaming) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onContinue,
              child: const Text('Lewati, pakai layar HP saja'),
            ),
          ],
          if (status?.problem != null) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _shareLog,
              icon: const Icon(Icons.ios_share),
              label: const Text('Bagikan log diagnostik'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _guidePanel(BuildContext context) {
    final theme = Theme.of(context);
    const steps = [
      'Buka kunci HP sebelum mencolok kabel. Saat HP terkunci, Android menutup pilihan aplikasi USB.',
      'Jika Android bertanya aplikasi untuk USB, pilih DashTConnect.',
      'Tutup aplikasi T-Link di HP agar sambungan USB tidak dipakai dua aplikasi.',
    ];
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sebelum mencolok', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final (index, step) in steps.indexed) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${index + 1}.',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(child: Text(step)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          Text(
            'Sentuhan dari layar mobil diteruskan langsung oleh Android lewat kabel yang sama.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Head unit')),
    body: SafeArea(
      top: false,
      child: AppContent(
        child: AdaptiveColumns(
          first: _statusPanel(context),
          second: _guidePanel(context),
        ),
      ),
    ),
  );
}
