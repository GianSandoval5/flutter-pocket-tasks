import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pocket_tasks/features/tasks/data/hive_task_repository.dart';
import 'package:pocket_tasks/features/tasks/domain/task.dart';

void main() {
  late Directory directory;
  late HiveTaskRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('pocket_tasks_test_');
    Hive.init(directory.path);
    repository = HiveTaskRepository(await Hive.openBox<dynamic>('tasks'));
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Task task() =>
      Task(id: 'task-1', title: 'Primera tarea', createdAt: DateTime.utc(2026));

  test('starts with an empty collection', () async {
    expect(await repository.load(), isEmpty);
  });

  test('persists tasks after closing and reopening the Hive box', () async {
    await repository.save(task());
    await Hive.close();
    Hive.init(directory.path);
    repository = HiveTaskRepository(await Hive.openBox<dynamic>('tasks'));
    final restored = await repository.load();
    expect(restored.single.title, 'Primera tarea');
  });

  test('updates an existing task without duplicates and deletes it', () async {
    await repository.save(task());
    await repository.save(
      task().copyWith(title: 'Actualizada', completed: true),
    );
    final tasks = await repository.load();
    expect(tasks, hasLength(1));
    expect(tasks.single.completed, isTrue);
    await repository.delete('task-1');
    expect(await repository.load(), isEmpty);
  });
}
