import 'package:dashtconnect/domain/entities/receiver_state.dart';
import 'package:dashtconnect/presentation/pages/head_unit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  Future<int Function()> open(
    WidgetTester tester,
    TestReceiverGateway gateway,
  ) async {
    var continued = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HeadUnitPage(receiver: gateway, onContinue: () => continued++),
      ),
    );
    await tester.pump();
    return () => continued;
  }

  FilledButton button(WidgetTester tester, String label) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

  testWidgets('connect stays disabled until the head unit is plugged in', (
    tester,
  ) async {
    final gateway = TestReceiverGateway();
    final continued = await open(tester, gateway);
    expect(find.text('Head unit belum terdeteksi'), findsOneWidget);
    expect(button(tester, 'Tampilkan di head unit').onPressed, isNull);

    await tester.tap(find.text('Lewati, pakai layar HP saja'));
    expect(continued(), 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('detected head unit connects, then offers the iPhone step', (
    tester,
  ) async {
    final gateway = TestReceiverGateway()
      ..headUnit = const HeadUnitStatus(HeadUnitLink.detected)
      ..onConnectHeadUnit = () => const HeadUnitStatus(HeadUnitLink.streaming);
    final continued = await open(tester, gateway);

    await tester.tap(find.text('Tampilkan di head unit'));
    await tester.pump();
    expect(gateway.headUnitConnects, 1);
    expect(find.text('Tampil di head unit'), findsOneWidget);
    expect(find.text('Lewati, pakai layar HP saja'), findsNothing);

    await tester.tap(find.text('Lanjut hubungkan iPhone'));
    expect(continued(), 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a failed session shows its reason and the log action', (
    tester,
  ) async {
    final gateway = TestReceiverGateway()
      ..headUnit = const HeadUnitStatus(
        HeadUnitLink.detected,
        problem: 'Head unit belum menerima tampilan DashTConnect.',
      );
    await open(tester, gateway);
    expect(
      find.text('Head unit belum menerima tampilan DashTConnect.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Bagikan log diagnostik'));
    await tester.tap(find.text('Bagikan log diagnostik'));
    await tester.pump();
    expect(gateway.shares, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
