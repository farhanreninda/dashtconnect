import 'experiment_record.dart';

class Notebook {
  const Notebook({
    this.inventory = const {},
    this.records = const {},
    this.theme = 'system',
    this.tutorialCompleted = false,
    this.lastMode,
  });

  final Map<String, String> inventory;
  final Map<String, ExperimentRecord> records;
  final String theme;
  final bool tutorialCompleted;
  final String? lastMode;

  Notebook copyWith({
    Map<String, String>? inventory,
    Map<String, ExperimentRecord>? records,
    String? theme,
    bool? tutorialCompleted,
    String? lastMode,
  }) => Notebook(
    inventory: inventory ?? this.inventory,
    records: records ?? this.records,
    theme: theme ?? this.theme,
    tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
    lastMode: lastMode ?? this.lastMode,
  );
}
