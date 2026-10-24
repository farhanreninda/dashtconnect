import 'dart:async';

import 'package:flutter/material.dart';

class ReceiverControls extends StatefulWidget {
  const ReceiverControls({
    super.key,
    required this.dimmed,
    required this.busy,
    required this.onToggleDim,
    required this.onStop,
  });

  final bool dimmed, busy;
  final VoidCallback onToggleDim, onStop;

  @override
  State<ReceiverControls> createState() => _ReceiverControlsState();
}

class _ReceiverControlsState extends State<ReceiverControls> {
  Timer? _idle, _returnHome;
  Offset? _position;
  bool _active = false,
      _expanded = false,
      _dragging = false,
      _returning = false;

  void _wake() {
    if (!mounted) return;
    _idle?.cancel();
    _returnHome?.cancel();
    if (!_active || _returning) {
      setState(() {
        _active = true;
        _returning = false;
      });
    }
    if (_dragging) return;
    _idle = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _active = false;
        _expanded = false;
      });
    });
    _returnHome = Timer(const Duration(seconds: 10), () {
      if (!mounted || _position == null) return;
      setState(() {
        _position = null;
        _expanded = false;
        _returning = true;
      });
    });
  }

  @override
  void dispose() {
    _idle?.cancel();
    _returnHome?.cancel();
    super.dispose();
  }

  Widget _button(String label, Widget icon, VoidCallback? action) => Material(
    color: const Color(0xED10141B),
    shape: const CircleBorder(side: BorderSide(color: Color(0x66FFFFFF))),
    clipBehavior: Clip.antiAlias,
    child: IconButton(
      tooltip: label,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white54,
        fixedSize: const Size(56, 56),
        shape: const CircleBorder(),
      ),
      onPressed: action == null
          ? null
          : () {
              _wake();
              action();
            },
      icon: icon,
    ),
  );

  Offset _bounded(Offset point, Size size) => Offset(
    point.dx.clamp(12.0, (size.width - 68).clamp(12.0, double.infinity)),
    point.dy.clamp(12.0, (size.height - 68).clamp(12.0, double.infinity)),
  );

  void _dock(Size size, Offset anchor) {
    _dragging = false;
    _wake();
    final point = _bounded(_position ?? anchor, size);
    setState(() {
      _position = _bounded(
        Offset(point.dx + 28 < size.width / 2 ? 12 : size.width - 68, point.dy),
        size,
      );
      _returning = true;
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      final home = _bounded(Offset(12, size.height - 68), size);
      final anchor = _bounded(_position ?? home, size);
      final openLeft = anchor.dx + 184 > size.width - 12;
      return Stack(
        children: [
          AnimatedPositioned(
            left: anchor.dx - (_expanded && openLeft ? 128 : 0),
            top: anchor.dy,
            duration: _returning && !MediaQuery.of(context).disableAnimations
                ? const Duration(milliseconds: 220)
                : Duration.zero,
            child: Focus(
              onFocusChange: (_) => _wake(),
              child: Listener(
                onPointerDown: (_) => _wake(),
                child: AnimatedOpacity(
                  opacity: _active ? 1 : 0.30,
                  duration: MediaQuery.of(context).disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: openLeft
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    children: [
                      Semantics(
                        hint: 'Geser untuk memindahkan. Kembali otomatis setelah 10 detik.',
                        child: GestureDetector(
                          onPanStart: (_) {
                            _dragging = true;
                            _wake();
                            setState(() {
                              _position = anchor;
                              _expanded = false;
                            });
                          },
                          onPanUpdate: (details) {
                            _wake();
                            setState(
                              () => _position = _bounded(
                                (_position ?? anchor) + details.delta,
                                size,
                              ),
                            );
                          },
                          onPanEnd: (_) => _dock(size, anchor),
                          onPanCancel: () => _dock(size, anchor),
                          child: _button(
                            _expanded ? 'Tutup kontrol sesi' : 'Kontrol sesi',
                            _expanded
                                ? const Icon(Icons.close)
                                : const Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(Icons.circle_outlined, size: 34),
                                      Icon(Icons.circle, size: 22),
                                    ],
                                  ),
                            () => setState(() => _expanded = !_expanded),
                          ),
                        ),
                      ),
                      if (_expanded) ...[
                        const SizedBox(width: 8),
                        _button(
                          widget.dimmed
                              ? 'Pulihkan kecerahan HP'
                              : 'Redupkan layar HP',
                          Icon(
                            widget.dimmed
                                ? Icons.brightness_high_outlined
                                : Icons.brightness_low_outlined,
                          ),
                          widget.busy ? null : widget.onToggleDim,
                        ),
                        const SizedBox(width: 8),
                        _button(
                          'Hentikan receiver',
                          const Icon(Icons.stop_circle_outlined),
                          widget.onStop,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
