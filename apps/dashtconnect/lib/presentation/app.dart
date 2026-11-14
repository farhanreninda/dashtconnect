import 'package:flutter/material.dart';

import '../domain/repositories/device_gateway.dart';
import '../domain/entities/connection_mode.dart';
import '../domain/repositories/android_auto_gateway.dart';
import '../domain/repositories/notebook_repository.dart';
import '../domain/repositories/receiver_gateway.dart';
import 'controllers/notebook_controller.dart';
import 'pages/research_home_page.dart';
import 'pages/mode_selector_page.dart';
import 'theme/app_theme.dart';
import 'widgets/app_layout.dart';
import 'widgets/startup_splash.dart';

class ResearchApp extends StatefulWidget {
  const ResearchApp({
    super.key,
    required this.repository,
    required this.device,
    required this.receiver,
    required this.androidAuto,
  });
  final NotebookRepository repository;
  final DeviceGateway device;
  final ReceiverGateway receiver;
  final AndroidAutoGateway androidAuto;

  @override
  State<ResearchApp> createState() => _ResearchAppState();
}

class _ResearchAppState extends State<ResearchApp> {
  late final NotebookController _controller;
  bool _introFinished = false;
  ConnectionMode? _mode;
  bool _choosingMode = false;
  bool _selecting = false;
  String? _selectionError;

  Future<void> _selectMode(ConnectionMode mode) async {
    if (_selecting) return;
    setState(() {
      _selecting = true;
      _selectionError = null;
    });
    try {
      await _controller.save(_controller.notebook!.copyWith(lastMode: mode.id));
      if (mounted) {
        setState(() {
          _mode = mode;
          _choosingMode = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _selectionError =
              'Pilihan belum tersimpan. Coba pilih mode kembali.',
        );
      }
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  late final _lightTheme = buildAppTheme(Brightness.light);
  late final _darkTheme = buildAppTheme(Brightness.dark);

  @override
  void initState() {
    super.initState();
    _controller = NotebookController(widget.repository)..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, child) => MaterialApp(
      title: 'DashTConnect',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeAnimationDuration: _introFinished
          ? kThemeAnimationDuration
          : Duration.zero,
      themeMode: switch (_controller.notebook?.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home:
          !_controller.failed &&
              (!_introFinished || _controller.notebook == null)
          ? StartupSplash(
              onFinished: () {
                if (mounted && !_introFinished) {
                  setState(() => _introFinished = true);
                }
              },
            )
          : _controller.notebook == null
          ? Scaffold(
              body: SafeArea(
                child: AppContent(
                  maxWidth: 560,
                  child: AppPanel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Catatan lokal tidak dapat dibaca.'),
                        const SizedBox(height: 12),
                        const Text(
                          'Berkas dipertahankan agar data tidak tertimpa. '
                          'Periksa penyimpanan perangkat lalu coba lagi.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _controller.load,
                          child: const Text('Coba baca kembali'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : _choosingMode
          ? ModeSelectorPage(
              lastMode: ConnectionMode.fromId(_controller.notebook!.lastMode),
              busy: _selecting,
              error: _selectionError,
              onSelect: _selectMode,
              onBack: () => setState(() => _choosingMode = false),
            )
          : ResearchHome(
              key: ValueKey(_mode),
              mode: _mode,
              androidAuto: widget.androidAuto,
              onChangeMode: () => setState(() {
                _selectionError = null;
                _choosingMode = true;
              }),
              onBackToHome: () => setState(() => _mode = null),
              notebook: _controller.notebook!,
              bridge: widget.device,
              receiver: widget.receiver,
              save: _controller.save,
            ),
    ),
  );
}
