import 'package:dashtconnect/domain/entities/notebook.dart';
import 'package:dashtconnect/domain/repositories/device_gateway.dart';
import 'package:dashtconnect/presentation/app.dart';
import 'package:dashtconnect/presentation/widgets/app_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

MemoryNotebookRepository _readyRepository() =>
    MemoryNotebookRepository()..data = const Notebook(tutorialCompleted: true);

ResearchApp _app({
  required MemoryNotebookRepository repository,
  required TestDeviceGateway device,
}) => ResearchApp(
  repository: repository,
  device: device,
  receiver: TestReceiverGateway(),
);

void main() {
  testWidgets(
    'setup tutorial is available from the guide tab without a duplicate home action',
    (tester) async {
      final bridge = TestDeviceGateway();
      await tester.pumpWidget(
        _app(repository: _readyRepository(), device: bridge),
      );
      await tester.pumpAndSettle();
      expect(bridge.infoReads, 0);
      expect(find.text('Mulai receiver'), findsOneWidget);
      expect(find.text('Uji tampilan'), findsNothing);
      expect(find.text('CarPlay terhubung'), findsNothing);
      expect(find.text('Siapkan koneksi'), findsNothing);
      await tester.tap(find.text('Panduan'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Buka tutorial'));
      await tester.tap(find.text('Buka tutorial'));
      await tester.pumpAndSettle();
      expect(find.text('Kenali alur koneksi'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('device read failure does not block setup and can be retried', (
    tester,
  ) async {
    final bridge = TestDeviceGateway()..failInfo = true;
    await tester.pumpWidget(
      _app(repository: _readyRepository(), device: bridge),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mulai receiver'), findsOneWidget);
    expect(bridge.infoReads, 0);
    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Informasi perangkat'));
    await tester.tap(find.text('Informasi perangkat'));
    await tester.pumpAndSettle();
    expect(bridge.infoReads, 1);
    expect(find.textContaining('Pembacaan perangkat gagal.'), findsOneWidget);
    bridge.failInfo = false;
    await tester.ensureVisible(find.text('Perbarui'));
    await tester.tap(find.text('Perbarui'));
    await tester.pumpAndSettle();
    expect(bridge.infoReads, 2);
    await tester.scrollUntilVisible(
      find.text('Perangkat uji'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Perangkat uji'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('settings errors can be retried from Panduan', (tester) async {
    final bridge = TestDeviceGateway()..failSettings = true;
    await tester.pumpWidget(
      _app(repository: _readyRepository(), device: bridge),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Panduan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Buka Wi-Fi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka Wi-Fi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Pengaturan belum bisa dibuka. Coba lagi.'),
      findsOneWidget,
    );
    bridge.failSettings = false;
    await tester.pump(const Duration(seconds: 4));
    await tester.ensureVisible(find.text('Buka Wi-Fi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka Wi-Fi'));
    await tester.pumpAndSettle();
    expect(bridge.lastSettings, DeviceSettings.wifi);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'first-run guide offers real settings and display actions then saves completion',
    (tester) async {
      final store = MemoryNotebookRepository();
      final bridge = TestDeviceGateway();
      await tester.pumpWidget(_app(repository: store, device: bridge));
      await tester.pumpAndSettle();
      expect(find.text('Kenali alur koneksi'), findsOneWidget);
      expect(find.text('Langkah 1 dari 4'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('guide-next')));
      await tester.tap(find.byKey(const Key('guide-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka Wi-Fi'));
      await tester.pumpAndSettle();
      expect(bridge.lastSettings, DeviceSettings.wifi);
      await tester.tap(find.text('Buka Bluetooth'));
      await tester.pumpAndSettle();
      expect(bridge.lastSettings, DeviceSettings.bluetooth);
      await tester.ensureVisible(find.byKey(const Key('guide-next')));
      await tester.tap(find.byKey(const Key('guide-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka uji layar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Target 1\n0 sentuhan'));
      await tester.pumpAndSettle();
      expect(find.text('Target 1\n1 sentuhan'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Langkah 3 dari 4'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('guide-next')));
      await tester.tap(find.byKey(const Key('guide-next')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Selesai'));
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(store.data.tutorialCompleted, isTrue);
      expect(find.text('Beranda'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(repository: store, device: bridge));
      await tester.pumpAndSettle();
      expect(find.text('Kenali alur koneksi'), findsNothing);
      await tester.tap(find.text('Panduan'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Buka tutorial'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka tutorial'));
      await tester.pumpAndSettle();
      expect(find.text('Kenali alur koneksi'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'skipping onboarding retains the guide on save failure and persists a retry',
    (tester) async {
      final store = MemoryNotebookRepository()..failSave = true;
      final bridge = TestDeviceGateway();
      await tester.pumpWidget(_app(repository: store, device: bridge));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Nanti saja'));
      await tester.tap(find.text('Nanti saja'));
      await tester.pumpAndSettle();

      expect(store.data.tutorialCompleted, isFalse);
      expect(find.text('Kenali alur koneksi'), findsOneWidget);
      expect(
        find.text(
          'Panduan belum tersimpan. Coba lagi melalui tombol yang sama.',
        ),
        findsOneWidget,
      );
      store.failSave = false;
      await tester.ensureVisible(find.text('Nanti saja'));
      await tester.tap(find.text('Nanti saja'));
      await tester.pumpAndSettle();
      expect(store.data.tutorialCompleted, isTrue);
      expect(find.text('Beranda'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'settings show only live device info and About while preserving stored data',
    (tester) async {
      final store = _readyRepository()
        ..data = const Notebook(
          tutorialCompleted: true,
          inventory: {'Model Android': 'Fixture previous Android'},
        );
      final original = store.data;
      await tester.pumpWidget(
        _app(repository: store, device: TestDeviceGateway()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pengaturan'));
      await tester.pumpAndSettle();
      expect(find.text('Catatan pengujian'), findsNothing);
      expect(find.text('Tinjau laporan lokal'), findsNothing);
      await tester.ensureVisible(find.text('Informasi perangkat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Informasi perangkat'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Simpan inventaris lokal'), findsNothing);
      expect(find.text('Perangkat uji'), findsOneWidget);
      expect(find.text('Fixture previous Android'), findsNothing);
      expect(identical(store.data, original), isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tentang DashTConnect'));
      await tester.tap(find.text('Tentang DashTConnect'));
      await tester.pumpAndSettle();
      expect(find.text('Tentang aplikasi'), findsOneWidget);
      expect(find.textContaining('Versi '), findsOneWidget);
      expect(find.textContaining('Receiver CarPlay tahap uji'), findsNothing);
      expect(find.textContaining('eksperimen'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Panduan'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Uji tampilan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uji tampilan'));
      await tester.pumpAndSettle();
      for (var index = 1; index <= 4; index++) {
        await tester.ensureVisible(find.text('Target $index\n0 sentuhan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Target $index\n0 sentuhan'));
        await tester.pumpAndSettle();
        expect(find.text('Target $index\n1 sentuhan'), findsOneWidget);
      }
      expect(find.text('4 dari 4 target disentuh'), findsOneWidget);
      await tester.ensureVisible(find.text('Ulangi penghitung'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ulangi penghitung'));
      await tester.pumpAndSettle();
      expect(find.text('0 dari 4 target disentuh'), findsOneWidget);
      for (var index = 1; index <= 4; index++) {
        expect(find.text('Target $index\n0 sentuhan'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('wide layout keeps navigation and touch targets usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(repository: _readyRepository(), device: TestDeviceGateway()),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<AppNavigation>(find.byType(AppNavigation)).rail,
      isTrue,
    );
    await tester.tap(find.text('Panduan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Uji tampilan'));
    await tester.tap(find.text('Uji tampilan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Target 2\n0 sentuhan'));
    await tester.pumpAndSettle();
    expect(find.text('Target 2\n1 sentuhan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('keyboard can reach and activate the brightness control', (
    tester,
  ) async {
    final bridge = TestDeviceGateway();
    await tester.pumpWidget(
      _app(repository: _readyRepository(), device: bridge),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Redupkan layar HP'), findsNothing);
    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mode redup'));
    var focused = false;
    for (var i = 0; i < 20 && !focused; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      FocusManager.instance.primaryFocus?.context?.visitAncestorElements((e) {
        focused = e.widget is SwitchListTile;
        return !focused;
      });
    }
    expect(focused, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(bridge.dimmed, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'theme and dim controls work while touch feedback remains visible',
    (tester) async {
      final store = _readyRepository();
      final bridge = TestDeviceGateway();
      await tester.pumpWidget(_app(repository: store, device: bridge));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pengaturan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tampilan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(find.byType(SwitchListTile), findsOneWidget);
      await tester.ensureVisible(find.text('Mode redup'));
      await tester.tap(find.text('Mode redup'));
      await tester.pumpAndSettle();
      expect(bridge.dimmed, isTrue);
      await tester.tap(find.text('Panduan'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Uji tampilan'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uji tampilan'));
      await tester.pumpAndSettle();
      expect(find.text('Aktifkan mode redup'), findsNothing);
      expect(find.text('Pulihkan kecerahan'), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);
      expect(bridge.dimmed, isTrue);
      await tester.tap(find.text('Target 1\n0 sentuhan'));
      await tester.pumpAndSettle();
      expect(find.text('Target 1\n1 sentuhan'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pengaturan'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Mode redup'));
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      await tester.tap(find.text('Mode redup'));
      await tester.pumpAndSettle();
      expect(bridge.dimmed, isFalse);
      await tester.pumpWidget(const SizedBox());
      expect(store.data.theme, 'dark');
    },
  );

  testWidgets(
    'narrow layout and large text keep navigation and targets usable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        _app(repository: _readyRepository(), device: TestDeviceGateway()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Panduan'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Uji tampilan'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uji tampilan'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Target 4\n0 sentuhan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Target 4\n0 sentuhan'));
      await tester.pumpAndSettle();
      expect(find.text('Target 4\n1 sentuhan'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Panduan'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Buka tutorial'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka tutorial'));
      await tester.pumpAndSettle();
      expect(find.text('Langkah 1 dari 4'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pengaturan'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Tentang DashTConnect'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
