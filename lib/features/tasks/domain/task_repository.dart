import 'task.dart';

abstract interface class TaskRepository {
  Future<List<Task>> load();
  Future<void> save(Task task);
  Future<void> delete(String id);
}

