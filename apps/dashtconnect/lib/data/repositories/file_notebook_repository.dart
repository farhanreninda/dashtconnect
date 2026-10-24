import 'dart:convert';
import 'dart:io';

import '../../domain/entities/notebook.dart';
import '../../domain/repositories/notebook_repository.dart';
import '../models/notebook_codec.dart';

class FileNotebookRepository implements NotebookRepository {
  FileNotebookRepository({required this.directoryPath});
  final Future<String> Function() directoryPath;

  Future<File> _file() async => File('${await directoryPath()}/research.json');

  @override
  Future<Notebook> load() async {
    final file = await _file();
    if (!await file.exists()) return const Notebook();
    if (await file.length() > 1024 * 1024) {
      throw const FormatException('Catatan melebihi batas 1 MB.');
    }
    return NotebookCodec.decode(await file.readAsString());
  }

  @override
  Future<void> save(Notebook notebook) async {
    final content = NotebookCodec.encode(notebook);
    if (utf8.encode(content).length > 1024 * 1024) {
      throw const FormatException('Catatan melebihi batas 1 MB.');
    }
    final file = await _file();
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(content, flush: true);
    await temporary.rename(file.path);
  }

  @override
  String exportReport(Notebook notebook) => NotebookCodec.report(notebook);
}
