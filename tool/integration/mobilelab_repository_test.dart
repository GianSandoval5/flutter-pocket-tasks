import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pocket_tasks/features/tasks/data/mobilelab_task_repository.dart';
import 'package:pocket_tasks/features/tasks/domain/task.dart';

void main() {
  const url = String.fromEnvironment('MOBILELAB_TEST_URL');
  final client = http.Client();
  final repository = MobileLabTaskRepository(
    client: client,
    baseUri: Uri.parse(url),
  );
  tearDownAll(client.close);

  test('real MobileLab Data API supports task creation, updates and deletion', () async {
    final task = Task(
      id: 'dart-integration-task',
      title: 'Comprobar MobileLab',
      createdAt: DateTime.utc(2026),
    );
    await repository.save(task);
    expect((await repository.load()).single.title, task.title);
    await repository.save(task.copyWith(completed: true));
    expect((await repository.load()).single.completed, isTrue);
    await repository.delete(task.id);
    expect(await repository.load(), isEmpty);
  });
}
