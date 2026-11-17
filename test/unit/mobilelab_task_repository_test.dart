import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocket_tasks/features/tasks/data/mobilelab_task_repository.dart';
import 'package:pocket_tasks/features/tasks/data/task_dto.dart';
import 'package:pocket_tasks/features/tasks/domain/task.dart';

void main() {
  final task = Task(id: 'one', title: 'Leer', createdAt: DateTime.utc(2026));

  MobileLabTaskRepository repository(
    Future<http.Response> Function(http.Request) handler,
  ) => MobileLabTaskRepository(
    client: MockClient(handler),
    baseUri: Uri.parse('http://127.0.0.1:4566'),
  );

  test('loads documents from the configured MobileLab collection', () async {
    final repo = repository((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/tasks');
      return http.Response(jsonEncode([TaskDto.toJson(task)]), 200);
    });
    final result = await repo.load();
    expect(result.single.title, 'Leer');
  });

  test('PUT creates or replaces a task with its stable identity', () async {
    final repo = repository((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/tasks/one');
      expect(jsonDecode(request.body), TaskDto.toJson(task));
      expect(request.headers['content-type'], 'application/json');
      return http.Response(request.body, 200);
    });
    await repo.save(task);
  });

  test(
    'DELETE accepts an already missing item for an idempotent retry',
    () async {
      final repo = repository((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/tasks/one');
        return http.Response('', 404);
      });
      await repo.delete('one');
    },
  );

  test(
    'reports server failures instead of silently using local data',
    () async {
      final repo = repository((request) async => http.Response('{}', 500));
      await expectLater(repo.load(), throwsA(isA<MobileLabException>()));
      await expectLater(repo.save(task), throwsA(isA<MobileLabException>()));
      await expectLater(
        repo.delete(task.id),
        throwsA(isA<MobileLabException>()),
      );
    },
  );

  test('rejects malformed collection responses', () async {
    final repo = repository((request) async => http.Response('{}', 200));
    await expectLater(repo.load(), throwsA(isA<FormatException>()));
  });

  test('applies request deadlines', () async {
    final repo = MobileLabTaskRepository(
      client: MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response('[]', 200);
      }),
      baseUri: Uri.parse('http://127.0.0.1:4566'),
      timeout: const Duration(milliseconds: 1),
    );
    await expectLater(repo.load(), throwsA(isA<TimeoutException>()));
  });

  test('rejects credentials and resource paths in the sandbox base URL', () {
    for (final url in [
      'file:///tmp/data',
      'http://user:secret@localhost',
      'http://localhost/api/tasks',
    ]) {
      expect(
        () => MobileLabTaskRepository(
          client: MockClient((request) async => http.Response('[]', 200)),
          baseUri: Uri.parse(url),
        ),
        throwsArgumentError,
      );
    }
  });
}
