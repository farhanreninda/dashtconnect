import 'package:dashtconnect/domain/entities/notebook.dart';
import 'package:dashtconnect/presentation/app.dart';
import 'package:dashtconnect/presentation/pages/device_page.dart';
import 'package:dashtconnect/presentation/theme/app_theme.dart';
import 'package:dashtconnect/presentation/widgets/app_navigation.dart';
import 'package:dashtconnect/presentation/widgets/app_page_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

class _GroupedInfoDevice extends TestDeviceGateway {
  String model = 'Fixture model';
  @override
  Future<Map<String, String>> deviceInfo() async {
    if (failInfo) throw StateError('Fixture failed refresh');
    return {
      'Model Android': model,
      'Jaringan aktif': 'Fixture network',
      'Suhu baterai': 'Fixture temperature',
      'Info tambahan': 'Fixture extension',
      'Arsitektur': 'arm64-v8a, armeabi-v7a, armeabi',
    };
  }
}

void main() {
  for (final size in [const Size(320, 640), const Size(640, 320)]) {
    testWidgets('expanded device details and refresh fit $size at 2x text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(body: DevicePage(bridge: _GroupedInfoDevice())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Detail teknis'));
      await tester.tap(find.text('Detail teknis'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('arm64-v8a, armeabi-v7a, armeabi'));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Perbarui'));
      await tester.tap(find.text('Perbarui'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Diperbarui pukul'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'device info shows gateway values, refreshes and preserves the last successful reading on error',
    (tester) async {
      final device = _GroupedInfoDevice();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DevicePage(bridge: device)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fixture model'), findsOneWidget);
      expect(find.text('Fixture extension'), findsNothing);
      expect(find.text('Fixture network'), findsOneWidget);
      expect(find.text('Fixture temperature'), findsOneWidget);
      await tester.ensureVisible(find.text('Detail teknis'));
      await tester.tap(find.text('Detail teknis'));
      await tester.pumpAndSettle();
      expect(find.text('Fixture extension'), findsOneWidget);
      device.model = 'Fixture another phone';
      await tester.ensureVisible(find.text('Perbarui'));
      await tester.tap(find.text('Perbarui'));
      await tester.pumpAndSettle();
      expect(find.text('Fixture model'), findsNothing);
      expect(find.text('Fixture another phone'), findsOneWidget);
      expect(find.textContaining('Diperbarui pukul'), findsOneWidget);
      device.failInfo = true;
      await tester.ensureVisible(find.text('Perbarui'));
      await tester.tap(find.text('Perbarui'));
      await tester.pumpAndSettle();
      expect(find.text('Fixture another phone'), findsOneWidget);
      expect(find.textContaining('Pembacaan perangkat gagal.'), findsOneWidget);
      device.failInfo = false;
      await tester.ensureVisible(find.text('Perbarui'));
      await tester.tap(find.text('Perbarui'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pembacaan perangkat gagal.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('tabs are lazy, retained, and never read device info on resume', (
    tester,
  ) async {
    final device = TestDeviceGateway();
    final store = MemoryNotebookRepository()
      ..data = const Notebook(tutorialCompleted: true);
    await tester.pumpWidget(
      ResearchApp(
        repository: store,
        device: device,
        receiver: TestReceiverGateway(),
      ),
    );
    await tester.pumpAndSettle();
    expect(device.infoReads, 0);
    expect(find.text('Android ini'), findsNothing);
    expect(find.text('Layar', skipOffstage: false), findsNothing);
    final home = tester.element(find.byKey(const PageStorageKey('home')));
    final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme;
    await tester.tap(find.text('Panduan'));
    await tester.pumpAndSettle();
    final guide = tester.element(find.byKey(const PageStorageKey('guide')));
    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tampilan'));
    await tester.tap(find.text('Tampilan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      identical(
        theme,
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme,
      ),
      isTrue,
    );
    await tester.tap(find.text('Panduan'));
    await tester.pumpAndSettle();
    expect(
      identical(
        guide,
        tester.element(find.byKey(const PageStorageKey('guide'))),
      ),
      isTrue,
    );
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    expect(
      identical(home, tester.element(find.byKey(const PageStorageKey('home')))),
      isTrue,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(device.infoReads, 0);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  for (final rail in [false, true]) {
    testWidgets(
      'custom navigation handles keyboard and reduced motion, rail=$rail',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        var selected = -1;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: AppNavigation(
                  rail: rail,
                  selectedIndex: 0,
                  onSelected: (index) => selected = index,
                ),
              ),
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(selected, 0);
        await tester.tap(find.text('Pengaturan'));
        await tester.pumpAndSettle();
        expect(selected, 2);
        expect(tester.takeException(), isNull);
        expect(tester.hasRunningAnimations, isFalse);
      },
    );
  }

  for (final reduced in [false, true]) {
    testWidgets(
      'routes preserve Material navigation and honor reduced=$reduced',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: reduced);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('Root'))),
        );
        final route = AppPageRoute<void>(
          builder: (_) =>
              Scaffold(appBar: AppBar(), body: const Text('Details')),
        );
        tester.state<NavigatorState>(find.byType(Navigator)).push(route);
        await tester.pump();
        expect(
          route.transitionDuration,
          reduced ? Duration.zero : const Duration(milliseconds: 200),
        );
        expect(
          route.reverseTransitionDuration,
          reduced ? Duration.zero : const Duration(milliseconds: 160),
        );
        await tester.pumpAndSettle();
        expect(find.text('Details'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Root'), findsOneWidget);
      },
    );
  }
}
