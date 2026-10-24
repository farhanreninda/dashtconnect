import 'dart:convert';
import 'dart:io';

import 'package:dashtconnect/data/repositories/file_notebook_repository.dart';
import 'package:dashtconnect/domain/entities/experiment_record.dart';
import 'package:dashtconnect/domain/entities/notebook.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late FileNotebookRepository store;
  late File file;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dashtconnect-test-');
    file = File('${directory.path}/research.json');
    store = FileNotebookRepository(directoryPath: () async => directory.path);
  });
  tearDown(() async => directory.delete(recursive: true));

  test(
    'existing v0.2.0 schema remains readable and exports without data loss',
    () async {
      const original = '''
{"schema":1,"theme":"dark","inventory":{"huFirmware":"1.1.0005.4400"},"records":{"EXP-03":{"status":"BELUM KONKLUSIF","fields":{"evidence":"Fixture: belum diuji pada HU"},"updatedAt":"2026-10-22T10:00:00","inventory":{"Model Android":"Perangkat uji"},"version":"0.2.0+1"}}}
''';
      await file.writeAsString(original);
      final notebook = await store.load();
      expect(notebook.tutorialCompleted, isFalse);
      expect(notebook.records['EXP-03']!.version, '0.2.0+1');
      expect(jsonDecode(store.exportReport(notebook)), jsonDecode(original));
      await store.save(notebook);
      expect(jsonDecode(await file.readAsString()), jsonDecode(original));
    },
  );

  test(
    'tutorial completion survives restart without losing existing data',
    () async {
      await store.save(
        const Notebook(
          theme: 'dark',
          inventory: {'huFirmware': '1.1.0005.4400'},
        ),
      );
      final before = await store.load();
      await store.save(before.copyWith(tutorialCompleted: true));
      final reopened = await FileNotebookRepository(
        directoryPath: () async => directory.path,
      ).load();
      expect(reopened.tutorialCompleted, isTrue);
      expect(reopened.theme, 'dark');
      expect(reopened.inventory, before.inventory);
      expect(reopened.copyWith(theme: 'light').tutorialCompleted, isTrue);
    },
  );

  test(
    'experiment evidence and its device snapshot survive a restart',
    () async {
      expect((await store.load()).records, isEmpty);
      final record = ExperimentRecord(
        status: 'BELUM KONKLUSIF',
        fields: {'evidence': 'Target disentuh pada HP; head unit belum diuji.'},
        updatedAt: '2026-10-22T10:00:00',
        inventory: {'Model Android': 'Perangkat uji'},
      );
      await store.save(
        Notebook(
          theme: 'dark',
          inventory: {'huModel': 'Belum diketahui'},
          records: {'EXP-03': record},
        ),
      );
      await store.save(
        (await store.load()).copyWith(
          inventory: {'huModel': 'Dicatat kemudian'},
        ),
      );
      final reopened = await FileNotebookRepository(
        directoryPath: () async => directory.path,
      ).load();
      expect(reopened.theme, 'dark');
      expect(
        reopened.records['EXP-03']!.fields['evidence'],
        contains('belum diuji'),
      );
      expect(
        reopened.records['EXP-03']!.inventory['Model Android'],
        'Perangkat uji',
      );
      expect(reopened.inventory['huModel'], 'Dicatat kemudian');
    },
  );

  test(
    'corrupt or unsupported data is rejected without replacing its bytes',
    () async {
      for (final content in [
        'broken json',
        '{"schema":999}',
        '{"schema":1,"theme":"dark","inventory":{},"records":{},"tutorialCompleted":"true"}',
        '{"schema":1,"theme":"dark","inventory":{},"records":{"EXP-03":{"status":"CONNECTED"}}}',
      ]) {
        await file.writeAsString(content);
        await expectLater(store.load(), throwsA(isA<FormatException>()));
        expect(await file.readAsString(), content);
      }
    },
  );
}
