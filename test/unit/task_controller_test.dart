import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_tasks/features/tasks/domain/task.dart';
import 'package:pocket_tasks/features/tasks/presentation/task_controller.dart';

import '../support/memory_task_repository.dart';

void main() {
  late MemoryTaskRepository repository;
  late TaskController controller;
  Task task(String id, String title, TaskPriority priority) => Task(
    id: id,
    title: title,
    priority: priority,
    createdAt: DateTime.utc(2026),
  );

  setUp(() {
    repository = MemoryTaskRepository();
    controller = TaskController(repository);
  });
  tearDown(() {
    controller.dispose();
  });

  test('filters case insensitively and orders by priority', () async {
    await controller.save(task('1', 'Leer Flutter', TaskPriority.normal));
    await controller.save(task('2', 'Practicar Flutter', TaskPriority.urgent));
    await controller.save(task('3', 'Caminar', TaskPriority.important));
    expect(controller.filtered(query: 'FLUTTER').map((task) => task.id), [
      '2',
      '1',
    ]);
  });

  test(
    'completion moves tasks between views and updates the summary',
    () async {
      final item = task('1', 'Leer', TaskPriority.normal);
      await controller.save(item);
      await controller.toggle(item);
      expect(controller.filtered(), isEmpty);
      expect(controller.filtered(completed: true), hasLength(1));
      expect(controller.completedCount, 1);
    },
  );

  test('failed writes retain previous state and allow a retry', () async {
    final item = task('1', 'Leer', TaskPriority.normal);
    await controller.save(item);
    repository.fail = true;
    expect(await controller.toggle(item), isFalse);
    expect(controller.tasks.single.completed, isFalse);
    expect(controller.error, isNotNull);
    expect(controller.busy, isFalse);
    repository.fail = false;
    expect(await controller.toggle(item), isTrue);
    expect(controller.error, isNull);
  });

  test(
    'delete removes a stored task and reload reads repository state',
    () async {
      final item = task('1', 'Leer', TaskPriority.normal);
      await repository.save(item);
      await controller.load();
      expect(controller.tasks, hasLength(1));
      await controller.delete(item);
      expect(controller.tasks, isEmpty);
      expect(repository.data, isEmpty);
    },
  );
}

