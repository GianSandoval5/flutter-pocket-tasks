import 'package:hive/hive.dart';

import '../domain/task.dart';
import '../domain/task_repository.dart';
import 'task_dto.dart';

class HiveTaskRepository implements TaskRepository {
  HiveTaskRepository(this.box);
  final Box<dynamic> box;

  @override
  Future<List<Task>> load() async => box.values
      .map(
        (value) => TaskDto.fromJson(Map<dynamic, dynamic>.from(value as Map)),
      )
      .toList();

  @override
  Future<void> save(Task task) => box.put(task.id, TaskDto.toJson(task));

  @override
  Future<void> delete(String id) => box.delete(id);
}
