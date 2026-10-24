import 'package:flutter/foundation.dart';

import '../../domain/entities/notebook.dart';
import '../../domain/repositories/notebook_repository.dart';

class NotebookController extends ChangeNotifier {
  NotebookController(this._repository);
  final NotebookRepository _repository;
  Notebook? _notebook;
  Notebook? get notebook => _notebook;
  bool _failed = false;
  bool get failed => _failed;
  bool _saving = false;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    _failed = false;
    _notify();
    try {
      _notebook = await _repository.load();
    } catch (_) {
      _failed = true;
    }
    _notify();
  }

  Future<void> save(Notebook next) async {
    if (_saving) throw StateError('Penyimpanan lain belum selesai.');
    _saving = true;
    try {
      await _repository.save(next);
      _notebook = next;
      _notify();
    } finally {
      _saving = false;
    }
  }

  String exportReport() => _repository.exportReport(notebook!);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
