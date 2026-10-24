import 'package:dashtconnect/presentation/pages/display_probe_page.dart';
import 'package:dashtconnect/presentation/theme/app_theme.dart';
import 'package:dashtconnect/presentation/widgets/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color first, Color second) {
  final luminances = [first.computeLuminance(), second.computeLuminance()]
    ..sort();
  return (luminances.last + 0.05) / (luminances.first + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'warning card has a labelled icon and AA text in ${brightness.name}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(brightness),
            home: const Scaffold(
              body: AppNotice.warning('Mobil harus terparkir.'),
            ),
          ),
        );
        final icon = tester.widget<Icon>(
          find.byIcon(Icons.warning_amber_rounded),
        );
        expect(icon.semanticLabel, 'Peringatan');
        final card = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(AppNotice),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = card.decoration! as BoxDecoration;
        final text = tester.widget<Text>(find.text('Mobil harus terparkir.'));
        expect(decoration.border, isNotNull);
        expect(
          contrast(text.style!.color!, decoration.color!),
          greaterThanOrEqualTo(4.5),
        );
      },
    );
    test('blue actions and text keep AA contrast in ${brightness.name}', () {
      final theme = buildAppTheme(brightness);
      final scheme = theme.colorScheme;
      final style = theme.filledButtonTheme.style!;
      final background = style.backgroundColor!.resolve({})!;
      final foreground = style.foregroundColor!.resolve({})!;
      expect(background, const Color(0xFF006BFD));
      expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
      expect(
        contrast(scheme.primary, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(scheme.onSecondaryContainer, scheme.secondaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      for (final surface in [
        scheme.surface,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainerLow,
      ]) {
        expect(contrast(scheme.onSurface, surface), greaterThanOrEqualTo(4.5));
        expect(
          contrast(scheme.onSurfaceVariant, surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrast(scheme.primary, surface), greaterThanOrEqualTo(4.5));
        expect(contrast(scheme.outline, surface), greaterThanOrEqualTo(3));
      }
      expect(
        contrast(scheme.onPrimaryContainer, scheme.primaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(scheme.onErrorContainer, scheme.errorContainer),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('probe targets stay legible in ${brightness.name}', (
      tester,
    ) async {
      final theme = buildAppTheme(brightness);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: DisplayProbe()),
        ),
      );
      final backgrounds = <Color>{};
      for (var target = 1; target <= 4; target++) {
        final button = tester.widget<FilledButton>(
          find.ancestor(
            of: find.text('Target $target\n0 sentuhan'),
            matching: find.byType(FilledButton),
          ),
        );
        final style = button.style!;
        final background = style.backgroundColor!.resolve({})!;
        final foreground = style.foregroundColor!.resolve({})!;
        final border = style.side!.resolve({})!.color;
        backgrounds.add(background);
        expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
        expect(
          contrast(border, theme.colorScheme.surface),
          greaterThanOrEqualTo(3),
        );
      }
      expect(backgrounds, hasLength(4));
    });
  }
}
