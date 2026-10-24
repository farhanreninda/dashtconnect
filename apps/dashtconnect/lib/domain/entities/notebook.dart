import 'experiment_record.dart';

class Notebook {
  const Notebook({
    this.inventory = const {},
    this.records = const {},
    this.theme = 'system',
    this.tutorialCompleted = false,
  });

  final Map<String, String> inventory;
  final Map<String, ExperimentRecord> records;
  final String theme;
  final bool tutorialCompleted;

  Notebook copyWith({
    Map<String, String>? inventory,
    Map<String, ExperimentRecord>? records,
    String? theme,
    bool? tutorialCompleted,
  }) => Notebook(
    inventory: inventory ?? this.inventory,
    records: records ?? this.records,
    theme: theme ?? this.theme,
    tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
  );
}
