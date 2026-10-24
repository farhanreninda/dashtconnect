import 'dart:async';

import 'package:dashtconnect/presentation/pages/appearance_page.dart';
import 'package:dashtconnect/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    for (final family in ['Inter', 'SpaceGrotesk']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'theme choices scroll and save in short landscape, $brightness/$scale',
        (tester) async {
          tester.view.physicalSize = const Size(640, 320);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          String? saved;
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(brightness),
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
          expect(find.byType(PopupMenuButton<String>), findsNothing);
          for (final choice in {
            'Gelap': 'dark',
            'Terang': 'light',
            'Sesuai perangkat': 'system',
          }.entries) {
            await tester.ensureVisible(find.text(choice.key));
            await tester.pumpAndSettle();
            await tester.tap(find.text(choice.key));
            await tester.pumpAndSettle();
            expect(saved, choice.value);
            expect(
              tester
                  .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
                  .groupValue,
              choice.value,
            );
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets(
    'failed save preserves selection and allows retry without overlapping writes',
    (tester) async {
      var calls = 0;
      final pending = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: AppearancePage(
            initialTheme: 'light',
            onChanged: (_) {
              calls++;
              return calls == 1 ? pending.future : Future.value();
            },
          ),
        ),
      );
      await tester.tap(find.text('Gelap'));
      await tester.pump();
      expect(calls, 1);
      expect(
        tester
            .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
            .groupValue,
        'light',
      );
      await tester.tap(find.text('Sesuai perangkat'));
      await tester.pump();
      expect(calls, 1);
      pending.completeError(StateError('Fixture failed save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tema belum tersimpan.'), findsOneWidget);
      expect(
        tester
            .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
            .groupValue,
        'light',
      );
      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.textContaining('Tema belum tersimpan.'), findsNothing);
      expect(
        tester
            .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
            .groupValue,
        'dark',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
