import 'package:pocket_tasks/features/tasks/domain/task.dart';
import 'package:pocket_tasks/features/tasks/domain/task_repository.dart';

class MemoryTaskRepository implements TaskRepository {
  final Map<String, Task> data = {};
  bool fail = false;

  void check() {
    if (fail) throw StateError('Storage unavailable');
  }

  @override
  Future<List<Task>> load() async {
    check();
    return data.values.toList();
  }

  @override
  Future<void> save(Task task) async {
    check();
    data[task.id] = task;
  }

  @override
  Future<void> delete(String id) async {
    check();
    data.remove(id);
  }
}

