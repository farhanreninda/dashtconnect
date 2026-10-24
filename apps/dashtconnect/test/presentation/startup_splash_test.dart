import 'dart:async';
import 'dart:ui' as ui;

import 'package:dashtconnect/domain/entities/notebook.dart';
import 'package:dashtconnect/presentation/app.dart';
import 'package:dashtconnect/presentation/widgets/startup_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

class _DelayedRepository extends MemoryNotebookRepository {
  final ready = Completer<Notebook>();

  @override
  Future<Notebook> load() => ready.future;
}

void main() {
  testWidgets(
    'splash mark draws blue outlines on a transparent canvas without a bitmap',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: StartupSplash(onFinished: () {})),
      );
      final mark = find.byKey(const Key('splash-mark'));
      final painter = tester
          .widget<CustomPaint>(
            find.descendant(of: mark, matching: find.byType(CustomPaint)),
          )
          .painter!;
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), const Size(128, 128));
      final picture = recorder.endRecording();
      final image = (await tester.runAsync(() => picture.toImage(128, 128)))!;
      final pixels = (await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      expect(pixels.getUint8(3), 0);
      expect(pixels.getUint8((64 * 128 + 64) * 4 + 3), 0);
      expect(
        List.generate(4, (i) => pixels.getUint8((64 * 128 + 10) * 4 + i)),
        [0, 107, 253, 255],
      );
      image.dispose();
      picture.dispose();
      await tester.pumpAndSettle();
      expect(tester.binding.sendFramesToEngine, isTrue);
      expect(find.byType(Image), findsNothing);
      expect(tester.getSize(mark), const Size(128, 128));
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('splash is neutral and animates in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(640, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var finished = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: StartupSplash(onFinished: () => finished++),
        ),
      );
      final expected = brightness == Brightness.dark
          ? Colors.black
          : Colors.white;
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        expected,
      );
      final mark = find.byKey(const Key('splash-mark'));
      expect(find.byType(Image), findsNothing);
      final logoBounds = tester.getRect(mark);
      final logoBottomRight = tester.getBottomRight(mark);
      expect(logoBounds.size, const Size(128, 128));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getRect(mark), logoBounds);
      expect(tester.getBottomRight(mark), logoBottomRight);
      expect(find.text('DashTConnect'), findsOneWidget);
      final fade = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(StartupSplash),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, allOf(greaterThan(0), lessThan(1)));
      expect(finished, 0);
      await tester.pumpAndSettle();
      expect(finished, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('short splash keeps the logo visible without clipping the name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: StartupSplash(onFinished: () => finished++),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const Key('splash-mark'))),
      const Size(128, 128),
    );
    expect(find.text('DashTConnect'), findsNothing);
    expect(finished, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion skips the intro immediately', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(home: StartupSplash(onFinished: () => finished++)),
    );
    expect(finished, 1);
    await tester.pump();
    expect(finished, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('saved theme applies and intro hands off once data is ready', (
    tester,
  ) async {
    final repository = _DelayedRepository();
    await tester.pumpWidget(
      ResearchApp(
        repository: repository,
        device: TestDeviceGateway(),
        receiver: TestReceiverGateway(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StartupSplash), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    repository.ready.complete(
      const Notebook(theme: 'dark', tutorialCompleted: true),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StartupSplash), findsNothing);
    expect(find.text('Mulai receiver'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('failed data load shows retry instead of trapping splash', (
    tester,
  ) async {
    final repository = MemoryNotebookRepository()..failLoad = true;
    await tester.pumpWidget(
      ResearchApp(
        repository: repository,
        device: TestDeviceGateway(),
        receiver: TestReceiverGateway(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Catatan lokal tidak dapat dibaca.'), findsOneWidget);
    repository.failLoad = false;
    repository.data = const Notebook(tutorialCompleted: true);
    await tester.tap(find.text('Coba baca kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Mulai receiver'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
