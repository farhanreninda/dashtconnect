import 'dart:async';

import 'package:dashtconnect/domain/entities/notebook.dart';
import 'package:dashtconnect/domain/entities/receiver_state.dart';
import 'package:dashtconnect/domain/repositories/device_gateway.dart';
import 'package:dashtconnect/presentation/app.dart';
import 'package:dashtconnect/presentation/pages/setup_guide_page.dart';
import 'package:dashtconnect/presentation/pages/appearance_page.dart';
import 'package:dashtconnect/presentation/widgets/app_layout.dart';
import 'package:dashtconnect/presentation/widgets/app_navigation.dart';
import 'package:dashtconnect/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final position = tester.getCenter(finder);
  expect(
    position.dy,
    lessThan(tester.view.physicalSize.height - tester.view.viewInsets.bottom),
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Inter', 'SpaceGrotesk']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
      await loader.load();
    }
  });
  testWidgets(
    'paired panels match heights after content expands and collapses',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppContent(
              child: AdaptiveColumns(
                first: AppPanel(child: SizedBox(height: 80)),
                second: AppPanel(
                  child: ExpansionTile(
                    title: Text('Bantuan'),
                    children: [SizedBox(height: 240)],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final panels = find.byType(AppPanel);
      final initialHeight = tester.getSize(panels.first).height;
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Bantuan'));
        await tester.pumpAndSettle();
        expect(tester.getSize(panels.first), tester.getSize(panels.last));
        expect(tester.takeException(), isNull);
        if (i == 0) {
          expect(
            tester.getSize(panels.first).height,
            greaterThan(initialHeight),
          );
        } else {
          expect(tester.getSize(panels.first).height, initialHeight);
        }
      }
    },
  );

  testWidgets('action tiles retain keyboard activation', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: AppActionTile(
            icon: Icons.wifi,
            title: 'Buka Wi-Fi',
            subtitle: 'Pengaturan lokal',
            onTap: () => opened = true,
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final tileMaterial = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(AppActionTile),
            matching: find.byType(Material),
          )
          .first,
    );
    expect((tileMaterial.shape! as RoundedRectangleBorder).side.width, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened, isTrue);
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets(
      'guide action cards share dimensions in both orientations at ${scale}x',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = MemoryNotebookRepository()
          ..data = const Notebook(tutorialCompleted: true);
        tester.view.physicalSize = const Size(320, 640);
        await tester.pumpWidget(
          ResearchApp(
            repository: store,
            device: TestDeviceGateway(),
            receiver: TestReceiverGateway(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Panduan'));
        await tester.pumpAndSettle();
        for (final size in [const Size(320, 640), const Size(800, 360)]) {
          tester.view.physicalSize = size;
          await tester.pumpAndSettle();
          final cards = find.byType(AppActionTile);
          expect(cards, findsNWidgets(3));
          final dimensions = [
            for (var i = 0; i < 3; i++) tester.getSize(cards.at(i)),
          ];
          expect(dimensions.toSet(), hasLength(1));
          if (scale == 1) {
            expect(dimensions.first.height, lessThanOrEqualTo(80));
          }
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('theme choices remain usable in short landscape at ${scale}x', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: AppearancePage(
            initialTheme: 'system',
            onChanged: (value) async => saved = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (scale == 1) {
        for (final choice in ['Sesuai perangkat', 'Terang', 'Gelap']) {
          expect(
            tester.getRect(find.text(choice)).bottom,
            lessThanOrEqualTo(360),
          );
        }
      }
      await tapVisible(tester, find.text('Gelap'));
      expect(saved, 'dark');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('settings information rows have matching heights on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(384, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryNotebookRepository()
      ..data = const Notebook(tutorialCompleted: true);
    await tester.pumpWidget(
      ResearchApp(
        repository: store,
        device: TestDeviceGateway(),
        receiver: TestReceiverGateway(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    final deviceRow = find.ancestor(
      of: find.text('Informasi perangkat'),
      matching: find.byType(ListTile),
    );
    final aboutRow = find.ancestor(
      of: find.text('Tentang DashTConnect'),
      matching: find.byType(ListTile),
    );
    expect(tester.getSize(deviceRow).height, tester.getSize(aboutRow).height);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape rail keeps its longest label on one line', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Scaffold(
          body: Row(
            children: [
              AppNavigation(rail: true, selectedIndex: 2, onSelected: (_) {}),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final label = tester.renderObject<RenderParagraph>(find.text('Pengaturan'));
    expect(
      label.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 10),
      ),
      hasLength(1),
    );
  });

  for (final theme in ['light', 'dark']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'all routes remain usable in short landscape, $theme at ${scale}x',
        (tester) async {
          tester.view.physicalSize = const Size(800, 360);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetViewInsets);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final store = MemoryNotebookRepository()
            ..data = Notebook(tutorialCompleted: true, theme: theme);
          final device = TestDeviceGateway();
          final receiver = TestReceiverGateway();
          final messenger = tester.binding.defaultBinaryMessenger;
          messenger.setMockMethodCallHandler(SystemChannels.platform, (
            call,
          ) async {
            return null;
          });
          messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
            call,
          ) async {
            if (call.method == 'create') {
              final id = (call.arguments as Map)['id'] as int;
              scheduleMicrotask(
                () => receiver.updates.add(
                  ReceiverEvent(id, ReceiverPhase.surfaceReady, ''),
                ),
              );
            }
            return null;
          });
          addTearDown(() {
            messenger.setMockMethodCallHandler(SystemChannels.platform, null);
            messenger.setMockMethodCallHandler(
              SystemChannels.platform_views,
              null,
            );
            return receiver.updates.close();
          });
          await tester.pumpWidget(
            ResearchApp(repository: store, device: device, receiver: receiver),
          );
          await tester.pumpAndSettle();
          expect(
            tester.widget<AppNavigation>(find.byType(AppNavigation)).rail,
            isTrue,
          );
          expect(find.byType(NavigationBar), findsNothing);
          if (scale == 1) {
            final action = find.ancestor(
              of: find.text('Mulai receiver'),
              matching: find.byType(FilledButton),
            );
            expect(
              tester.getRect(action).bottom,
              lessThanOrEqualTo(360),
              reason: 'Primary action must be visible before scrolling in normal landscape',
            );
          }
          await tapVisible(tester, find.text('Panduan'));
          await tapVisible(tester, find.text('Uji tampilan'));
          if (scale == 1) {
            for (var target = 1; target <= 4; target++) {
              final button = find.ancestor(
                of: find.text('Target $target\n0 sentuhan'),
                matching: find.byType(FilledButton),
              );
              expect(
                tester.getRect(button).bottom,
                lessThanOrEqualTo(360),
                reason: 'All four targets must be visible in normal short landscape',
              );
            }
          }
          await tapVisible(tester, find.text('Target 4\n0 sentuhan'));
          expect(find.text('Target 4\n1 sentuhan'), findsOneWidget);
          tester.view.physicalSize = const Size(360, 800);
          await tester.pumpAndSettle();
          expect(find.text('Target 4\n1 sentuhan'), findsOneWidget);
          tester.view.physicalSize = const Size(800, 360);
          await tester.pumpAndSettle();
          await tester.pageBack();
          await tester.pumpAndSettle();

          await tapVisible(tester, find.text('Panduan'));
          await tapVisible(tester, find.text('Buka Wi-Fi'));
          expect(device.lastSettings, DeviceSettings.wifi);
          await tapVisible(tester, find.text('Buka Bluetooth'));
          expect(device.lastSettings, DeviceSettings.bluetooth);
          await tapVisible(tester, find.text('Belum tampil di head unit?'));
          expect(
            find.textContaining('Gunakan kabel data pada port USB'),
            findsOneWidget,
          );

          await tapVisible(tester, find.text('Pengaturan'));
          await tapVisible(tester, find.text('Informasi perangkat'));
          expect(find.byType(TextField), findsNothing);
          expect(find.text('Perangkat uji'), findsOneWidget);
          final snapshot = store.data;
          tester.view.physicalSize = const Size(360, 800);
          await tester.pumpAndSettle();
          tester.view.physicalSize = const Size(800, 360);
          await tester.pumpAndSettle();
          expect(find.text('Perangkat uji'), findsOneWidget);
          expect(identical(store.data, snapshot), isTrue);
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(find.text('Catatan pengujian'), findsNothing);
          expect(find.text('Tinjau laporan lokal'), findsNothing);
          await tapVisible(tester, find.text('Tentang DashTConnect'));
          expect(find.text('Tentang aplikasi'), findsOneWidget);
          await tester.ensureVisible(
            find.text('Atur kecerahan layar HP saat terhubung.'),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pageBack();
          await tester.pumpAndSettle();

          await tapVisible(tester, find.text('Beranda'));
          await tapVisible(tester, find.text('Mulai receiver'));
          await tapVisible(tester, find.text('Hubungkan iPhone'));
          expect(receiver.starts, 0);
          expect(
            find.textContaining('Autentikasi aksesori belum disiapkan'),
            findsOneWidget,
          );
          await tester.pageBack();
          await tester.pumpAndSettle();
          await tester.pumpWidget(const SizedBox());
        },
        variant: TargetPlatformVariant.only(TargetPlatform.android),
      );

      testWidgets(
        'all tutorial steps fit short landscape, $theme at ${scale}x',
        (tester) async {
          tester.view.physicalSize = const Size(640, 320);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          var completed = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(
                theme == 'dark' ? Brightness.dark : Brightness.light,
              ),
              home: SetupGuidePage(
                firstRun: true,
                onComplete: () async {
                  completed = true;
                },
                onTestDisplay: () {},
                onOpenSettings: (_) async {},
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (var step = 1; step <= 4; step++) {
            expect(find.text('Langkah $step dari 4'), findsOneWidget);
            await tapVisible(tester, find.byKey(const Key('guide-next')));
          }
          expect(completed, isTrue);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
