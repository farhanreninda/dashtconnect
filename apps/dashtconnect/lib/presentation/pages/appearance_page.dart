import 'package:flutter/material.dart';

import '../widgets/app_layout.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({
    super.key,
    required this.initialTheme,
    required this.onChanged,
  });

  final String initialTheme;
  final Future<void> Function(String) onChanged;

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  late String _selected = widget.initialTheme;
  bool _saving = false;
  String? _error;

  Future<void> _select(String value) async {
    if (_saving || value == _selected) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onChanged(value);
      if (mounted) setState(() => _selected = value);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Tema belum tersimpan. Pilih kembali untuk mencoba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tampilan')),
    body: SafeArea(
      child: AppContent(
        maxWidth: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageIntro(
              'Tema aplikasi',
              'Pilih tampilan yang nyaman untuk Anda.',
            ),
            const SizedBox(height: 16),
            RadioGroup<String>(
              groupValue: _selected,
              onChanged: (value) {
                if (value != null) _select(value);
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final split =
                      constraints.maxWidth >= 600 &&
                      MediaQuery.textScalerOf(context).scale(16) < 24;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final option in const [
                        ('system', 'Sesuai perangkat', 'Ikuti tema HP'),
                        ('light', 'Terang', 'Selalu terang'),
                        ('dark', 'Gelap', 'Selalu gelap'),
                      ])
                        SizedBox(
                          width: split
                              ? (constraints.maxWidth - 24) / 3
                              : constraints.maxWidth,
                          child: Material(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLowest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: _selected == option.$1
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                width: _selected == option.$1 ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                if (split)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: _ThemePreview(option.$1),
                                  ),
                                RadioListTile<String>(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  value: option.$1,
                                  enabled: !_saving,
                                  title: Text(option.$2),
                                  subtitle: Text(option.$3),
                                  selected: _selected == option.$1,
                                  controlAffinity:
                                      ListTileControlAffinity.trailing,
                                  secondary: split
                                      ? null
                                      : MediaQuery.textScalerOf(context)
                                                .scale(16) <=
                                            24
                                      ? _ThemePreview(option.$1)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (_saving) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(semanticsLabel: 'Menyimpan tema'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              AppNotice(_error!, error: true),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          for (final dark
              in value == 'system' ? [false, true] : [value == 'dark'])
            Expanded(
              child: ColoredBox(
                color: dark ? const Color(0xFF10141B) : const Color(0xFFF6F7F9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(height: 9, color: const Color(0xFF006BFD)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: dark
                              ? const Color(0xFF303D50)
                              : const Color(0xFFDCE5F3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
