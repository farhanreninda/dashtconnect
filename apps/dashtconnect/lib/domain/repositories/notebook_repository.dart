import '../entities/notebook.dart';

abstract interface class NotebookRepository {
  Future<Notebook> load();
  Future<void> save(Notebook notebook);
  String exportReport(Notebook notebook);
}
