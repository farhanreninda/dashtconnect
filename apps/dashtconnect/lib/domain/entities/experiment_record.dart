import '../../core/app_version.dart';

const resultStatuses = ['BELUM DIUJI', 'BERHASIL', 'GAGAL', 'BELUM KONKLUSIF'];

Set<String> requiredRecordFields(String status) => switch (status) {
  'BERHASIL' => const {
    'configuration',
    'steps',
    'evidence',
    'next',
    'supports',
  },
  'GAGAL' => const {'configuration', 'steps', 'evidence', 'next', 'refutes'},
  _ => const {},
};

class ExperimentRecord {
  const ExperimentRecord({
    required this.status,
    required this.fields,
    required this.updatedAt,
    required this.inventory,
    this.version = appVersion,
  });

  final String status, updatedAt, version;
  final Map<String, String> fields, inventory;
}
