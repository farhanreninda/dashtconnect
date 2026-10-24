import 'dart:async';

import 'package:dashtconnect/domain/entities/notebook.dart';
import 'package:dashtconnect/presentation/controllers/notebook_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

class PendingRepository extends MemoryNotebookRepository {
  final loaded = Completer<Notebook>();
  final saved = Completer<void>();

  @override
  Future<Notebook> load() => loaded.future;

  @override
  Future<void> save(Notebook notebook) async {
    await saved.future;
    data = notebook;
  }
}

void main() {
  test('read failure can be retried without resetting stored data', () async {
    final repository = MemoryNotebookRepository()
      ..data = const Notebook(theme: 'dark')
      ..failLoad = true;
    final controller = NotebookController(repository);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.failed, isTrue);
    expect(controller.notebook, isNull);
    expect(repository.data.theme, 'dark');

    repository.failLoad = false;
    await controller.load();
    expect(controller.failed, isFalse);
    expect(controller.notebook!.theme, 'dark');
    expect(controller.exportReport(), contains('"theme": "dark"'));
  });

  test('failed writes retain current state and allow another save', () async {
    final repository = MemoryNotebookRepository();
    final controller = NotebookController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    repository.failSave = true;

    await expectLater(
      controller.save(const Notebook(theme: 'dark')),
      throwsStateError,
    );
    expect(controller.notebook!.theme, 'system');
    expect(repository.data.theme, 'system');

    repository.failSave = false;
    await controller.save(const Notebook(theme: 'light'));
    expect(controller.notebook!.theme, 'light');
    expect(repository.data.theme, 'light');
  });

  test('overlapping writes cannot replace the pending notebook', () async {
    final repository = PendingRepository();
    final controller = NotebookController(repository);
    addTearDown(controller.dispose);
    repository.loaded.complete(const Notebook());
    await controller.load();

    final pending = controller.save(const Notebook(theme: 'dark'));
    await expectLater(
      controller.save(const Notebook(theme: 'light')),
      throwsStateError,
    );
    repository.saved.complete();
    await pending;
    expect(controller.notebook!.theme, 'dark');
  });

  test('a late load does not notify a disposed controller', () async {
    final repository = PendingRepository();
    final controller = NotebookController(repository);
    var notifications = 0;
    controller.addListener(() => notifications++);
    final pending = controller.load();
    controller.dispose();
    repository.loaded.complete(const Notebook());
    await pending;
    expect(notifications, 1);
  });
}
