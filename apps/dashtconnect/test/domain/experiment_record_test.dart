import 'package:dashtconnect/domain/entities/experiment_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'conclusive results require common evidence and the matching outcome',
    () {
      for (final status in ['BERHASIL', 'GAGAL']) {
        expect(
          requiredRecordFields(status),
          containsAll(['configuration', 'steps', 'evidence', 'next']),
        );
      }
      expect(requiredRecordFields('BERHASIL'), contains('supports'));
      expect(requiredRecordFields('BERHASIL'), isNot(contains('refutes')));
      expect(requiredRecordFields('GAGAL'), contains('refutes'));
      expect(requiredRecordFields('GAGAL'), isNot(contains('supports')));
      expect(requiredRecordFields('BELUM DIUJI'), isEmpty);
      expect(requiredRecordFields('BELUM KONKLUSIF'), isEmpty);
    },
  );
}
