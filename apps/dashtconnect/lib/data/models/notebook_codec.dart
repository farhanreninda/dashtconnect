import 'dart:convert';

import '../../domain/entities/experiment_record.dart';
import '../../domain/entities/notebook.dart';
import '../../domain/experiments.dart';

class NotebookCodec {
  static String encode(Notebook notebook) => jsonEncode(toMap(notebook));

  static String report(Notebook notebook) =>
      const JsonEncoder.withIndent('  ').convert(toMap(notebook));

  static Notebook decode(String content) {
    final raw = jsonDecode(content);
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Catatan lokal tidak valid.');
    }
    return fromMap(raw);
  }

  static Map<String, dynamic> toMap(Notebook notebook) => {
    'schema': 1,
    'theme': notebook.theme,
    if (notebook.tutorialCompleted) 'tutorialCompleted': true,
    'inventory': notebook.inventory,
    'records': notebook.records.map(
      (key, value) => MapEntry(key, _recordToJson(value)),
    ),
  };

  static Notebook fromMap(Map<String, dynamic> json) {
    if (json['schema'] != 1 ||
        (json.containsKey('tutorialCompleted') &&
            json['tutorialCompleted'] is! bool) ||
        !['system', 'light', 'dark'].contains(json['theme']) ||
        json['records'] is! Map<String, dynamic>) {
      throw const FormatException('Versi catatan lokal tidak didukung.');
    }
    final raw = json['records'] as Map<String, dynamic>;
    final records = raw.map((key, value) {
      if (!experiments.any((experiment) => experiment.id == key) ||
          value is! Map<String, dynamic>) {
        throw const FormatException('Catatan lokal tidak dikenali.');
      }
      return MapEntry(key, _recordFromJson(value));
    });
    return Notebook(
      inventory: _readStrings(json['inventory']),
      theme: json['theme'] as String,
      tutorialCompleted: json['tutorialCompleted'] as bool? ?? false,
      records: records,
    );
  }
}

Map<String, dynamic> _recordToJson(ExperimentRecord record) => {
  'status': record.status,
  'fields': record.fields,
  'updatedAt': record.updatedAt,
  'inventory': record.inventory,
  'version': record.version,
};

ExperimentRecord _recordFromJson(Map<String, dynamic> json) {
  final status = json['status'];
  if (!resultStatuses.contains(status) ||
      json['updatedAt'] is! String ||
      json['version'] is! String) {
    throw const FormatException('Format hasil pengujian tidak didukung.');
  }
  return ExperimentRecord(
    status: status as String,
    fields: _readStrings(json['fields']),
    updatedAt: json['updatedAt'] as String,
    inventory: _readStrings(json['inventory']),
    version: json['version'] as String,
  );
}

Map<String, String> _readStrings(dynamic value) {
  if (value is! Map ||
      value.keys.any((key) => key is! String) ||
      value.values.any((item) => item is! String)) {
    throw const FormatException('Catatan lokal tidak valid.');
  }
  return Map<String, String>.from(value);
}
