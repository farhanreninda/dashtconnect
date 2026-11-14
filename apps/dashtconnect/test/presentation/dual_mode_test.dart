import 'dart:async';

import 'package:dashtconnect/domain/entities/android_auto_state.dart';
import 'package:dashtconnect/domain/entities/notebook.dart';
import 'package:dashtconnect/presentation/app.dart';
import 'package:dashtconnect/presentation/pages/android_auto_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

const waiting = AndroidAutoState(
  sdk: 34,
  installed: true,
  enabled: true,
  version: '17.4',
  usbAccessory: true,
  usbHostDevice: false,
);
const unavailable = AndroidAutoState(
  sdk: 34,
  installed: false,
  enabled: false,
  version: '',
  usbAccessory: false,
  usbHostDevice: false,
);

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'home shortcuts open guides and touch test without selecting a transport',
    (tester) async {
      final aa = TestAndroidAutoGateway();
      final receiver = TestReceiverGateway();
      final store = MemoryNotebookRepository()
        ..data = const Notebook(tutorialCompleted: true);
      await tester.pumpWidget(
        ResearchApp(
          repository: store,
          device: TestDeviceGateway(),
          receiver: receiver,
          androidAuto: aa,
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.text('Panduan koneksi'));
      expect(find.text('Panduan Apple CarPlay'), findsOneWidget);
      await tap(tester, find.text('Beranda'));
      await tap(tester, find.text('Uji tampilan T-Link'));
      expect(find.text('Tes sentuhan'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Koneksi ke head unit'), findsOneWidget);
      expect(store.data.lastMode, isNull);
      expect(receiver.prepares + receiver.starts, 0);
      expect(aa.reads, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'startup opens home; choices are in content and can be cancelled',
    (tester) async {
      final aa = TestAndroidAutoGateway();
      final store = MemoryNotebookRepository()
        ..data = const Notebook(
          tutorialCompleted: true,
          lastMode: 'androidAuto',
        );
      await tester.pumpWidget(
        ResearchApp(
          repository: store,
          device: TestDeviceGateway(),
          receiver: TestReceiverGateway(),
          androidAuto: aa,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Koneksi ke head unit'), findsOneWidget);
      expect(find.byKey(const Key('mode-androidAuto')), findsNothing);
      expect(find.byTooltip('Ganti mode'), findsNothing);
      expect(aa.reads, 0);
      await tap(tester, find.text('Panduan'));
      expect(find.text('Panduan Apple CarPlay'), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Android Auto'));
      expect(find.text('Panduan Android Auto'), findsOneWidget);
      expect(find.byKey(const Key('mode-androidAuto')), findsNothing);
      expect(store.data.lastMode, 'androidAuto');
      await tap(tester, find.text('Pengaturan'));
      expect(find.text('Mode koneksi'), findsNothing);
      expect(aa.reads, 0);
      await openModeChoices(tester);
      await tap(tester, find.byType(BackButton));
      expect(find.text('Koneksi ke head unit'), findsOneWidget);
      await openModeChoices(tester);
      await tap(tester, find.byKey(const Key('mode-androidAuto')));
      expect(find.text('Identitas head unit belum dipasang'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Koneksi ke head unit'), findsOneWidget);
      expect(aa.updates.hasListener, isFalse);
      expect(store.data.lastMode, 'androidAuto');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'first CarPlay tutorial can return to selector before completing setup',
    (tester) async {
      await tester.pumpWidget(
        ResearchApp(
          repository: MemoryNotebookRepository(),
          device: TestDeviceGateway(),
          receiver: TestReceiverGateway(),
          androidAuto: TestAndroidAutoGateway(),
        ),
      );
      await tester.pumpAndSettle();
      await openModeChoices(tester);
      await tap(tester, find.byKey(const Key('mode-carplay')));
      expect(find.text('Kenali alur koneksi'), findsOneWidget);
      await openModeChoices(tester);
      expect(find.text('Pilih cara terhubung.'), findsOneWidget);
      await tap(tester, find.byKey(const Key('mode-androidAuto')));
      expect(find.text('Identitas head unit belum dipasang'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'late failed refresh and settings failure do not erase newer readiness',
    (tester) async {
      final aa = TestAndroidAutoGateway()
        ..pending = Completer<AndroidAutoState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AndroidAutoPage(gateway: aa, onGuide: () {}),
          ),
        ),
      );
      await tester.pump();
      aa.updates.add(waiting);
      await tester.pump();
      aa.pending!.completeError(StateError('old refresh failed'));
      await tester.pumpAndSettle();
      expect(find.text('Identitas head unit belum dipasang'), findsOneWidget);
      aa.failSettings = true;
      await tap(tester, find.text('Pengaturan Android Auto'));
      expect(find.text('Identitas head unit belum dipasang'), findsOneWidget);
      expect(
        find.text('Pengaturan Android Auto belum dapat dibuka. Coba lagi.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'selector persists choice, separates guides and never starts the other transport',
    (tester) async {
      final store = MemoryNotebookRepository()
        ..data = const Notebook(tutorialCompleted: true, lastMode: 'carplay');
      final aa = TestAndroidAutoGateway();
      final receiver = TestReceiverGateway();
      await tester.pumpWidget(
        ResearchApp(
          repository: store,
          device: TestDeviceGateway(),
          receiver: receiver,
          androidAuto: aa,
        ),
      );
      await tester.pumpAndSettle();
      await openModeChoices(tester);
      expect(find.text('Pilih cara terhubung.'), findsOneWidget);
      expect(find.text('Terakhir dipakai'), findsOneWidget);
      expect(aa.reads, 0);
      await tap(tester, find.byKey(const Key('mode-androidAuto')));
      expect(store.data.lastMode, 'androidAuto');
      expect(find.text('Identitas head unit belum dipasang'), findsOneWidget);
      expect(find.text('Mulai receiver'), findsNothing);
      expect(receiver.prepares + receiver.starts, 0);
      await tap(tester, find.text('Panduan'));
      expect(find.text('Panduan Android Auto'), findsOneWidget);
      expect(find.text('Buka tutorial'), findsNothing);
      expect(aa.updates.hasListener, isFalse);
      await openModeChoices(tester);
      expect(find.text('Pilih cara terhubung.'), findsOneWidget);
      await tap(tester, find.byKey(const Key('mode-carplay')));
      expect(find.text('Mulai receiver'), findsOneWidget);
      expect(find.text('Identitas head unit belum dipasang'), findsNothing);
      expect(aa.updates.hasListener, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'preference failure stays actionable and unknown saved mode shows selector',
    (tester) async {
      final store = MemoryNotebookRepository()
        ..data = const Notebook(lastMode: 'future-mode')
        ..failSave = true;
      await tester.pumpWidget(
        ResearchApp(
          repository: store,
          device: TestDeviceGateway(),
          receiver: TestReceiverGateway(),
          androidAuto: TestAndroidAutoGateway(),
        ),
      );
      await tester.pumpAndSettle();
      await openModeChoices(tester);
      await tap(tester, find.byKey(const Key('mode-androidAuto')));
      expect(
        find.text('Pilihan belum tersimpan. Coba pilih mode kembali.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mode-androidAuto')), findsOneWidget);
      store.failSave = false;
      await tap(tester, find.byKey(const Key('mode-androidAuto')));
      expect(find.text('Identitas head unit belum dipasang'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'USB and enabled source never claim a local projection; readiness error recovers',
    (tester) async {
      final aa = TestAndroidAutoGateway()..state = waiting;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AndroidAutoPage(gateway: aa, onGuide: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Identitas head unit belum dipasang'), findsOneWidget);
      expect(find.text('Android Auto terhubung'), findsNothing);
      expect(find.text('Mulai receiver'), findsNothing);
      aa.updates.add(unavailable);
      await tester.pumpAndSettle();
      expect(find.text('Layanan Android Auto belum tersedia'), findsOneWidget);
      aa.updates.addError(StateError('gone'));
      await tester.pumpAndSettle();
      expect(find.text('Persiapan belum terbaca'), findsOneWidget);
      await tap(tester, find.text('Periksa ulang'));
      expect(find.text('Identitas head unit belum dipasang'), findsOneWidget);
      aa.failSettings = true;
      await tap(tester, find.text('Pengaturan Android Auto'));
      expect(
        find.text('Pengaturan Android Auto belum dapat dibuka. Coba lagi.'),
        findsOneWidget,
      );
      expect(find.text('Identitas head unit belum dipasang'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(aa.updates.hasListener, isFalse);
    },
  );

  testWidgets(
    'session can start only when ready and reports progress and failure',
    (tester) async {
      const ready = AndroidAutoState(
        sdk: 34,
        installed: true,
        enabled: true,
        version: '17.9',
        usbAccessory: false,
        usbHostDevice: false,
        identity: true,
      );
      final aa = TestAndroidAutoGateway()..state = ready;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AndroidAutoPage(gateway: aa, onGuide: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Siap menjalankan Android Auto'), findsOneWidget);
      await tap(tester, find.text('Buka layar Android Auto'));
      expect(aa.starts, 1);
      aa.updates.add(
        const AndroidAutoState(
          sdk: 34,
          installed: true,
          enabled: true,
          version: '17.9',
          usbAccessory: false,
          usbHostDevice: false,
          identity: true,
          session: AndroidAutoSession.waitingVideo,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Terhubung, menunggu gambar'), findsOneWidget);
      expect(find.text('Buka layar Android Auto'), findsNothing);
      await tap(tester, find.text('Hentikan sesi'));
      expect(aa.stops, 1);
      aa.updates.add(
        const AndroidAutoState(
          sdk: 34,
          installed: true,
          enabled: true,
          version: '17.9',
          usbAccessory: false,
          usbHostDevice: false,
          identity: true,
          session: AndroidAutoSession.failed,
          sessionDetail: 'Head unit server Android Auto belum berjalan.',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sesi Android Auto gagal'), findsOneWidget);
      expect(
        find.text('Head unit server Android Auto belum berjalan.'),
        findsOneWidget,
      );
      expect(find.text('Buka layar Android Auto'), findsOneWidget);
    },
  );

  testWidgets(
    'late refresh cannot replace newer readiness event or update disposed screen',
    (tester) async {
      final aa = TestAndroidAutoGateway()
        ..pending = Completer<AndroidAutoState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AndroidAutoPage(gateway: aa, onGuide: () {}),
          ),
        ),
      );
      await tester.pump();
      aa.updates.add(unavailable);
      await tester.pump();
      aa.pending!.complete(waiting);
      await tester.pumpAndSettle();
      expect(find.text('Layanan Android Auto belum tersedia'), findsOneWidget);
      aa.pending = Completer<AndroidAutoState>();
      await tester.ensureVisible(find.text('Periksa ulang'));
      await tester.tap(find.text('Periksa ulang'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      aa.pending!.complete(waiting);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(320, 640), const Size(800, 360)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('both modes reflow at $size with text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = MemoryNotebookRepository()
          ..data = const Notebook(tutorialCompleted: true);
        await tester.pumpWidget(
          ResearchApp(
            repository: store,
            device: TestDeviceGateway(),
            receiver: TestReceiverGateway(),
            androidAuto: TestAndroidAutoGateway(),
          ),
        );
        await tester.pumpAndSettle();
        await tap(tester, find.text('Panduan'));
        expect(find.text('Panduan Apple CarPlay'), findsOneWidget);
        await tap(tester, find.widgetWithText(ChoiceChip, 'Android Auto'));
        expect(find.text('Panduan Android Auto'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await openModeChoices(tester);
        for (final mode in ['androidAuto', 'carplay']) {
          await tap(
            tester,
            find.descendant(
              of: find.byKey(Key('mode-$mode')),
              matching: find.text(
                mode == 'carplay' ? 'Apple CarPlay' : 'Android Auto',
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          for (final tab in ['Panduan', 'Pengaturan', 'Beranda']) {
            await tap(tester, find.text(tab));
            expect(tester.takeException(), isNull);
          }
          await openModeChoices(tester);
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
