import 'package:dashtconnect/presentation/widgets/receiver_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty overlay space passes touches to CarPlay content', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                ),
              ),
              Positioned.fill(
                child: ReceiverControls(
                  dimmed: false,
                  busy: false,
                  onToggleDim: () {},
                  onStop: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(300, 100));
    expect(taps, 1);
    await tester.tap(find.byTooltip('Kontrol sesi'));
    await tester.pump();
    expect(taps, 1);
    await tester.pumpWidget(const SizedBox());
  });

  Future<void> openMovable(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceiverControls(
            dimmed: false,
            busy: false,
            onToggleDim: () {},
            onStop: () {},
          ),
        ),
      ),
    );
  }

  testWidgets(
    'drag moves without tapping and returns ten seconds after the last interaction',
    (tester) async {
      await openMovable(tester);
      final main = find.byTooltip('Kontrol sesi');
      final home = tester.getTopLeft(main);
      await tester.drag(main, const Offset(180, -100));
      await tester.pumpAndSettle();
      final moved = tester.getTopLeft(main);
      expect(moved.dx, greaterThan(home.dx));
      expect(moved.dx, 332);
      expect(moved.dy, lessThan(home.dy));
      expect(find.byTooltip('Redupkan layar HP'), findsNothing);
      await tester.pump(const Duration(seconds: 7));
      await tester.tap(main);
      await tester.pump(const Duration(seconds: 9));
      expect(tester.getTopLeft(main), moved);
      expect(find.byTooltip('Hentikan receiver'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getTopLeft(main), home);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'release near the left edge docks without changing vertical position',
    (tester) async {
      await openMovable(tester);
      final main = find.byTooltip('Kontrol sesi');
      await tester.drag(main, const Offset(100, -80));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(main).dx, 12);
      expect(tester.getTopLeft(main).dy, lessThan(172));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('drag stays in bounds and right-edge menu opens inward', (
    tester,
  ) async {
    await openMovable(tester);
    final main = find.byTooltip('Kontrol sesi');
    await tester.drag(main, const Offset(-1000, -1000));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(main), const Offset(12, 12));
    await tester.drag(main, const Offset(1000, 1000));
    await tester.pumpAndSettle();
    final edge = tester.getTopLeft(main);
    expect(edge, const Offset(332, 172));
    await tester.tap(main);
    await tester.pump();
    expect(tester.getTopLeft(find.byTooltip('Tutup kontrol sesi')), edge);
    for (final label in ['Redupkan layar HP', 'Hentikan receiver']) {
      final rect = tester.getRect(find.byTooltip(label));
      expect(rect.left, greaterThanOrEqualTo(12));
      expect(rect.right, lessThanOrEqualTo(388));
      expect(rect.bottom, lessThanOrEqualTo(228));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'round control wakes, resets idle timer and fades without disappearing',
    (tester) async {
      var dims = 0, stops = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiverControls(
              dimmed: false,
              busy: false,
              onToggleDim: () => dims++,
              onStop: () => stops++,
            ),
          ),
        ),
      );
      double opacity() =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
      expect(opacity(), 0.30);
      expect(
        tester.getSize(find.widgetWithIcon(IconButton, Icons.circle)),
        const Size(56, 56),
      );
      expect(find.byTooltip('Redupkan layar HP'), findsNothing);
      await tester.tap(find.byTooltip('Kontrol sesi'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(), 1);
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byTooltip('Redupkan layar HP'));
      await tester.pump(const Duration(seconds: 2));
      expect(dims, 1);
      expect(opacity(), 1);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(), 0.30);
      expect(find.byTooltip('Kontrol sesi'), findsOneWidget);
      expect(find.byTooltip('Hentikan receiver'), findsNothing);
      await tester.tap(find.byTooltip('Kontrol sesi'));
      await tester.pump();
      await tester.tap(find.byTooltip('Hentikan receiver'));
      expect(stops, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('idle also closes the menu with accessible navigation enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            accessibleNavigation: true,
            disableAnimations: true,
          ),
          child: ReceiverControls(
            dimmed: true,
            busy: false,
            onToggleDim: () {},
            onStop: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Kontrol sesi'));
    await tester.pump(const Duration(seconds: 4));
    expect(find.byTooltip('Pulihkan kecerahan HP'), findsNothing);
    expect(find.byTooltip('Hentikan receiver'), findsNothing);
    expect(find.byTooltip('Kontrol sesi'), findsOneWidget);
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0.30,
    );
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).duration,
      Duration.zero,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
