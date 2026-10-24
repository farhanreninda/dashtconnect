import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StartupSplash extends StatefulWidget {
  const StartupSplash({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash>
    with SingleTickerProviderStateMixin {
  late final _animation =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 180),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFinished();
      });
  late final _curve = CurvedAnimation(
    parent: _animation,
    curve: Curves.easeOutCubic,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      if (!_animation.isCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _animation.value = 1;
        });
      }
    } else if (_animation.isDismissed) {
      _animation.forward();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? Colors.black : Colors.white;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: background,
            systemNavigationBarColor: background,
            systemNavigationBarDividerColor: background,
          ),
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Center(
                  child: Semantics(
                    label: 'DashTConnect sedang dibuka',
                    child: const SizedBox(
                      key: Key('splash-mark'),
                      width: 128,
                      height: 128,
                      child: CustomPaint(painter: _SplashMarkPainter()),
                    ),
                  ),
                ),
                if (constraints.maxHeight >= 280)
                  Positioned(
                    top: constraints.maxHeight / 2 + 84,
                    left: 20,
                    right: 20,
                    child: ExcludeSemantics(
                      child: FadeTransition(
                        opacity: _curve,
                        child: Text(
                          'DashTConnect',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
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

class _SplashMarkPainter extends CustomPainter {
  const _SplashMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 128, size.height / 128);
    final outline = Paint()
      ..color = const Color(0xFF006BFD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(10, 26, 44, 102),
        const Radius.circular(8),
      ),
      outline,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(50, 36, 118, 92),
        const Radius.circular(10),
      ),
      outline,
    );
    canvas.drawLine(const Offset(44, 64), const Offset(50, 64), outline);
    outline.strokeWidth = 4;
    canvas.drawLine(const Offset(23, 90), const Offset(31, 90), outline);
  }

  @override
  bool shouldRepaint(_SplashMarkPainter oldDelegate) => false;
}
