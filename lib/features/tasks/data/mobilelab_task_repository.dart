import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/task.dart';
import '../domain/task_repository.dart';
import 'task_dto.dart';

class MobileLabException implements Exception {
  const MobileLabException(this.statusCode);
  final int statusCode;

  @override
  String toString() => 'MobileLab respondió HTTP $statusCode.';
}

class MobileLabTaskRepository implements TaskRepository {
  MobileLabTaskRepository({
    required this.client,
    required this.baseUri,
    this.timeout = const Duration(seconds: 8),
  }) {
    if (!{'http', 'https'}.contains(baseUri.scheme) ||
        baseUri.host.isEmpty ||
        baseUri.userInfo.isNotEmpty ||
        baseUri.hasQuery ||
        baseUri.hasFragment ||
        !{'', '/'}.contains(baseUri.path)) {
      throw ArgumentError('MOBILELAB_URL debe ser el origen HTTP del sandbox.');
    }
  }

  final http.Client client;
  final Uri baseUri;
  final Duration timeout;
  static const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Uri _uri([String? id]) => baseUri.resolve(
    id == null ? '/api/tasks' : '/api/tasks/${Uri.encodeComponent(id)}',
  );

  @override
  Future<List<Task>> load() async {
    final response = await client.get(_uri(), headers: headers).timeout(timeout);
    if (response.statusCode != 200) {
      throw MobileLabException(response.statusCode);
    }
    final documents = jsonDecode(response.body);
    if (documents is! List) {
      throw const FormatException('MobileLab debe devolver una lista de tareas.');
    }
    return documents.map((document) {
      if (document is! Map) {
        throw const FormatException('La tarea debe ser un objeto JSON.');
      }
      return TaskDto.fromJson(Map<dynamic, dynamic>.from(document));
    }).toList();
  }

  @override
  Future<void> save(Task task) async {
    final response = await client
        .put(_uri(task.id), headers: headers, body: jsonEncode(TaskDto.toJson(task)))
        .timeout(timeout);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw MobileLabException(response.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    final response = await client
        .delete(_uri(id), headers: headers)
        .timeout(timeout);
    if (response.statusCode != 204 && response.statusCode != 404) {
      throw MobileLabException(response.statusCode);
    }
  }
}
