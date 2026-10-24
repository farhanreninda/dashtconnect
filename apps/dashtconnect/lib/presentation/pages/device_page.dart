import 'package:flutter/material.dart';

import '../../domain/repositories/device_gateway.dart';
import '../widgets/app_layout.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key, required this.bridge});
  final DeviceGateway bridge;

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  Map<String, String> _info = {};
  bool _reading = false;
  String? _error;
  DateTime? _updatedAt;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _reading = true;
      _error = null;
    });
    try {
      final info = await widget.bridge.deviceInfo();
      if (mounted) {
        setState(() {
          _reading = false;
          _info = info;
          _updatedAt = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _reading = false;
          _error =
              'Pembacaan perangkat gagal. Tekan Perbarui untuk mencoba lagi.';
        });
      }
    }
  }

  Iterable<MapEntry<String, String>> _values(List<String> keys) =>
      _info.entries.where((item) => keys.contains(item.key));

  bool _isTechnical(String key) => !const [
    'Model Android',
    'Versi Android',
    'Jaringan aktif',
    'Internet tervalidasi Android',
    'Suhu baterai',
    'Daya eksternal',
  ].contains(key);

  Widget _rows(Iterable<MapEntry<String, String>> values) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final item in values)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(switch (item.key) {
                'Jaringan aktif' => 'Jaringan',
                'Internet tervalidasi Android' => 'Validasi internet',
                _ => item.key,
              }, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(item.value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
    ],
  );

  Widget _section(
    String title,
    IconData icon,
    Iterable<MapEntry<String, String>> values,
    String note,
  ) {
    if (values.isEmpty) return const SizedBox.shrink();
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _rows(values),
          const SizedBox(height: 12),
          Text(note, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppContent(
    maxWidth: 960,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPanel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(Icons.smartphone_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _info['Model Android'] ??
                          (_reading
                              ? 'Membaca perangkat…'
                              : 'Model belum tersedia'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_info['Versi Android'] case final version?) ...[
                      const SizedBox(height: 6),
                      Text('Android $version'),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Terbaca otomatis dari perangkat ini.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_reading) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(semanticsLabel: 'Membaca info Android'),
        ],
        const SizedBox(height: 20),
        AdaptiveColumns(
          first: _section(
            'Koneksi',
            Icons.wifi_outlined,
            _values(const ['Jaringan aktif', 'Internet tervalidasi Android']),
            'Indikator sistem, bukan tes koneksi langsung.',
          ),
          second: _section(
            'Baterai dan daya',
            Icons.battery_charging_full_outlined,
            _values(const ['Suhu baterai', 'Daya eksternal']),
            'Suhu yang ditampilkan adalah suhu baterai.',
          ),
        ),
        if (_info.keys.any(_isTechnical)) ...[
          const SizedBox(height: 20),
          AppPanel(
            padding: 0,
            child: ExpansionTile(
              key: const PageStorageKey('device-details'),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Text('Detail teknis'),
              leading: const Icon(Icons.memory_outlined),
              children: [
                _rows(_info.entries.where((item) => _isTechnical(item.key))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (_error != null) ...[
          AppNotice(_error!, error: true),
          const SizedBox(height: 16),
        ],
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(switch (_updatedAt) {
                      final time? =>
                        'Diperbarui pukul ${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}',
                      null => 'Belum ada pembaruan',
                    }, style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _reading ? null : _refresh,
                icon: const Icon(Icons.refresh),
                label: Text(_reading ? 'Memperbarui…' : 'Perbarui'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
