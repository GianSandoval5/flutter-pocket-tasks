import 'package:flutter/foundation.dart';

import '../domain/task.dart';
import '../domain/task_repository.dart';

class TaskController extends ChangeNotifier {
  TaskController(this.repository);
  final TaskRepository repository;
  List<Task> _tasks = [];
  List<Task> get tasks => List.unmodifiable(_tasks);
  bool busy = false;
  String? error;
  int get completedCount => _tasks.where((task) => task.completed).length;

  List<Task> filtered({String query = '', bool completed = false}) {
    final result = _tasks
        .where(
          (task) =>
              task.completed == completed &&
              task.title.toLowerCase().contains(query.toLowerCase().trim()),
        )
        .toList();
    result.sort((a, b) {
      final priority = b.priority.index.compareTo(a.priority.index);
      return priority != 0 ? priority : b.createdAt.compareTo(a.createdAt);
    });
    return result;
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (_) {
      error = 'No pudimos acceder a las tareas. Comprueba que MobileLab esté iniciado y que MOBILELAB_URL sea accesible.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> load() => _run(() async {
    _tasks = await repository.load();
  });

  Future<bool> save(Task task) => _run(() async {
    await repository.save(task);
    _tasks = [..._tasks.where((item) => item.id != task.id), task];
  });

  Future<bool> toggle(Task task) =>
      save(task.copyWith(completed: !task.completed));

  Future<bool> delete(Task task) => _run(() async {
    await repository.delete(task.id);
    _tasks = _tasks.where((item) => item.id != task.id).toList();
  });
}
