import 'dart:async';

import 'package:dashtconnect/domain/entities/receiver_state.dart';
import 'package:dashtconnect/presentation/pages/receiver_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late TestReceiverGateway gateway;
  late TestDeviceGateway device;
  final platformCalls = <MethodCall>[];
  late int viewId, surfaces;
  setUp(() {
    gateway = TestReceiverGateway();
    device = TestDeviceGateway();
    platformCalls.clear();
    viewId = -1;
    surfaces = 0;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create') {
        surfaces++;
        viewId = (call.arguments as Map)['id'] as int;
        scheduleMicrotask(
          () => gateway.updates.add(
            ReceiverEvent(viewId, ReceiverPhase.surfaceReady, ''),
          ),
        );
      }
      return null;
    });
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    await gateway.updates.close();
  });

  Future<void> open(WidgetTester tester, {bool autoConnect = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ReceiverPage(
          receiver: gateway,
          device: device,
          autoConnect: autoConnect,
        ),
      ),
    );
    if (autoConnect) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    } else {
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'missing identity blocks starting and permissions have a real action',
    (tester) async {
      gateway.value = const ReceiverPreparation(
        authenticationAvailable: false,
        internetAvailable: true,
        bluetoothEnabled: false,
        missingPermissions: ['android.permission.RECORD_AUDIO'],
        phones: [],
      );
      await open(tester);
      expect(find.byTooltip('Redupkan layar HP'), findsNothing);
      expect(find.byTooltip('Pulihkan kecerahan HP'), findsNothing);
      expect(
        find.textContaining('Autentikasi aksesori belum disiapkan'),
        findsOneWidget,
      );
      expect(find.textContaining('Putuskan sebelum memulai'), findsNothing);
      await tester.ensureVisible(find.text('Hubungkan iPhone'));
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Hubungkan iPhone'),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.textContaining('mikrofon untuk audio CarPlay'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Berikan izin receiver'));
      await tester.tap(find.text('Berikan izin receiver'));
      await tester.pumpAndSettle();
      expect(gateway.requests, 1);
      expect(gateway.starts, 0);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'internet-connected Android can start and status changes retain the surface',
    (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(
        left: 24,
        top: 12,
        bottom: 24,
      );
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      gateway.value = const ReceiverPreparation(
        authenticationAvailable: true,
        internetAvailable: true,
        bluetoothEnabled: true,
        missingPermissions: [],
        phones: [ReceiverPhone(id: 'AA:BB:CC:DD:EE:FF', name: 'iPhone uji')],
      );
      await open(tester);
      expect(surfaces, 1);
      await tester.ensureVisible(find.text('iPhone uji'));
      await tester.tap(find.text('iPhone uji'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Hubungkan iPhone'));
      await tester.tap(find.text('Hubungkan iPhone'));
      await tester.pump();
      expect(gateway.starts, 1);
      expect(find.text('CarPlay terhubung'), findsNothing);
      expect(find.text('Menghubungkan iPhone'), findsOneWidget);
      gateway.updates.add(
        ReceiverEvent(viewId + 1, ReceiverPhase.connected, 'wrong view'),
      );
      await tester.pump();
      expect(find.text('CarPlay terhubung'), findsNothing);
      gateway.updates.add(
        ReceiverEvent(viewId, ReceiverPhase.connected, 'received frame'),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('CarPlay terhubung'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(
        tester.getSize(find.byType(AndroidViewSurface)),
        const Size(800, 360),
      );
      expect(
        platformCalls.any(
          (call) =>
              call.method == 'SystemChrome.setEnabledSystemUIMode' &&
              call.arguments == 'SystemUiMode.immersiveSticky',
        ),
        isTrue,
      );
      await tester.tap(find.byTooltip('Kontrol sesi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Redupkan layar HP'));
      await tester.pumpAndSettle();
      expect(device.dimmed, isTrue);
      device.failDim = true;
      await tester.tap(find.byTooltip('Pulihkan kecerahan HP'));
      await tester.pumpAndSettle();
      expect(
        find.text('Kecerahan belum dapat diubah. Coba lagi.'),
        findsOneWidget,
      );
      expect(device.dimmed, isTrue);
      device.failDim = false;
      await tester.tap(find.byTooltip('Pulihkan kecerahan HP'));
      await tester.pumpAndSettle();
      expect(device.dimmed, isFalse);
      expect(surfaces, 1);
      await tester.tap(find.byTooltip('Hentikan receiver'));
      await tester.pumpAndSettle();
      expect(gateway.stops, 1);
      expect(find.text('CarPlay terhubung'), findsNothing);
      expect(find.byType(AppBar), findsOneWidget);
      expect(
        platformCalls
            .lastWhere(
              (call) => call.method == 'SystemChrome.setEnabledSystemUIMode',
            )
            .arguments,
        'SystemUiMode.edgeToEdge',
      );
      expect(surfaces, 1);
      await tester.pumpWidget(const SizedBox());
      expect(gateway.stops, 2);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'local Wi-Fi help hides credentials until requested and clears them after failure at ${scale}x',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await open(tester);
        gateway.updates.add(
          ReceiverEvent(
            viewId,
            ReceiverPhase.connecting,
            'Menunggu Wi-Fi',
            wifi: const ReceiverWifi('DIRECT-test', 'test-passphrase'),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.ensureVisible(find.text('iPhone belum masuk Wi-Fi?'));
        await tester.pump();
        await tester.tap(find.text('iPhone belum masuk Wi-Fi?'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('test-passphrase'), findsNothing);
        await tester.ensureVisible(find.text('Tampilkan sandi'));
        await tester.pump();
        await tester.tap(find.text('Tampilkan sandi'));
        await tester.pump();
        expect(find.text('test-passphrase'), findsOneWidget);
        expect(tester.takeException(), isNull);
        gateway.updates.add(
          ReceiverEvent(viewId, ReceiverPhase.error, 'Uji dihentikan'),
        );
        await tester.pumpAndSettle();
        expect(find.text('test-passphrase'), findsNothing);
        gateway.updates.add(
          ReceiverEvent(viewId, ReceiverPhase.connecting, 'Percobaan baru'),
        );
        await tester.pump();
        await tester.pump();
        expect(find.text('iPhone belum masuk Wi-Fi?'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }

  testWidgets(
    'preparation scrolls without overflow at large text on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester);
      await tester.scrollUntilVisible(
        find.text('Hubungkan iPhone'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
  const phoneA = ReceiverPhone(id: 'AA:BB:CC:DD:EE:01', name: 'iPhone A');
  const phoneB = ReceiverPhone(id: 'AA:BB:CC:DD:EE:02', name: 'iPhone B');
  ReceiverPreparation ready({
    List<ReceiverPhone> phones = const [phoneA],
    String? preferred,
    bool wifi = true,
  }) => ReceiverPreparation(
    authenticationAvailable: true,
    internetAvailable: true,
    bluetoothEnabled: true,
    wifiEnabled: wifi,
    preferredPhoneId: preferred,
    missingPermissions: [],
    phones: phones,
  );

  testWidgets(
    'one paired phone starts automatically once and does not retry after failure',
    (tester) async {
      gateway.value = ready();
      await open(tester, autoConnect: true);
      expect(gateway.prepares, 1);
      expect(gateway.starts, 1);
      expect(gateway.startedPhoneId, phoneA.id);
      gateway.updates.add(
        ReceiverEvent(viewId, ReceiverPhase.error, 'Uji koneksi gagal'),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Periksa ulang'));
      await tester.tap(find.text('Periksa ulang'));
      await tester.pumpAndSettle();
      expect(gateway.starts, 1);
      expect(gateway.prepares, 1);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'multiple phones require choice unless a successful phone was remembered',
    (tester) async {
      gateway.value = ready(phones: [phoneA, phoneB]);
      await open(tester, autoConnect: true);
      expect(gateway.starts, 0);
      expect(find.textContaining('Ada beberapa perangkat'), findsOneWidget);
      await tester.ensureVisible(find.text('iPhone B'));
      await tester.tap(find.text('iPhone B'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Hubungkan iPhone'));
      await tester.tap(find.text('Hubungkan iPhone'));
      await tester.pump();
      expect(gateway.startedPhoneId, phoneB.id);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('automatic connection chooses the remembered paired phone', (
    tester,
  ) async {
    gateway.value = ready(phones: [phoneA, phoneB], preferred: phoneB.id);
    await open(tester, autoConnect: true);
    expect(gateway.starts, 1);
    expect(gateway.startedPhoneId, phoneB.id);
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    'cancelling Wi-Fi setup does not start or open setup repeatedly',
    (tester) async {
      gateway.value = ready(wifi: false);
      await open(tester, autoConnect: true);
      expect(gateway.prepares, 1);
      expect(gateway.starts, 0);
      expect(find.textContaining('Persiapan belum lengkap'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(gateway.prepares, 1);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'closing receiver while system setup is pending prevents automatic start',
    (tester) async {
      gateway.value = ready();
      final pending = Completer<ReceiverPreparation>();
      gateway.onPrepare = () => pending.future;
      await open(tester, autoConnect: true);
      expect(gateway.prepares, 1);
      await tester.pumpWidget(const SizedBox());
      pending.complete(ready());
      await tester.pump();
      expect(gateway.starts, 0);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
  testWidgets(
    'setup returning in background waits for resume before connecting',
    (tester) async {
      gateway.value = ready();
      final pending = Completer<ReceiverPreparation>();
      gateway.onPrepare = () => pending.future;
      await open(tester, autoConnect: true);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      pending.complete(ready());
      await tester.pump();
      expect(gateway.starts, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(gateway.starts, 1);
      expect(gateway.prepares, 1);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
  testWidgets(
    'automatic start waits for the native surface to return after settings',
    (tester) async {
      gateway.value = ready();
      final pending = Completer<ReceiverPreparation>();
      gateway.onPrepare = () => pending.future;
      await open(tester, autoConnect: true);
      gateway.updates.add(ReceiverEvent(viewId, ReceiverPhase.surfaceLost, ''));
      await tester.pump();
      pending.complete(ready());
      await tester.pump();
      expect(gateway.starts, 0);
      gateway.updates.add(
        ReceiverEvent(viewId, ReceiverPhase.surfaceReady, ''),
      );
      await tester.pump();
      await tester.pump();
      expect(gateway.starts, 1);
      expect(gateway.prepares, 1);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
