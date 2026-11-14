import 'package:flutter/material.dart';

import '../../domain/entities/connection_mode.dart';
import '../widgets/app_brand.dart';
import '../widgets/app_layout.dart';

class ModeSelectorPage extends StatelessWidget {
  const ModeSelectorPage({
    super.key,
    required this.onSelect,
    this.lastMode,
    this.busy = false,
    this.error,
    this.onBack,
  });
  final ValueChanged<ConnectionMode> onSelect;
  final ConnectionMode? lastMode;
  final bool busy;
  final String? error;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: onBack == null && !busy,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !busy) onBack?.call();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const AppBrand(),
        leading: onBack == null
            ? null
            : BackButton(onPressed: busy ? null : onBack),
      ),
      body: SafeArea(
        child: AppContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const PageIntro(
                'Pilih cara terhubung.',
                'Dua alur berbeda, sesuai ponsel dan head unit Anda.',
              ),
              const SizedBox(height: 28),
              AdaptiveColumns(
                first: _mode(
                  context,
                  ConnectionMode.carPlay,
                  Icons.apple,
                  'Untuk iPhone',
                  'Android menerima CarPlay dari iPhone, lalu meneruskannya ke head unit melalui T-Link.',
                  'iPhone + Android + head unit T-Link',
                ),
                second: _mode(
                  context,
                  ConnectionMode.androidAuto,
                  Icons.android,
                  'Untuk Android',
                  'Target satu Android sebagai sumber dan receiver lokal, lalu tampil di HU melalui T-Link. Perlu head unit server Android Auto dan sertifikat head unit.',
                  'Satu Android + head unit T-Link',
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Kedua mode menargetkan HU T-Link. CarPlay memakai iPhone; receiver lokal Android Auto masih memerlukan integrasi.',
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: LinearProgressIndicator(),
                ),
              if (error != null) ...[
                const SizedBox(height: 16),
                AppNotice(error!, error: true),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _mode(
    BuildContext context,
    ConnectionMode mode,
    IconData icon,
    String audience,
    String description,
    String devices,
  ) {
    final theme = Theme.of(context);
    final accent = mode == ConnectionMode.carPlay
        ? theme.colorScheme.primary
        : theme.brightness == Brightness.dark
        ? const Color(0xFF71DBC2)
        : const Color(0xFF006A55);
    return Semantics(
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          key: Key('mode-${mode.id}'),
          borderRadius: BorderRadius.circular(16),
          onTap: busy ? null : () => onSelect(mode),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 36, color: accent),
                    const Spacer(),
                    Icon(Icons.arrow_forward, color: accent),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  audience,
                  style: theme.textTheme.labelLarge?.copyWith(color: accent),
                ),
                const SizedBox(height: 8),
                Text(mode.label, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(description),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text(devices, style: theme.textTheme.bodySmall),
                if (lastMode == mode)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Terakhir dipakai',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
