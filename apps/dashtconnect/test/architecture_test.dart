import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('source imports respect domain, data and presentation boundaries', () {
    final root = Directory('lib').absolute;
    final imports = RegExp("(?:import|export)\\s+['\"]([^'\"]+)['\"]");
    for (final file in root.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final relative = file.path
          .substring(root.path.length + 1)
          .replaceAll('\\', '/');
      for (final match in imports.allMatches(file.readAsStringSync())) {
        final target = match.group(1)!;
        if (relative.startsWith('presentation/')) {
          expect(target, isNot('dart:io'), reason: relative);
        }
        if (relative.startsWith('domain/') || relative.startsWith('core/')) {
          expect(target.startsWith('package:'), isFalse, reason: relative);
          expect(
            ['dart:io', 'dart:ui', 'dart:convert'].contains(target),
            isFalse,
            reason: relative,
          );
        }
        if (target.startsWith('dart:')) continue;
        if (target.startsWith('package:') &&
            !target.startsWith('package:dashtconnect/')) {
          continue;
        }
        final resolved = target.startsWith('package:dashtconnect/')
            ? root.uri
                  .resolve(target.substring('package:dashtconnect/'.length))
                  .path
            : file.parent.uri.resolve(target).normalizePath().path;
        if (relative.startsWith('domain/') || relative.startsWith('core/')) {
          expect(resolved, isNot(contains('/data/')), reason: relative);
          expect(resolved, isNot(contains('/presentation/')), reason: relative);
        }
        if (relative.startsWith('presentation/')) {
          expect(resolved, isNot(contains('/data/')), reason: relative);
        }
        if (relative.startsWith('data/')) {
          expect(resolved, isNot(contains('/presentation/')), reason: relative);
        }
      }
    }
  });
}
