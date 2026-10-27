import 'package:dashtconnect/presentation/pages/setup_guide_page.dart';
import 'package:dashtconnect/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _showGuide(
  WidgetTester tester, {
  Future<void> Function()? onComplete,
  VoidCallback? onTestDisplay,
  Future<void> Function(String)? onOpenSettings,
  bool firstRun = false,
  double textScale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    theme: buildAppTheme(Brightness.light),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: SetupGuidePage(
      firstRun: firstRun,
      onComplete: onComplete ?? () async {},
      onTestDisplay: onTestDisplay ?? () {},
      onOpenSettings: onOpenSettings ?? (_) async {},
    ),
  ),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('guide navigates and invokes settings and display actions', (
    tester,
  ) async {
    final settings = <String>[];
    var displayOpens = 0;
    var completions = 0;
    await _showGuide(
      tester,
      onComplete: () async => completions++,
      onOpenSettings: (section) async => settings.add(section),
      onTestDisplay: () => displayOpens++,
    );
    expect(completions, 0);
    expect(find.text('Langkah 1 dari 4'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('guide-next')));
    await _tap(tester, find.text('Buka Wi-Fi'));
    await _tap(tester, find.text('Buka Bluetooth'));
    expect(settings, ['wifi', 'bluetooth']);
    await _tap(tester, find.text('Sebelumnya'));
    expect(find.text('Kenali alur koneksi'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('guide-next')));
    await _tap(tester, find.byKey(const Key('guide-next')));
    await _tap(tester, find.text('Buka uji layar'));
    expect(displayOpens, 1);
    expect(completions, 0);
    await _tap(tester, find.byKey(const Key('guide-next')));
    expect(find.text('Hubungkan tanpa memutus Wi-Fi'), findsOneWidget);
    expect(
      find.textContaining('Internet tetap digunakan di iPhone'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Wi-Fi berinternet dan data seluler Android boleh tetap aktif.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Setujui permintaan CarPlay di iPhone.'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Selesai'));
    expect(completions, 1);
  });

  testWidgets('failed completion remains retryable and skip uses completion', (
    tester,
  ) async {
    var attempts = 0;
    await _showGuide(
      tester,
      firstRun: true,
      onComplete: () async {
        attempts++;
        if (attempts == 1) throw StateError('storage unavailable');
      },
    );
    expect(attempts, 0);
    expect(
      find.text('Panduan dapat dibuka lagi dari menu Panduan.'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Nanti saja'));
    expect(attempts, 1);
    expect(
      find.text('Panduan belum tersimpan. Coba lagi melalui tombol yang sama.'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Nanti saja'));
    expect(attempts, 2);
    expect(find.textContaining('Panduan belum tersimpan.'), findsNothing);
  });

  testWidgets('settings failure shows a retryable error', (tester) async {
    var attempts = 0;
    await _showGuide(
      tester,
      onOpenSettings: (_) async {
        attempts++;
        if (attempts == 1) throw StateError('settings unavailable');
      },
    );
    await _tap(tester, find.byKey(const Key('guide-next')));
    await _tap(tester, find.text('Buka Wi-Fi'));
    expect(
      find.text('Pengaturan Wi-Fi tidak bisa dibuka. Coba lagi.'),
      findsOneWidget,
    );
    await _tap(tester, find.text('Buka Wi-Fi'));
    expect(attempts, 2);
    expect(find.textContaining('tidak bisa dibuka'), findsNothing);
  });

  testWidgets('all steps reflow at 320 pixels and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var completions = 0;
    await _showGuide(
      tester,
      firstRun: true,
      textScale: 2,
      onComplete: () async => completions++,
    );
    for (var step = 1; step <= 4; step++) {
      expect(find.text('Langkah $step dari 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _tap(tester, find.byKey(const Key('guide-next')));
    }
    expect(completions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('next action is reachable using the keyboard', (tester) async {
    await _showGuide(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Langkah 2 dari 4'), findsOneWidget);
  });
}
