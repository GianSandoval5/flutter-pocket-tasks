import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_tasks/features/tasks/data/task_dto.dart';
import 'package:pocket_tasks/features/tasks/domain/task.dart';

void main() {
  Task task(String title) =>
      Task(id: '1', title: title, createdAt: DateTime.utc(2026));

  test('trims titles and rejects empty or oversized tasks', () {
    expect(task('  Comprar pan  ').title, 'Comprar pan');
    expect(() => task('  '), throwsArgumentError);
    expect(() => task(List.filled(121, 'a').join()), throwsArgumentError);
  });

  test('editing preserves identity, completion and creation time', () {
    final original = task('Leer').copyWith(completed: true);
    final edited = original.copyWith(
      title: 'Leer 20 minutos',
      priority: TaskPriority.urgent,
    );
    expect(edited.id, original.id);
    expect(edited.createdAt, original.createdAt);
    expect(edited.completed, isTrue);
    expect(edited.priority, TaskPriority.urgent);
    expect(original.title, 'Leer');
  });

  test('DTO round trip preserves persisted fields', () {
    final original = task('Caminar')
        .copyWith(priority: TaskPriority.important, completed: true);
    final decoded = TaskDto.fromJson(TaskDto.toJson(original));
    expect(TaskDto.toJson(decoded), TaskDto.toJson(original));
  });
}

